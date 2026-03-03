# Dockerfile for development environment
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

# Install additional tools if needed
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set up user
USER developer
