#!/bin/bash

# Stashpad - Stop All Services Script
# This script stops and removes the coordination server and web client containers.

echo "Stopping Stashpad coordination services..."

# Navigate to the project root
PROJECT_ROOT=$(dirname "$0")
cd "$PROJECT_ROOT" || { echo "❌ Error: Failed to directory $PROJECT_ROOT"; exit 1; }

# Stop and remove containers
if docker compose down; then
    echo "✅ Success! Stashpad services have been stopped."
else
    echo "❌ Error: Failed to stop Docker services."
    exit 1
fi
