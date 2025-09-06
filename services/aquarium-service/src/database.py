import os
import json
import boto3
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Fetch DB credentials from AWS Secrets Manager
secret_name = os.environ.get("DB_SECRET_ARN")
region_name = os.environ.get("AWS_REGION")

session = boto3.session.Session()
client = session.client(service_name='secretsmanager', region_name=region_name)

get_secret_value_response = client.get_secret_value(SecretId=secret_name)
secret = json.loads(get_secret_value_response['SecretString'])

DB_USERNAME = secret['username']
DB_PASSWORD = secret['password']
DB_ENDPOINT = secret['endpoint']
DB_NAME = secret['db_name']

SQLALCHEMY_DATABASE_URL = f"postgresql://{DB_USERNAME}:{DB_PASSWORD}@{DB_ENDPOINT}/{DB_NAME}"

engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()