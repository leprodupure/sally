import os
import json
import boto3
import sys
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool, text

from alembic import context

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Add the project root to the Python path to allow imports from src/
sys.path.insert(0, os.path.realpath(os.path.join(os.path.dirname(__file__), '..')))

# add your model's MetaData object here
# for 'autogenerate' support
# This try/except block allows the script to work both locally (with a src/ dir)
# and in the Lambda (where src/ is flattened).
try:
    from src.models import Base
except ImportError:
    from models import Base

target_metadata = Base.metadata

def get_database_url():
    """
    Constructs the database URL from a JSON secret stored in an environment variable.
    """
    secret_arn = os.environ.get("DB_SECRET_ARN")
    if not secret_arn:
        raise ValueError("DB_SECRET_ARN environment variable not set.")

    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager')
    get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
    secret_string = get_secret_value_response['SecretString']

    secret = json.loads(secret_string)
    db_user = secret['username']
    db_pass = secret['password']
    db_host = secret['endpoint']
    db_name = secret['db_name']
    return f"postgresql+psycopg2://{db_user}:{db_pass}@{db_host}/{db_name}"

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = get_database_url()
    config.set_main_option("sqlalchemy.url", url)
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        version_table_schema='aquarium'
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    config.set_main_option("sqlalchemy.url", get_database_url())

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        connect_args={"connect_timeout": 10}
    )

    with connectable.connect() as connection:
        # Create the schema if it doesn't exist before configuring the context
        connection.execute(text("CREATE SCHEMA IF NOT EXISTS aquarium"))

        context.configure(
            connection=connection, 
            target_metadata=target_metadata,
            version_table_schema='aquarium'
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
