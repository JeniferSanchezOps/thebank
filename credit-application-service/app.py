import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

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
@app.route("/health", methods=["GET"])
def health():
    return "OK", 200
@app.route('/accounts/<account_sid>/credit-applications', methods=['POST'])
def apply_for_credit(account_sid):
    if not request.json:
        return jsonify({'error': 'Missing request body'}), 400
    
    # Extract request data
    data = request.json
    required_fields = ['accountId', 'monthlyIncome', 'monthlyExpenses', 'dependents', 'requestedAmount']
    
    # Validate required fields
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    try:
        # Validate numeric fields
        for numeric_field in ['monthlyIncome', 'monthlyExpenses', 'dependents', 'requestedAmount']:
            if not isinstance(data[numeric_field], (int, float)) or data[numeric_field] < 0:
                return jsonify({'error': f'{numeric_field} must be a positive number'}), 400
        
        connection = get_db_connection()
        if connection is None:
            return jsonify({'error': 'Database connection failed'}), 500
        
        cursor = connection.cursor()
        
        # Insert credit application into database
        query = """
        INSERT INTO credit_applications 
        (account_sid, account_id, monthly_income, monthly_expenses, dependents, requested_amount, application_date) 
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
        """
        
        cursor.execute(query, (
            account_sid,
            data['accountId'],
            data['monthlyIncome'],
            data['monthlyExpenses'],
            data['dependents'],
            data['requestedAmount']
        ))
        
        application_id = cursor.lastrowid
        connection.commit()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'message': 'Credit application submitted successfully',
            'applicationId': application_id
        }), 201
        
    except Error as e:
        return jsonify({'error': f'Database error: {str(e)}'}), 500
    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)), debug=False)
