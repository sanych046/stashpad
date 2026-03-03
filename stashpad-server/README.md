# Stashpad Server

Coordination server that facilitates communication between mobile and web clients without accessing user data.

## Features

- Authentication coordination
- Data relay between clients
- Session management
- Access control verification

## Architecture

- Minimal server built with Python and FastAPI
- Acts as a stateless "dumb pipe" for encrypted payloads
- Persistent WebSocket connections for real-time relay
- Temporary session state managed in-memory or with Redis
- End-to-end encryption maintained throughout
