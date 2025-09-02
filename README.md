# sally

Simple Aquarium Logger (SALly). Used to track aquariums parameters.

### Main features

- Track several aquariums,
- Record aquarium parameters (pH, GH, temperature, etc.) in a simple interface (smartphone mandatory, desktop is a
  plus),
- New parameters can be added on-the-fly,
- Display the parameters in charts,
- Define which species live in each aquarium,
- Get each species tolerated parameters from web sources,
- Display in the web page thresholds and alerts if the parameters are not tolerated.

This personal project aims at experimenting cloud technologies on a real use case (logging parameters of my aquariums).

## Architecture

The project is based on AWS managed services (Lambda, RDS, API Gateway, etc.). The frontend is a Single Page
Application hosted on a S3 bucket.

The project is divided in microservices.

### Repository Structure

To simplify development and deployment, this project uses a **monorepo** structure. All microservices, shared libraries,
and infrastructure code reside in a single Git repository. This approach provides several key advantages:

-   **Atomic Commits**: Changes that span multiple services (e.g., an API contract change) can be made in a single
    commit and pull request, ensuring consistency.
-   **Simplified Dependency Management**: All services use a single, consistent version of shared libraries.
-   **Unified CI/CD**: A single, intelligent pipeline can build, test, and deploy only the services that have changed.

The directory structure looks like this:

```
sally/
├── .github/
│   └── workflows/              # GitHub Actions CI/CD pipelines
├── docs/
│   └── microservices.md
├── infra/
│   └── core/                   # Terraform for shared infrastructure (VPC, DB Cluster, API Gateway)
├── services/
│   ├── frontend-spa/           # Source code for the Single Page Application
│   ├── aquarium-service/       # Source code and Terraform for this service
│   ├── measurement-service/
│   ├── species-catalog-service/
│   └── analysis-service/
├── libs/
│   └── sally-data-models/      # Example of a shared library for DTOs
└── README.md
```

Access to the application is controlled by OAuth2.

### Deployment

The deployment is ensured by a CI/CD pipeline using GitHub Actions. The pipelines follow these principles:

- Each microservice is compiled/packaged separately.
- The infrastructure (Terraform) is stored alongside the code/binary, in the same package/archive.
- The same package is compiled once, and deployed on all the environments (integration, production).
- A single, unified pipeline uses path filtering to determine which services have changed and need to be deployed.

Several deployment environments exist:

Production
: publicly available (for chosen users). This environment is deployed manually, when the integration environment is
marked as ready.

Integration
: restricted availability. Used to manually test the application before moving to production. Each time the project is
successfully deployed in the staging environment (i.e. the integration tests pass), the code is deployed to the
integration environment.

Staging
: restricted availability. Used to execute the integration tests. Each time the main branch evolves, the code is
deployed to the integration environment,

Temporary development environments
: each feature branch is deployed in a dedicated temporary environment. This environment is created when a pull request
is opened, and deleted when the PR is closed or merged.

All the microservices are deployed by a standard pipeline. The deployment is divided in two big steps: build, and
deploy.

#### Build microservices separately

A first pipeline is dedicated to the code compilation. No deployment is made at this time.
Each commit on a feature branch triggers the build step:

1. The code is compiled,
2. The Unit Tests are run,
3. SonarQube is called to check the code,
4. The code and the Terraform code of the microservice are zipped together and published on a package registry (usage of
   ORAS is needed if GitHub is used).

When the package is built on a feature branch, the package published on the registry is marked as _unstable_. When the
code is merged to the main branch, the pipeline is executed again, and the package is published as _release candidate_.

#### Deploy all the microservices

When a package is published, it is deployed by a second pipeline. This pipeline:

1. Collects all the packages that compose the project,
2. Deploys them as needed:
    - If a microservice depends on another, both are deployed in the correct order,
    - If a microservice did not change, it is not deployed again.
3. Runs the Integration Tests of the microservice,
4. Runs the Integration Tests of the application (dedicated project),
5. If the tests pass, mark the set of versions of all the packages as ready to production.

If the package is _unstable_, it is deployed on a temporary environment linked to the pull request id.

If the package is _release candidate_, it is deployed automatically on the staging environment to execute the
integration tests. If they pass, the package is also deployed on the integration environment for manual testing.
