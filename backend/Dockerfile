FROM python:3.10-slim

WORKDIR /app

# Install system dependencies needed for compiling packages like reportlab, psycopg2, etc.
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg-dev \
    zlib1g-dev \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Run the application on the dynamic port assigned by Railway
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
