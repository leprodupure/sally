import os
import json
from collections import defaultdict


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
    Returns a list of batches, where each batch is a list of services
    that can be deployed in parallel.
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

    return sorted_batches


if __name__ == "__main__":
    """
    This script calculates the deployment order of services based on dependency files
    and outputs a JSON object representing deployment batches for the CI/CD pipeline.
    """
    services_dir = "services"

    print("--- Building Service Dependency Graph ---")
    graph = get_service_dependencies(services_dir)
    print(f"Found dependencies: {dict(graph)}")

    print("\n--- Calculating Deployment Order (Topological Sort) ---")
    deployment_batches = topological_sort(graph)
    
    print("\n--- Deployment Plan ---")
    # The output is a JSON string that the CI pipeline will parse
    print(json.dumps({"batch": deployment_batches}))