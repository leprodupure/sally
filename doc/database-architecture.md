# Sally Project: Database Architecture

This document explains the project's database architecture, which consists of a single shared AWS RDS instance that uses multiple, dynamically-created schemas for data isolation.

---

## The "Why": Rationale for a Single RDS Instance

The primary driver for this architectural decision is **cost-effectiveness**, especially when leveraging the AWS Free Tier and managing multiple non-production environments.

### 1. AWS Free Tier Optimization

-   **The Offer**: The AWS Free Tier includes 750 hours per month of a `db.t3.micro` or `db.t4g.micro` instance. This is enough to run **one** database instance continuously for free.
-   **The Problem**: Our architecture supports multiple, ephemeral environments (one for `staging` and one for each pull request, e.g., `pr123`, `pr124`). Provisioning a separate RDS instance for each of these stacks would be prohibitively expensive, as each new instance would fall outside the Free Tier and incur hourly charges.
-   **The Solution**: By sharing a single RDS instance across all non-production stacks, we can stay within the Free Tier for our baseline `staging` environment while still supporting isolated data for all other preview environments at no extra database cost.

### 2. Operational Simplicity

Managing a single database instance is significantly simpler than managing a fleet of them. Centralizing the database simplifies:

-   **Monitoring and Alerting**: One set of CloudWatch alarms to configure.
-   **Backup and Recovery**: One backup plan to manage.
-   **Major Version Upgrades**: One upgrade process to execute.

### 3. Resource Efficiency

For development and testing workloads, the traffic is typically low and sporadic. A single small instance (like a `t4g.micro`) has more than enough CPU, memory, and I/O capacity to handle dozens of logically-separated schemas without performance degradation.

---

## The "How": Implementation Details

While the database *instance* is shared, the *data* for each service in each stack is logically isolated using PostgreSQL schemas.

### 1. Dynamic Schema Naming

A consistent naming convention is used to prevent collisions:

**Schema Name = `<service_name>_<stack_name>`**

-   Example for `aquarium-service` in a PR: `aquarium_pr123`
-   Example for `measurement-service` in staging: `measurement_staging`

This logic is centralized in a `get_schema()` function within each service's `src/models.py` file. This function reads the `STAGE` environment variable (which holds the stack name) to construct the appropriate schema name at runtime.

### 2. Automated Schema Deployment and Migrations

The process of creating and updating these schemas is fully automated by our CI/CD pipeline using **Alembic**.

Here is the step-by-step workflow:

1.  **CI/CD Trigger**: The GitHub Actions pipeline is triggered by a code change in a service (e.g., a new model in `aquarium-service`).

2.  **Invoke Migration Lambda**: The pipeline invokes a dedicated `migration-runner` Lambda function. Crucially, this Lambda's Terraform configuration ensures it has the `STAGE` environment variable set correctly for the stack being deployed (e.g., `pr123`).

3.  **Alembic Execution**: The `migration-runner` Lambda executes the `alembic upgrade head` command for the specific service that changed.

4.  **`env.py` Configuration**: Alembic starts by running the `alembic/env.py` script.
    -   This script imports and calls the `get_schema()` function from the service's models.
    -   It dynamically determines the target schema name (e.g., `aquarium_pr123`).
    -   It connects to the database and ensures the schema exists by running `CREATE SCHEMA IF NOT EXISTS aquarium_pr123`.
    -   It then sets this schema name on Alembic's global configuration object: `config.set_main_option("schema", "aquarium_pr123")`.

5.  **Run Migration Scripts**: Alembic discovers the required migration script (e.g., `versions/1a2b3c_create_aquariums_table.py`).

6.  **Targeted DDL**: The migration script retrieves the schema name from the configuration (`op.get_context().config.get_main_option('schema')`) and uses it to execute the DDL commands against the correct schema (e.g., `op.create_table('aquariums', ..., schema='aquarium_pr123')`).

### 3. Application Runtime

When the service's main application Lambda (e.g., `aquarium-service`) runs, it uses the **exact same `get_schema()` function** and `STAGE` environment variable to configure its SQLAlchemy models. This guarantees that when the application queries the database, it connects to and interacts with the exact same schema that the migration scripts configured, ensuring perfect alignment between the application and its data.
