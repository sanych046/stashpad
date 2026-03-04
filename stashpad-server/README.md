# Stashpad Server

Coordination server that facilitates communication between mobile and web clients without accessing user data. It acts as a stateless "dumb pipe" for end-to-end encrypted payloads.

## Features

- **Authentication coordination**: QR-based pairing logic.
- **Data relay**: Real-time message forwarding via WebSockets.
- **Session management**: In-memory session tracking for active pairings.
- **Privacy-first**: The server never decrypts or stores user notes.

## Tech Stack

- **Python 3.11**
- **FastAPI**: Main web framework.
- **WebSockets**: For real-time relay.
- **Docker**: For containerized deployment.

## API Endpoints

### HTTP

- `POST /api/auth/request`: Web client initiates a pairing session.
- `POST /api/auth/verify`: Mobile device authorizes a session.
- `GET /health`: Server health check.

### WebSocket

- `WS /ws/{user_id}`: Persistent connection for relaying encrypted messages.

## Getting Started

### Prerequisites

- Docker and Docker Compose

### Running the Server

Use the provided convenience scripts:

- **Start**: `./scripts/start.sh`
- **Stop**: `./scripts/stop.sh`

Alternatively, use Docker Compose directly:

```bash
docker compose up -d
```

## Testing

An integration test script is provided to verify the relay logic:

```bash
docker exec <container_id> python3 test_relay.py
```
