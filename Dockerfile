FROM python:3.9-slim

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

# Make port 10000 available to the world outside this container
EXPOSE 10000

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["flask", "run", "--host=0.0.0.0", "--port=10000"]