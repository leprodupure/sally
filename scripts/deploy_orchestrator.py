import os
import sys
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


def s3_object_exists(bucket, key):
    """Checks if an object exists in an S3 bucket."""
    print(f"Checking for S3 object: s3://{bucket}/{key}")
    command = ["aws", "s3api", "head-object", "--bucket", bucket, "--key", key]
    # We expect this command to fail if the object doesn't exist, so we capture the return code.
    # We redirect stdout and stderr to DEVNULL to keep the output clean.
    result = subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return result.returncode == 0


def get_service_dependencies(services_dir):
    """
    Builds a dependency graph from 'dependencies.txt' files.
    Returns a dictionary where keys are services and values are sets of their dependencies.
    """
    dependency_graph = defaultdict(set)
    service_list = [s for s in os.listdir(services_dir) if os.path.isdir(os.path.join(services_dir, s))]

    for service in service_list:
        # Ensure every discovered service exists as a key in the graph, even if it has no dependencies.
        # This is crucial for the topological sort to include standalone services.
        if service not in dependency_graph:
            dependency_graph[service] = set()
        
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
    sorted_batches = []
    processed_nodes = set()
    nodes_to_process = set(dependency_graph)

    while nodes_to_process:
        # find all the nodes whose dependencies were already found. All of them can be deployed in a batch.
        batch = [k for k in nodes_to_process if dependency_graph[k].issubset(processed_nodes)]
        if not batch:
            raise Exception("Cycle detected in dependencies! Cannot determine deployment order.")
        # Add it to the list of batches.
        sorted_batches.append(batch)
        # Also add the batch to the list of processed nodes and remove it from the nodes to process.
        processed_nodes.update(batch)
        nodes_to_process.difference_update(batch)

    return [item for sublist in sorted_batches for item in sublist]


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

        # Determine the S3 key for the package, with fallback logic
        versioned_s3_key = f"{s3_key_prefix}/{service}-{s3_key_version}.zip"
        rc_s3_key = f"{s3_key_prefix}/{service}-rc.zip"

        s3_key_to_download = versioned_s3_key
        if not s3_object_exists(s3_bucket, versioned_s3_key):
            print(f"Package '{versioned_s3_key}' not found. Falling back to 'rc' version.")
            s3_key_to_download = rc_s3_key
            if not s3_object_exists(s3_bucket, rc_s3_key):
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