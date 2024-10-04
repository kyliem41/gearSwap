import psycopg2
import os

# Lambda function
def lambda_handler(event, context):
    # Database connection parameters
    db_host = os.environ['localhost']   # Set environment variables in Lambda for security
    db_name = os.environ['gearSwap']
    db_user = os.environ['postgres']
    db_password = os.environ['postgres']
    
    # Data to insert (usually this comes from the 'event')
    username = event['username']
    email = event['email']
    password = event['password']    # Assuming password is hashed beforehand
    profile_info = event.get('profileInfo')  # Optional or null if not provided

    # SQL query to insert a new user
    insert_query = """
    INSERT INTO users.users (username, email, password, profileInfo) 
    VALUES (%s, %s, %s, %s)
    RETURNING id, username, email, joinDate;
    """
    
    # Establish a connection to PostgreSQL
    try:
        conn = psycopg2.connect(
            host=db_host,
            dbname=db_name,
            user=db_user,
            password=db_password
        )
        cursor = conn.cursor()
        
        # Execute the insert query
        cursor.execute(insert_query, (username, email, password, profile_info))
        
        # Commit the transaction
        conn.commit()
        
        # Fetch the newly created user details
        new_user = cursor.fetchone()
        
        # Close the connection
        cursor.close()
        conn.close()
        
        # Return the created user information
        return {
            "statusCode": 200,
            "body": {
                "id": new_user[0],
                "username": new_user[1],
                "email": new_user[2],
                "joinDate": new_user[3].strftime('%Y-%m-%d %H:%M:%S')
            }
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error creating user: {str(e)}"
        }