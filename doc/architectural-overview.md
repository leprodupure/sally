# Sally Project: Architectural Overview

This document provides a high-level overview of the key architectural aspects and design principles of the "Sally" project.

---

### 1. Microservices Architecture

The project follows a microservices paradigm, breaking the application down into smaller, independent services.

-   **Services**: The system includes distinct components like `aquarium-service`, `measurement-service`, and a `core-infra` service for shared resources.
-   **Benefits**: This approach promotes a strong separation of concerns, enables independent development and deployment cycles, and offers technological flexibility.

### 2. Serverless-First Compute Model

The entire backend runs on a serverless model, abstracting away the need to manage servers, operating systems, or runtimes.

-   **Technology**: **AWS Lambda** is used to execute the application code for all backend services and for operational tasks like database migrations and ad-hoc queries.
-   **Benefits**: This provides automatic scaling based on demand, reduces operational overhead, and leverages a cost-effective pay-per-use pricing model.

### 3. API-Driven Design

All backend services are exposed via a managed, secure HTTP interface.

-   **Technology**: **AWS API Gateway** serves as the single, unified entry point for all API requests.
-   **Implementation**: It is configured to route incoming requests to the appropriate backend Lambda function based on the request path. It also acts as the primary security enforcement point.

### 4. Decoupled Frontend (Single-Page Application)

The frontend is a modern Single-Page Application (SPA) that is completely decoupled from the backend services.

-   **Technology**: Static assets (HTML, JavaScript, CSS) are hosted on **AWS S3** and distributed globally via the **AWS CloudFront** CDN for low-latency delivery.
-   **Interaction**: The SPA runs in the user's browser and communicates with the backend by making asynchronous HTTP requests to the API Gateway endpoints.

### 5. Managed Relational Database

The project relies on a managed database service to offload the complexities of database administration.

-   **Technology**: **AWS RDS for PostgreSQL** provides the central, relational data store.
-   **Implementation**: A single database instance is shared across all services, but data is logically isolated using a **multi-tenant schema strategy** (e.g., `aquarium_staging`, `measurement_staging`), a key architectural decision that ensures data integrity between environments.

### 6. Infrastructure as Code (IaC)

The entire cloud infrastructure is defined and managed declaratively in version-controlled files.

-   **Technology**: **Terraform** is used to provision and manage all AWS resources, from the foundational VPC and database to the individual Lambda functions and API Gateway routes.
-   **Benefits**: This ensures that all environments are reproducible and consistent. It simplifies the process of creating, updating, and destroying infrastructure.

### 7. Comprehensive CI/CD Automation

The project features a mature, automated pipeline for continuous integration and continuous deployment.

-   **Technology**: **GitHub Actions** orchestrates the end-to-end build, test, and deployment process.
-   **Implementation**: The pipeline automatically detects changes in the codebase, builds and packages services, runs database migrations, and applies infrastructure changes using Terraform.

### 8. Dynamic Multi-Environment Strategy

The architecture is designed to support multiple, isolated environments from a single codebase.

-   **Implementation**: The combination of Terraform **workspaces** and dynamically generated **stack names** (e.g., `staging`, `pr123`) enables the automated creation of ephemeral "preview environments" for each pull request.
-   **Benefits**: This strategy allows for robust testing and validation of changes in an isolated, production-like environment before they are merged into the main branch.

### 9. Centralized Security and Authentication

Security is managed centrally and enforced at the edge of the network.

-   **Technology**: **AWS Cognito** handles user authentication (user pools), while **AWS IAM** manages resource permissions.
-   **Implementation**: API Gateway uses a Cognito authorizer to validate a JSON Web Token (JWT) on every incoming API request. Network security is handled by a **VPC** and **Security Groups**, ensuring critical resources like the database are not exposed to the public internet.
