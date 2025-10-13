import os
import json
import psycopg2
import psycopg2.extras

def handler(event, context):
    """
    This Lambda handler connects to the database and executes a SQL query provided in the event.
    """
    print(f"Received event: {event}")
    sql_query = event.get('query')
    service_name = event.get('service_name')

    if not sql_query:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': "Missing 'query' parameter in the event payload."})
        }

    if not service_name:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': "Missing 'service_name' parameter in the event payload."})
        }

    conn_string = os.environ.get("DATABASE_URL")
    if not conn_string:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': "DATABASE_URL environment variable not set."})
        }

    stage = os.environ.get("STAGE")
    schema_name = f"{service_name}_{stage}" if stage else service_name

    conn = None
    try:
        print(f"Connecting to the database with schema {schema_name} and executing query: {sql_query}")
        conn = psycopg2.connect(conn_string, options=f'-c search_path={schema_name}')
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        cur.execute(sql_query)
        
        if cur.description:
            results = cur.fetchall()
            print(f"Query returned {len(results)} row(s).")
            response_body = json.dumps(results, indent=4, default=str)
        else:
            results = f"{cur.rowcount} rows affected."
            print(results)
            response_body = json.dumps({'message': results})

        conn.commit()
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
