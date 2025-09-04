import os
import sys
import boto3
import subprocess
from collections import defaultdict


def run_command(command, working_dir):
    """Runs a command and streams its output."""
    print(f"Executing: '{' '.join(command)}' in '{working_dir}'", flush=True)
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        cwd=working_dir,
        bufsize=1
    )
    for line in iter(process.stdout.readline, ''):
        print(line, end='', flush=True)
    process.wait()
    if process.returncode != 0:
        raise subprocess.CalledProcessError(process.returncode, command)


def s3_object_exists(s3_client, bucket, key):
    """Checks if an object exists in an S3 bucket."""
    try:
        s3_client.head_object(Bucket=bucket, Key=key)
        return True
    except s3_client.exceptions.ClientError as e:
        if e.response['Error']['Code'] == '404':
            return False
        else:
            # Something else has gone wrong.
            raise


def get_service_dependencies(services_dir):
    """
    Builds a dependency graph from 'dependencies.txt' files.
    Returns a dictionary where keys are services and values are sets of their dependencies.
    """
    dependency_graph = defaultdict(set)
    service_list = [s for s in os.listdir(services_dir) if os.path.isdir(os.path.join(services_dir, s))]

    for service in service_list:
        # Ensure every service is in the graph, even if it has no dependencies
        dependency_graph[service]
        
        dep_file = os.path.join(services_dir, service, 'dependencies.txt')
        if os.path.exists(dep_file):
            with open(dep_file, 'r') as f:
                for line in f:
                    dependency = line.strip()
                    if dependency:
                        dependency_graph[service].add(dependency)
    return dependency_graph


def topological_sort(dependency_graph):
    """
    Performs a topological sort on the dependency graph.
    Returns a list of services in the correct deployment order.
    """
    sorted_order = []
    # Nodes with no incoming edges
    in_degree = {u: 0 for u in dependency_graph}
    for u in dependency_graph:
        for v in dependency_graph[u]:
            in_degree[v] += 1

    queue = [u for u in dependency_graph if in_degree[u] == 0]

    while queue:
        u = queue.pop(0)
        sorted_order.append(u)

        # Since u is "deployed", we can remove its outgoing edges
        # by decrementing the in-degree of its neighbors.
        for v in dependency_graph:
            if u in dependency_graph[v]:
                in_degree[v] -= 1
                if in_degree[v] == 0:
                    queue.append(v)

    if len(sorted_order) == len(dependency_graph):
        return sorted_order
    else:
        raise Exception("Cycle detected in dependencies! Cannot determine deployment order.")


if __name__ == "__main__":
    services_dir = "services"
    s3_bucket = os.environ.get("S3_BUCKET")
    s3_key_prefix = os.environ.get("S3_KEY_PREFIX", "packages")
    s3_key_version = os.environ.get("S3_KEY_VERSION")

    if not all([s3_bucket, s3_key_version]):
        print("Error: S3_BUCKET and S3_KEY_VERSION environment variables must be set.")
        sys.exit(1)

    print("--- Building Service Dependency Graph ---")
    graph = get_service_dependencies(services_dir)
    print(f"Found dependencies: {dict(graph)}")

    print("\n--- Calculating Deployment Order (Topological Sort) ---")
    deploy_order = topological_sort(graph)
    print(f"Deployment order: {deploy_order}")

    print("\n--- Starting Sequential Deployment ---")
    for service in deploy_order:
        print(f"\n----- Deploying Service: {service} -----")
        package_filename = f"{service}-package.zip"
        
        s3_client = boto3.client('s3')

        # Determine the S3 key for the package, with fallback logic
        versioned_s3_key = f"{s3_key_prefix}/{service}-{s3_key_version}.zip"
        rc_s3_key = f"{s3_key_prefix}/{service}-rc.zip"

        s3_key_to_download = versioned_s3_key
        if not s3_object_exists(s3_client, s3_bucket, versioned_s3_key):
            print(f"Package '{versioned_s3_key}' not found. Falling back to 'rc' version.")
            s3_key_to_download = rc_s3_key
            if not s3_object_exists(s3_client, s3_bucket, rc_s3_key):
                print(f"Error: Neither PR nor RC package found for service '{service}'. Cannot deploy.")
                sys.exit(1)
        
        # 1. Download the package
        run_command(["aws", "s3", "cp", f"s3://{s3_bucket}/{s3_key_to_download}", package_filename], working_dir=".")
        # 2. Unzip the package
        run_command(["unzip", "-o", package_filename], working_dir=".")
        # 3. Deploy using Terraform
        run_command(["terraform", "apply", "-auto-approve"], working_dir="terraform")
        # 4. Clean up
        run_command(["rm", "-rf", "terraform", f"{service}-lambda.zip"], working_dir=".")
        run_command(["rm", package_filename], working_dir=".")