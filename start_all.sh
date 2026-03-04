#!/bin/bash

# Stashpad - Start All Services Script
# This script starts the coordination server and web client for local testing.

echo "Starting Stashpad coordination services..."

# Navigate to the project root (where docker-compose.yml is located)
PROJECT_ROOT=$(dirname "$0")
cd "$PROJECT_ROOT" || { echo "❌ Error: Failed to directory $PROJECT_ROOT"; exit 1; }

# Start the containers in detached mode
if docker compose up -d --build; then
    echo "---------------------------------------------------"
    echo "✅ Success! Stashpad services are now running."
    echo ""
    echo "Coordination Server: http://localhost:8000"
    echo "Web Client:         http://localhost:8080"
    echo ""
    echo "Note: The Android app still needs to be run manually"
    echo "via 'flutter run' from the stashpad-android directory."
    echo "---------------------------------------------------"
else
    echo "❌ Error: Failed to start Docker services."
    exit 1
fi
