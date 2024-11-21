FROM python:3.8-slim

WORKDIR /app


COPY requirements.txt requirements.txt

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Set environment variables
ENV FLASK_APP=run.py
ENV FLASK_ENV=production

# Expose the port the app runs on
EXPOSE 10000

# Run the application
CMD ["python", "run.py"]