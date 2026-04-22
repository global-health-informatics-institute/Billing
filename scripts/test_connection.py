#!/usr/bin/env python3
"""
Simple script to test database connection
"""

import configparser
import mysql.connector
import sys


def test_connection():
    """Test database connection"""
    print("Testing database connection...")
    print("-" * 50)
    
    # Read config
    config = configparser.ConfigParser()
    config.read('config.ini')
    
    try:
        # Display connection info (without password)
        print(f"Host: {config.get('database', 'host')}")
        print(f"Port: {config.get('database', 'port')}")
        print(f"Database: {config.get('database', 'database')}")
        print(f"Username: {config.get('database', 'username')}")
        print("-" * 50)
        
        # Attempt connection
        connection = mysql.connector.connect(
            host=config.get('database', 'host'),
            port=config.getint('database', 'port'),
            database=config.get('database', 'database'),
            user=config.get('database', 'username'),
            password=config.get('database', 'password')
        )
        
        print("Connection successful")
        
        # Test a simple query
        cursor = connection.cursor()
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()
        print(f"MySQL version: {version[0]}")
        
        # List tables
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        print(f"Found {len(tables)} tables in database")
        
        cursor.close()
        connection.close()
        
        print("-" * 50)
        print("All tests passed! You can now run generate_report.py")
        return True
        
    except mysql.connector.Error as err:
        print(f"Connection failed: {err}")
        print("-" * 50)
        print("Please check your config.ini settings")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


if __name__ == '__main__':
    success = test_connection()
    sys.exit(0 if success else 1)
