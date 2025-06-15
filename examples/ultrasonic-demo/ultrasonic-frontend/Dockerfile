# Use slim Python image for smaller size, autodetect if it's on a RPI
FROM python:3.12-slim-bookworm

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create static directory
RUN mkdir -p /app/static

# Copy source code and static files
COPY src/app.py .
COPY src/static/index.html /app/static/
COPY src/static/script.js /app/static/

# List files for debugging
RUN ls -la /app && ls -la /app/static

# Expose port
EXPOSE 80

# Run the application with gunicorn with proper timeouts
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--timeout", "30", "--workers", "2", "--log-level", "debug", "--access-logfile", "-", "--error-logfile", "-", "--capture-output", "app:app"]
