import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import boto3
import json

def get_db_credentials():
    secret_name = os.environ['DB_SECRET_ARN']
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

credentials = get_db_credentials()

SQLALCHEMY_DATABASE_URL = (
    f"postgresql+psycopg2://{credentials['username']}:{credentials['password']}"
    f"@{credentials['endpoint']}/{credentials['db_name']}"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
