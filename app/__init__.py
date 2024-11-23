from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from app.routes import register_routes

import os

db = SQLAlchemy()

def create_app():
    app = Flask(__name__)

    # Load environment variables
    postgres_user = os.getenv('POSTGRES_USER')
    postgres_password = os.getenv('POSTGRES_PASSWORD')
    postgres_host = os.getenv('POSTGRES_HOST')
    postgres_port = os.getenv('POSTGRES_PORT')
    postgres_db = os.getenv('POSTGRES_DB')

    print(f"POSTGRES_USER: {postgres_user}")
    print(f"POSTGRES_PASSWORD: {postgres_password}")
    print(f"POSTGRES_HOST: {postgres_host}")
    print(f"POSTGRES_PORT: {postgres_port}")
    print(f"POSTGRES_DB: {postgres_db}")

    app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{postgres_user}:{postgres_password}@{postgres_host}:{postgres_port}/{postgres_db}"
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
    register_routes(app)

    return app