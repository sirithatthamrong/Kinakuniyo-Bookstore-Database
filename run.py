from app import create_app
import os
from dotenv import load_dotenv

load_dotenv() # take environment variables from .env

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host=os.getenv('HOST', '0.0.0.0'), port=int(os.getenv('PORT', 5000)))