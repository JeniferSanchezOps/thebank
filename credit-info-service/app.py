import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Database connection configuration from environment variables
DB_HOST = os.environ.get('DB_HOST')
DB_NAME = os.environ.get('DB_NAME')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_PORT = os.environ.get('DB_PORT', 3306)

def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT
        )
        return connection
    except Error as e:
        print(f"Error connecting to MySQL database: {e}")
        return None

@app.route('/accounts/<account_sid>/credits', methods=['GET'])
def get_credits(account_sid):
    try:
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = connection.cursor(dictionary=True)
        
        query = """
        SELECT 
            id,
            balance,
            principal_amount,
            start_date,
            term
        FROM 
            credits
        WHERE 
            account_sid = %s
        ORDER BY 
            start_date DESC
        """
        
        cursor.execute(query, (account_sid,))
        credits = cursor.fetchall()
        
        # Format dates as ISO strings
        for credit in credits:
            if isinstance(credit['start_date'], datetime):
                credit['start_date'] = credit['start_date'].isoformat()
        
        cursor.close()
        connection.close()
        
        return jsonify(credits), 200
        
    except Error as e:
        return jsonify({'error': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)), debug=False)
