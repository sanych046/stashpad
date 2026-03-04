#!/bin/bash

# Navigate to the server directory
cd "$(dirname "$0")/.."

echo "🚀 Starting Stashpad Server..."
docker compose up -d --build

if [ $? -eq 0 ]; then
    echo "✅ Server is running at http://localhost:8000"
    echo "Logs can be viewed with: docker compose logs -f"
else
    echo "❌ Failed to start the server."
    exit 1
fi
