#!/bin/bash

# Navigate to the server directory
cd "$(dirname "$0")/.."

echo "Stopping Stashpad Server..."
docker compose down

if [ $? -eq 0 ]; then
    echo "✅ Server stopped."
else
    echo "❌ Failed to stop the server."
    exit 1
fi
