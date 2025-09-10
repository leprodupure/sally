import os
import boto3
import json
import psycopg2
import psycopg2.extras

def get_db_credentials():
    secret_name = os.environ['DB_SECRET_ARN']
    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

def handler(event, context):
    """
    This Lambda handler connects to the database and executes a SQL query provided in the event.
    """
    print(f"Received event: {event}")
    sql_query = event.get('query')

    if not sql_query:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': "Missing 'query' parameter in the event payload."})
        }

    credentials = get_db_credentials()
    conn_string = (
        f"host={credentials['endpoint']} "
        f"dbname={credentials['db_name']} "
        f"user={credentials['username']} "
        f"password={credentials['password']}"
    )

    conn = None
    try:
        print(f"Connecting to the database and executing query: {sql_query}")
        conn = psycopg2.connect(conn_string)
        # Use RealDictCursor to get results as a list of dictionaries
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        cur.execute(sql_query)
        
        # Check if the query returns rows
        if cur.description:
            results = cur.fetchall()
            print(f"Query returned {len(results)} row(s).")
            response_body = json.dumps(results, indent=4, default=str) # Use default=str to handle non-serializable types like datetimes
        else:
            # For queries that don't return rows (e.g., INSERT, UPDATE, DELETE)
            results = f"{cur.rowcount} rows affected."
            print(results)
            response_body = json.dumps({'message': results})

        conn.commit() # Commit any changes made by the query
        cur.close()
        
        return {
            'statusCode': 200,
            'body': response_body
        }

    except Exception as e:
        print(f"Error executing query: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
    finally:
        if conn:
            conn.close()
            print("Database connection closed.")
