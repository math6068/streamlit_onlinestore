import os
from dotenv import load_dotenv
import pymysql

# Load the environment variables from .env file
load_dotenv()

# Get the database credentials from environment variables
DB_ENDPOINT = os.getenv("DB_ENDPOINT")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_REGION = os.getenv("DB_REGION")
DB_NAME = os.getenv("DB_NAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")


# Establish a database connection
connection = pymysql.connect(
    host=DB_ENDPOINT,
    user=DB_USER,
    password=DB_PASSWORD,
    database=DB_NAME,
    port=int(DB_PORT),
)

# SQL query to create the 'products' table
sql_query = """
CREATE TABLE IF NOT EXISTS products (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (id)
);
"""

def create_datebase():
    """
    Create the 'products' table if it doesn't exist
    """
    with connection.cursor() as cursor:
        sql = "CREATE DATABASE customers"
        cursor.execute(sql)
    connection.commit()

def create_table():
    """
    Create the 'products' table if it doesn't exist
    """
    with connection.cursor() as cursor:
        cursor.execute(sql_query)
    connection.commit()

def read_data():
    """
    Read the last 10 products from the 'products' table
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM products ORDER BY id DESC LIMIT 10")
        data = cursor.fetchall()
    return data

def write_data(data):
    """
    Write new product data to the 'products' table
    """
    with connection.cursor() as cursor:
        cursor.executemany("INSERT INTO products (name, price, quantity) VALUES (%s, %s, %s)", data)
    connection.commit()
