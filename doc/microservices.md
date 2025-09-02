Here is a logical breakdown of services that would support the application's goals:

### 1. Auth Service (Implemented via AWS Cognito)

* **Responsibility**: This service will be implemented using **AWS Cognito**. Cognito will manage the user directory, user
  sign-up/sign-in, credential validation, and the issuance of JWT tokens (fulfilling the OAuth2 requirement). This
  offloads the heavy lifting of authentication and user management to a secure, managed AWS service.
* **Interactions**:
    *   The **Frontend SPA** will interact directly with Cognito (e.g., via the AWS Amplify library) for login, sign-up,
        and password recovery.
    *   **API Gateway** will use a Cognito Authorizer to automatically validate tokens on incoming requests, securing the
        backend microservices.

### 2. Aquarium Service

* **Responsibility**: Manages the core `Aquarium` entities. This includes CRUD (Create, Read, Update, Delete) operations
  for aquariums. It would also manage the relationship between a user and their aquariums, and which species reside in
  each aquarium.
* **Interactions**: The frontend would call this to list or edit aquariums. The Analysis Service would query it to know
  which species are in a given aquarium.

### 3. Measurement Service

* **Responsibility**: This is the high-throughput service for the core feature: logging parameters. Its primary job is
  to receive and store time-series data (e.g., `aquarium_id`, `parameter_type`, `value`, `timestamp`). It should be
  optimized for fast writes and efficient querying over time ranges for charting.
* **Interactions**: The frontend would send new parameter readings here. It would also query this service to get data
  for the charts.

### 4. Species Catalog Service

* **Responsibility**: Acts as a knowledge base for aquatic species. It stores information about different species and,
  most importantly, their tolerated water parameters (pH, GH, temperature ranges). This service would contain the logic
  to "get each species tolerated parameters from web sources," likely through a combination of a persistent database and
  a scheduled job that scrapes/fetches data from external APIs.
* **Interactions**: The Aquarium Service might use it to validate species names. The Analysis Service will heavily rely
  on it to fetch the tolerance thresholds for a given species.

### 5. Analysis & Alerting Service

* **Responsibility**: The "brains" of the system. This service compares the data from the **Measurement Service** with
  the tolerance data from the **Species Catalog Service**. It can run on a schedule (e.g., every hour) or be triggered
  by new measurements. If a parameter is out of the tolerated range for any species in an aquarium, it generates an
  alert.
* **Interactions**: It reads from the **Measurement Service**, **Aquarium Service**, and **Species Catalog Service**.
  When an alert condition is met, it would publish an event or call the **Notification Service**.

### 6. Notification Service

* **Responsibility**: A small, focused service that handles the delivery of alerts. It's decoupled from the logic of
  *detecting* an alert. It would take a formatted alert message and send it to the user via their preferred channels (
  e.g., email, push notification, SMS).
* **Interactions**: It receives requests from the **Analysis & Alerting Service** to send notifications.

## How They Fit Together

## Database Choices

Following the architectural decision to standardize on a single, highly scalable database technology where feasible,
**Amazon Aurora PostgreSQL** has been chosen as the primary data store for most microservices. This choice leverages
Aurora's high performance, availability, and scalability, combined with PostgreSQL's robust feature set and
extensibility.

Here's how Aurora PostgreSQL will be utilized by each service:

### 1. Auth Service
*   **Database**: None (Handled by AWS Cognito)
*   **Rationale**: AWS Cognito provides its own secure, managed user directory. By using Cognito, we eliminate the need
    for a dedicated database to store user credentials and profiles, simplifying the architecture and enhancing security.

### 2. Aquarium Service
*   **Database**: Amazon Aurora PostgreSQL
*   **Rationale**: Perfect for handling the relational data of `Aquarium` entities, their relationships with users, and
    the species residing within them.

### 3. Measurement Service
*   **Database**: Amazon Aurora PostgreSQL
*   **Rationale**: While a dedicated time-series database like Amazon Timestream is often optimal for high-volume
    time-series data, for the sake of consolidation and leveraging Aurora's capabilities, time-series parameter
    readings will be stored in a structured table format within Aurora PostgreSQL. This provides a good balance for
    initial scale and simplifies the technology stack.

### 4. Species Catalog Service
*   **Database**: Amazon Aurora PostgreSQL
*   **Rationale**: Will leverage PostgreSQL's powerful `JSONB` data type to store flexible, semi-structured documents
    for each species, including common names, aliases, and varied parameter thresholds. This allows for rich,
    searchable species data within a relational context.

### 5. Analysis & Alerting Service
*   **Database**: Amazon Aurora PostgreSQL
*   **Rationale**: Will store any necessary state for the analysis and alerting logic, such as alert thresholds,
    configuration, or last notification timestamps, benefiting from Aurora's reliability.

### 6. Notification Service
*   **Database**: None
*   **Rationale**: This service remains stateless, relying on other services (like the Auth Service) for user
    preferences and the Analysis & Alerting Service for notification content.

Here is a simple diagram illustrating how these services might interact:

```text
+----------------+      +---------------+      +----------------+
|                |----->|               |<---->|                |
|   Frontend SPA |      |  API Gateway  |      |   Auth Service |
|                |----->|               |      |                |
+----------------+      +-------+-------+      +----------------+
                                |
          +---------------------+---------------------+
          |                     |                     |
+---------v----------+ +--------v---------+ +---------v----------+
|                    | |                  | |                    |
|  Aquarium Service  | | Measurement Svc  | | Species Catalog Svc|
|                    | |                  | |                    |
+---------+----------+ +--------+---------+ +---------+----------+
          ^                     ^                     ^
          |                     |                     |
          |         +-----------+-----------+         |
          |         |                       |         |
          +---------| Analysis & Alerting Svc |---------+
                    |                       |
                    +-----------+-----------+
                                |
                      +---------v----------+
                      |                    |
                      | Notification Svc   |
                      |                    |
                      +--------------------+
```

This microservice architecture provides a clear separation of concerns, allowing you to develop, deploy, and scale each
part of your application independently, which aligns perfectly with the CI/CD strategy you've outlined.