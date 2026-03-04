<div align="center">
  <h1>⚙️ Stashpad Server</h1>
  <p>Coordination server that facilitates communication between mobile and web clients without accessing user data. It acts as a stateless "dumb pipe" for end-to-end encrypted payloads.</p>
</div>

---

## ✨ Features

- **Authentication Coordination**: QR-based pairing logic.
- **Data Relay**: Real-time message forwarding via WebSockets.
- **Session Management**: In-memory session tracking for active pairings.
- **Privacy-First**: The server never decrypts or stores user notes.

## 🛠 Tech Stack

- **Python 3.11**
- **FastAPI**: Main high-performance web framework.
- **WebSockets**: For real-time relay.
- **Docker**: For containerized deployment.

## 🔌 API Endpoints

### HTTP

- `POST /api/auth/request`: Web client initiates a pairing session.
- `POST /api/auth/verify`: Mobile device authorizes a session.
- `GET /health`: Server health check.

### WebSocket

- `WS /ws/{user_id}`: Persistent connection for relaying encrypted messages.

---

## 🚀 Running and Stopping

### 🐳 Using Docker (Recommended)

Running the server via Docker ensures a consistent environment. You can manage it using the project's root scripts or Docker Compose directly.

#### Start the Server

From the project root directory, use the provided script to start the server alongside the web client:

```bash
./start_all.sh
```

Or, to start _only_ the server using Docker Compose:

```bash
docker compose up -d stashpad-server
```

#### Stop the Server

From the project root directory, stop all services:

```bash
./stop_all.sh
```

Or, to stop _only_ the server:

```bash
docker compose stop stashpad-server
```

### 💻 Local Development (Python)

To run the server natively for local development or debugging:

1. **Install Dependencies**:

   ```bash
   cd stashpad-server
   pip install -r requirements.txt
   ```

2. **Run with Uvicorn**:

   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

   _The `--reload` flag enables auto-reloading upon file changes._

3. **Stop**:
   Press `Ctrl+C` in your terminal.

---

## 🚢 Deployment

To deploy the server to a production environment:

1. Ensure Docker is installed on your host system.
2. Build and run the server container:
   ```bash
   docker build -t stashpad-server ./stashpad-server
   docker run -d -p 8000:8000 --restart always --name stashpad-server stashpad-server
   ```
3. Expose port `8000` through a reverse proxy (e.g., Nginx) and secure it with SSL/TLS (HTTPS/WSS) to ensure encrypted transit.

---

## 🧪 Testing

To verify the relay logic is functioning correctly, you can run the provided test script:

```bash
# Within the running Docker container
docker exec <container_name> python3 test_relay.py

# Or run it locally if dependencies are installed
python3 test_relay.py
```
