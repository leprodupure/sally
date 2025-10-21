# Sally Project: Environments and Deployment Pipeline

This document provides an overview of the project's deployment environments and the automated CI/CD pipeline that manages them, based on the principles outlined in the project README.

---

## 1. Deployment Environments

The project utilizes a four-tiered, multi-environment strategy to ensure stability, enable thorough testing, and provide a clear path to production.

### a. Production Environment

-   **Purpose**: The live environment, publicly available to chosen users.
-   **Stack Name**: `production`
-   **Deployment Trigger**: A **manual action**. A release is promoted to production only after the `integration` environment has been fully tested and approved. This is a deliberate gate to protect the live system.

### b. Integration Environment

-   **Purpose**: A stable, restricted-access environment for final manual testing and user acceptance testing (UAT) before a production release.
-   **Stack Name**: `integration`
-   **Deployment Trigger**: Automatic. A deployment to `integration` is triggered after a deployment to the `staging` environment succeeds and all automated integration tests pass.

### c. Staging Environment

-   **Purpose**: A restricted-access environment used exclusively for running automated integration and application-level tests.
-   **Stack Name**: `staging`
-   **Deployment Trigger**: Automatic. This environment is updated whenever new code is pushed or merged into the `main` branch.

### d. Preview (Temporary) Environments

-   **Purpose**: An ephemeral, fully-functional, and completely isolated stack created for a specific pull request. It allows developers and reviewers to test the exact changes in a live setting before the code is merged.
-   **Stack Name**: Dynamically generated based on the pull request number (e.g., `pr123`, `pr124`).
-   **Deployment Trigger**: A preview environment is automatically deployed when a pull request is opened or updated.
-   **Teardown**: To conserve resources, the entire stack is automatically destroyed when the corresponding pull request is closed.

---

## 2. The CI/CD Deployment Pipeline

The deployment process is fully automated using GitHub Actions. The pipeline is designed to manage the flow of code from a pull request through to production.

### Workflow for a Pull Request

1.  **Trigger**: A pull request is opened or updated.
2.  **Build**: The `build-and-package` job builds the changed services and publishes the artifacts to a package registry, marking them as *unstable*.
3.  **Deploy to Preview**: The `deploy-batch-*` jobs deploy the *unstable* packages to a dedicated preview environment (e.g., `pr123`). This involves:
    -   Running database migrations for the `pr123` schema.
    -   Running `terraform apply` to create or update the `pr123` resources.
4.  **Teardown**: When the PR is closed, the `destroy-batch-*` jobs run `terraform destroy` to remove all resources associated with the preview environment.

### Workflow for the Main Branch (Staging -> Integration -> Production)

1.  **Trigger**: A pull request is merged into the `main` branch.
2.  **Build**: The `build-and-package` job runs again, building the final version of the services. The resulting packages are marked as *release candidates*.
3.  **Deploy to Staging**: The pipeline automatically deploys the *release candidate* packages to the `staging` environment.
4.  **Automated Testing**: A dedicated job runs a full suite of integration tests against the `staging` environment.
5.  **Deploy to Integration**: **If the automated tests pass**, the pipeline automatically triggers a deployment of the same *release candidate* packages to the `integration` environment. This environment is now ready for manual testing and verification.
6.  **Manual Promotion to Production**: After the `integration` environment has been manually verified and approved, a team member with the appropriate permissions can trigger a **manual workflow** (e.g., a GitHub Actions manual dispatch or a release tag). This final workflow deploys the trusted *release candidate* packages to the `production` environment.
