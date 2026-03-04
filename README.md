<div align="center">
  <h1>🔒 Stashpad</h1>
  <p>A secure, cross-platform note-taking application with end-to-end encryption and device-to-device synchronization.</p>
</div>

---

## 📖 Overview

Stashpad is designed to provide users with a secure way to store and access notes across different devices. The architecture follows the Signal model where the primary device (mobile phone) holds the master data and encryption keys, while other devices (web browsers) connect temporarily for access.

## 🏗 Architecture & Components

1. 📱 **[stashpad-android](stashpad-android/README.md)**: Primary client application (Flutter)
   - Main storage location for all user data
   - Handles encryption/decryption of notes
   - Authenticates web client access via QR code

2. 🌐 **[stashpad-web](stashpad-web/README.md)**: Web client application (Flutter Web)
   - Lightweight client with no persistent storage
   - Connects to mobile device for data access
   - Receives and decrypts data from mobile device

3. ⚙️ **[stashpad-server](stashpad-server/README.md)**: Coordination server (Python/FastAPI)
   - Acts as a "dumb pipe" between clients
   - Coordinates authentication process
   - Relays encrypted data without accessing content
   - Maintains no permanent user data

## 🛡 Security Model

- **End-to-End Encryption**: Utilizes client-side keys so the server never sees unencrypted data.
- **Master Keys**: The mobile device acts as the source of truth and holds the master encryption keys.
- **Secure Pairing**: QR code authentication ensures a secure pairing process between the mobile app and the web client.
- **Data in Transit**: All data is encrypted before transmission.

## 🔄 Synchronization Flow

1. User opens the web client and initiates a connection request.
2. The web client generates a temporary session token and displays a QR code.
3. The mobile app scans the QR code to authorize the session.
4. The mobile app encrypts notes with a session-specific key.
5. Encrypted data is transmitted through the server to the web client.
6. The web client decrypts data using the shared session key.
7. Real-time synchronization is maintained during the active session.

---

## 🚀 Getting Started

Local development and testing require starting the coordination server and the web client. The Android app is run manually on an emulator or physical device.

### 🐳 Running via Docker (Recommended for Testing/Deployment)

We provide handy scripts in the project root to manage the backend and web client containers.

#### Start All Services

To start the coordination server (`stashpad-server`) and the web client (`stashpad-web`) in the background:

```bash
./start_all.sh
```

_The script will automatically build the images and run them using Docker Compose._

- **Coordination Server**: Available at `http://localhost:8000`
- **Web Client**: Available at `http://localhost:8080`

#### Stop All Services

To stop and remove the running containers and networks:

```bash
./stop_all.sh
```

### 💻 Local Development (Manual Setup)

If you prefer to run the components manually without Docker for active development:

1. **Start the Server**:

   ```bash
   cd stashpad-server
   pip install -r requirements.txt
   uvicorn main:app --reload --port 8000
   ```

   _Stop by pressing `Ctrl+C`._

2. **Start the Web Client**:

   ```bash
   cd stashpad-web
   flutter pub get
   flutter run -d chrome
   ```

   _Stop by pressing `q` or `Ctrl+C`._

3. **Start the Android App**:
   The Android app must always be run manually for local development.
   ```bash
   cd stashpad-android
   flutter run
   ```
   _Stop by pressing `q` or `Ctrl+C`._

## 🚢 Deployment

For production deployment of the web and server components, you can use the provided Docker Compose configuration `docker-compose.yml`.

1. Ensure Docker and Docker Compose are installed on your production server.
2. Clone the repository.
3. Deploy in detached mode:
   ```bash
   docker compose up -d --build
   ```
4. Configure a reverse proxy (like Nginx or Traefik) to handle SSL/TLS termination and route traffic to the respective ports (`8000` for server, `8080` for web).
