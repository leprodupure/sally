import os
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

def get_url():
    """Get the database URL, handling the local development case."""
    db_secret_arn = os.environ.get("DB_SECRET_ARN")
    if not db_secret_arn:
        print("WARNING: DB_SECRET_ARN not set. Using a placeholder database URL.")
        print("         Local autogeneration will fail without a valid database connection.")
        return "postgresql://user:pass@localhost/sally"
    
    # In the Lambda environment, the database module will be at the root.
    try:
        from src.database import SQLALCHEMY_DATABASE_URL
    except ImportError:
        from database import SQLALCHEMY_DATABASE_URL
    return SQLALCHEMY_DATABASE_URL

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = get_url()
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
    # Set the sqlalchemy.url in the config object from our dynamic function
    config.set_main_option("sqlalchemy.url", get_url())

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
        connect_args={"connect_timeout": 10}
    )

    with connectable.connect() as connection:
        # Create the schema if it doesn't exist and commit the change
        connection.execute(text("CREATE SCHEMA IF NOT EXISTS aquarium"))
        connection.commit()

        # Now, configure the context for Alembic's transactional migrations
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
