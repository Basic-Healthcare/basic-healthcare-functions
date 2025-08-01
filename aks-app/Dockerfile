FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements-aks.txt .
RUN pip install --no-cache-dir -r requirements-aks.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 8080

# Set environment variable
ENV PORT=8080

# Run the application
CMD ["python", "app.py"]
