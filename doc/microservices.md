# Sally Project: Microservice Architecture

This document provides a logical breakdown of the services that support the application's goals. It distinguishes between the currently implemented architecture and services that are planned for future development.

---

## Implemented Architecture

This section describes the components that are currently built and deployed.

### Core Infrastructure

This is not a runtime microservice but a foundational infrastructure stack responsible for deploying shared resources.

-   **Responsibility**: Manages and deploys the core, shared infrastructure that all other services depend on. This includes:
    -   The **Amazon RDS for PostgreSQL Instance**.
    -   The main **API Gateway** instance and its Cognito Authorizer.
    -   The **AWS Cognito User Pool and App Client** for authentication.
    -   Core networking components (e.g., VPC, subnets).
    -   The S3 bucket and CloudFront distribution for the **Frontend SPA**.
-   **Database Strategy**: A key architectural decision is the use of a **single RDS instance** shared across all environments. Data is isolated using a **multi-schema strategy**, where schema names are dynamically generated based on the service and stack name (e.g., `aquarium_staging`, `measurement_pr123`). This is a cost-effective approach that fully leverages the AWS Free Tier while enabling robust, multi-environment testing.
-   **Deployment**: Managed via Terraform in a dedicated directory (`services/core-infra/`).

### Aquarium Service

-   **Responsibility**: Manages `Aquarium` entities (CRUD operations). It associates aquariums with a specific user, identified by the user ID from the Cognito JWT token.
-   **Interactions**: Called by the frontend to manage aquariums.
-   **Database**: **Amazon RDS for PostgreSQL**.

### Measurement Service

-   **Responsibility**: A high-throughput service for ingesting and storing time-series parameter readings (e.g., `aquarium_id`, `parameter_type`, `value`, `timestamp`).
-   **Interactions**: Receives new parameter readings from the frontend and is queried by the frontend for charting.
-   **Database**: **Amazon RDS for PostgreSQL**.

### Frontend SPA

-   **Responsibility**: Provides the user interface for the application. It is a Single Page Application built with modern web technologies.
-   **Interactions**:
    -   Interacts with **AWS Cognito** for authentication.
    -   Makes authenticated API calls to the backend services via **API Gateway**.

---

## Planned Future Services

This section describes services that are part of the project's future vision but are not yet implemented.

### Species Catalog Service

-   **Responsibility**: To act as a knowledge base for aquatic species, storing information like tolerated water parameters (pH, GH, temp). It would include logic to fetch/update this data from external web sources.
-   **Interactions**: Would be queried by the `Aquarium Service` to validate species and by the `Analysis & Alerting Service` to get tolerance thresholds.
-   **Database**: Would likely use **Amazon RDS for PostgreSQL**, leveraging its `JSONB` data type to store flexible, semi-structured documents for each species.

### Analysis & Alerting Service

-   **Responsibility**: To be the "brains" of the system. It would compare data from the `Measurement Service` with thresholds from the `Species Catalog Service`. If a parameter were out of range, it would generate and persist an alert.
-   **Interactions**: Would read from the `Measurement`, `Aquarium`, and `Species Catalog` services. It would expose an API endpoint for the frontend to fetch active alerts.
-   **Database**: Would use **Amazon RDS for PostgreSQL** to store analysis configurations and the generated alerts.

---

## How They Fit Together

The diagram below illustrates the target architecture, including both implemented and planned future services.

```text
                               +---------------+
                               |  AWS Cognito  |
                               +-------+-------+
                                       ^
                                       | (Auth Flow)
                                       |
+----------------+  (API Calls w/ JWT)  +-----------------+
|                |--------------------->|                 |  (Poll for Alerts)
|  Frontend SPA  |                      |   API Gateway   |
|                |<---------------------| (w/ Authorizer) |
+----------------+                      +--------+--------+
                                                 |
                                                 | (Proxied Requests)
                                                 |
       +-----------------------------------------+-----------------------------------------+--------------------+
       |                                         |                                         |                    |
       v                                         v                                         v                    |
+----------------+                       +----------------+                       +-----------------+           |
| Aquarium Svc   |                       | Measurement Svc|                       | Species Cat. Svc|           |
| (RDS)          |                       | (RDS)          |                       | (RDS/JSONB)     |           |
+-------+--------+                       +-------+--------+                       +--------+--------+           |
        ^ (Reads)                                ^ (Reads)                                ^ (Reads)             |
        |                                        |                                        |                     |
        +----------------------------------------+----------------------------------------+                     |
                                                 |                                                              |
                                                 v                                                              |
                                       +------------------+                                                     |
                                       |  Analysis &      |                                                     |
                                       |  Alerting Svc    |<----------------------------------------------------+
                                       |  (RDS)           |
                                       +------------------+
```
