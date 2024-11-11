# Use the official lightweight Python image
FROM python:3.10-slim

# Set environment variables to ensure Python output is flushed immediately
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set the working directory inside the container
WORKDIR /opt/app

# Copy only the requirements file first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install system dependencies required by the application
RUN apt-get update && \
    apt-get upgrade -yq ca-certificates && \
    apt-get install -yq --no-install-recommends \
        prometheus-node-exporter \
        procps curl gnupg \ 
        && \
    
    # Clean up to reduce image size
    rm -rf /var/lib/apt/lists/*

# Copy the rest of the application code
COPY . .

# Expose the necessary ports
EXPOSE 7860 8000 9100

# Set environment variables specific to your application
ENV GRADIO_SERVER_NAME="0.0.0.0"

# Define the default command to run both Prometheus Node Exporter and your Python app
CMD ["/opt/app/scripts/docker_deploy.sh"]