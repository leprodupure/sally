Here is a logical breakdown of services that would support the application's goals:

### 1. Auth Service (Implemented via AWS Cognito)

*   **Responsibility**: Implemented using **AWS Cognito** to manage the user directory, user sign-up/sign-in, credential
    validation, and the issuance of JWT tokens. This offloads the heavy lifting of authentication to a secure, managed
    AWS service.
* **Interactions**:
    *   The **Frontend SPA** will interact directly with Cognito (e.g., via the AWS Amplify library) for login, sign-up,
        and password recovery.
    *   **API Gateway** will use a Cognito Authorizer to automatically validate tokens on incoming requests, securing the
        backend microservices.
*   **Database**: None. User data is managed securely within AWS Cognito.

### 2. Aquarium Service

*   **Responsibility**: Manages `Aquarium` entities (CRUD operations). It associates aquariums with a specific user,
    identified by the user ID from the Cognito JWT token.
*   **Interactions**: Called by the frontend to manage aquariums. Queried by the `Analysis & Alerting Service`.
*   **Database**: **Amazon Aurora PostgreSQL**. Perfect for handling the relational data of aquariums and their
    relationship to users.

### 3. Measurement Service

*   **Responsibility**: A high-throughput service for ingesting and storing time-series parameter readings (e.g.,
    `aquarium_id`, `parameter_type`, `value`, `timestamp`).
*   **Interactions**: Receives new parameter readings from the frontend. Queried by the frontend for charting and by the
    `Analysis & Alerting Service`.
*   **Database**: **Amazon Aurora PostgreSQL**. For consolidation, time-series data will be stored in a structured table.
    This simplifies the stack, though a dedicated time-series database could be a future optimization.

### 4. Species Catalog Service

*   **Responsibility**: Acts as a knowledge base for aquatic species, storing information like tolerated water parameters
    (pH, GH, temp). Includes logic to fetch/update this data from external web sources.
*   **Interactions**: Queried by the `Aquarium Service` to validate species and by the `Analysis & Alerting Service` to
    get tolerance thresholds.
*   **Database**: **Amazon Aurora PostgreSQL**. Leverages PostgreSQL's powerful `JSONB` data type to store flexible,
    semi-structured documents for each species (common names, aliases, parameters).

### 5. Analysis & Alerting Service

*   **Responsibility**: The "brains" of the system. Compares data from the `Measurement Service` with thresholds from the
    `Species Catalog Service`. If a parameter is out of range, it generates and persists an alert.
*   **Interactions**: Reads from the `Measurement`, `Aquarium`, and `Species Catalog` services. Exposes an API endpoint
    for the frontend to fetch active alerts.
*   **Database**: **Amazon Aurora PostgreSQL**. Stores analysis configurations and the generated alerts to be displayed
    in the UI.

### 6. Frontend SPA

*   **Responsibility**: Provides the user interface for the application. It is a Single Page Application (e.g., built
    with React, Vue, or Angular).
*   **Interactions**:
    *   Interacts with **AWS Cognito** for authentication.
    *   Makes authenticated API calls to the backend services via **API Gateway**.
    *   Periodically polls the `Analysis & Alerting Service` for new alerts to display on the web page.
*   **Deployment**: Hosted as a static website on an **Amazon S3 bucket**, served globally via **Amazon CloudFront**.

## Inter-Service Communication

Communication between services primarily follows a synchronous, API-driven pattern. The `API Gateway` acts as the
single entry point, routing requests to the appropriate backend service. For asynchronous tasks, such as triggering an
analysis run after a new measurement, an event-based pattern using services like **Amazon SNS** or **EventBridge** can
be used to decouple services and improve resilience.

## How They Fit Together

Here is a simple diagram illustrating how these services might interact:

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
       +-----------------------------------------+-----------------------------------------+
       |                                         |                                         |
       v                                         v                                         v
+----------------+                       +----------------+                       +-----------------+
| Aquarium Svc   |                       | Measurement Svc|                       | Species Cat. Svc|
| (Aurora)       |                       | (Aurora)       |                       | (Aurora/JSONB)  |
+-------+--------+                       +-------+--------+                       +--------+--------+
        ^ (Reads)                                ^ (Reads)                                ^ (Reads)
        |                                        |                                        |
        +----------------------------------------+----------------------------------------+
                                                 |
                                                 v
                                       +------------------+
                                       |  Analysis &      |
                                       |  Alerting Svc    |
                                       |  (Aurora)        |
                                       +------------------+
```

This microservice architecture provides a clear separation of concerns, allowing you to develop, deploy, and scale each
part of your application independently, which aligns perfectly with the CI/CD strategy you've outlined.