# Sally Project: AWS to GCP Migration Plan

This document outlines the strategy for migrating the "Sally" application from its current AWS infrastructure to the Google Cloud Platform (GCP). The project's serverless, container-free architecture and use of Terraform make it highly portable.

## High-Level Service Mapping

The following table shows a direct mapping of the AWS services currently in use to their primary GCP equivalents.

| AWS Service               | GCP Equivalent                       | Purpose in Your Project                                      |
|:--------------------------|:-------------------------------------|:-------------------------------------------------------------|
| **Lambda**                | **Cloud Functions**                  | To run backend service code and database migrations.         |
| **API Gateway**           | **API Gateway**                      | To define and secure the HTTP endpoints for your services.   |
| **RDS for PostgreSQL**    | **Cloud SQL for PostgreSQL**         | A fully managed relational database for application data.    |
| **S3**                    | **Cloud Storage**                    | To host static frontend files and store deployment packages. |
| **CloudFront**            | **Cloud Load Balancing + Cloud CDN** | To serve the frontend globally and route API traffic.        |
| **Cognito**               | **Identity Platform**                | To handle user authentication and JWT validation.            |
| **SSM Parameter Store**   | **Secret Manager**                   | To securely store and manage database credentials.           |
| **IAM**                   | **IAM**                              | To manage permissions and service accounts.                  |
| **VPC & Security Groups** | **VPC & Firewall Rules**             | To create a private network and control traffic.             |

---

## Detailed Migration Path

### 1. Backend Services (Lambda & API Gateway)

-   **Compute**: The Python service code (`main.py`, `crud.py`, etc.) currently in **AWS Lambda** will be deployed to **GCP Cloud Functions**. The core application logic remains identical, though function signatures and dependency management will require minor adjustments. The `migration_runner` and `query_runner` utilities will also become separate Cloud Functions.
-   **API Management**: An **GCP API Gateway** will be configured using an OpenAPI specification. It will define the API routes (e.g., `/api/aquariums`) and map them to the trigger URLs of the appropriate Cloud Functions, replacing the current AWS API Gateway setup.

### 2. Database (RDS)

-   **From RDS to Cloud SQL**: The PostgreSQL database will be migrated from **AWS RDS** to **GCP Cloud SQL for PostgreSQL**. Cloud SQL is GCP's direct equivalent, offering a fully managed, scalable, and secure database service. It will be configured within a GCP VPC for private network connectivity.

### 3. Frontend (S3 & CloudFront)

-   **Static Hosting**: The compiled Single-Page Application (SPA) assets (`index.html`, JS, CSS) will be moved from **AWS S3** to a **GCP Cloud Storage** bucket.
-   **Content Delivery & Routing**: The current **CloudFront** distribution will be replaced by an **External HTTP(S) Load Balancer**.
    -   **Path-Based Routing**: The load balancer will be configured to route traffic based on the request path.
    -   **Frontend Backend**: A backend service pointing to the Cloud Storage bucket will serve the SPA. **Cloud CDN** will be enabled on this backend to cache static assets at the edge.
    -   **API Backend**: A second backend service will point to the GCP API Gateway to handle API traffic for any path matching `/api/*`.

### 4. Authentication (Cognito)

-   **From Cognito to Identity Platform**: User management and authentication will be handled by **GCP Identity Platform** (built on Firebase Authentication). It provides a direct replacement for Cognito's user pools, supporting sign-up, sign-in, and the issuance of JWTs for authenticating API requests. The GCP API Gateway will be configured to validate these JWTs.

### 5. Infrastructure & CI/CD (Terraform & GitHub Actions)

-   **Infrastructure as Code**: The project will continue to use **Terraform**. The codebase will be updated to use the **Google Provider** instead of the AWS Provider. Existing `.tf` files will be rewritten to define GCP resources (e.g., `google_cloudfunctions_function`, `google_sql_database_instance`), but the declarative IaC workflow remains the same.
-   **CI/CD Pipeline**: **GitHub Actions** will remain the CI/CD platform. The workflow will be updated to authenticate with GCP using **Workload Identity Federation** (the recommended keyless approach). Pipeline steps will be modified to use `gcloud` CLI commands instead of the `aws` CLI.
