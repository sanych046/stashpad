<div align="center">
  <h1>🌐 Stashpad Web Client</h1>
  <p>A lightweight, browser-based Flutter application providing synchronized, end-to-end encrypted access to notes by pairing with the Stashpad mobile app.</p>
</div>

---

## ✨ Features

- **Real-time Sync**: View and edit notes with instant synchronization via the coordination server.
- **Privacy-First**: Notes are decrypted in-memory on the client; no data is ever stored persistently in the browser.
- **Secure Pairing**: Easy setup by scanning a QR code from the Android app to establish a shared trust session.
- **End-to-End Encryption**: Uses AES-GCM for all relayed data, ensuring only your devices can read your notes.

## 🏗 Architecture & Tech Stack

- **Framework**: [Flutter for Web](https://flutter.dev/multi-platform/web)
- **Encryption**: Uses the `cryptography` package for client-side AES-GCM decryption/encryption.
- **Relay Mechanism**: [web_socket_channel](https://pub.dev/packages/web_socket_channel) for persistent communication with the coordination server.
- **State Management**: [Provider](https://pub.dev/packages/provider) for managing sync state and note data.

---

## 🚀 Running and Stopping

### 🐳 Using Docker (Recommended)

The web client is integrated into the project's root Docker Compose setup and builds into an Nginx-served static site.

#### Start the Web Client

From the project root directory, use the unified script:

```bash
./start_all.sh
```

Or, start it independently via Docker Compose:

```bash
docker compose up -d stashpad-web
```

_The web client will be accessible at `http://localhost:8080`._

#### Stop the Web Client

From the project root directory:

```bash
./stop_all.sh
```

Or, stop it independently:

```bash
docker compose stop stashpad-web
```

### 💻 Local Development (Flutter)

To run the web application natively with hot-reloading for active development:

1. **Install Dependencies**:
   Ensure you have the Flutter SDK installed on your system.

   ```bash
   cd stashpad-web
   flutter pub get
   ```

2. **Run Locally**:
   Launch the app in the Chrome browser:

   ```bash
   flutter run -d chrome
   ```

3. **Stop**:
   Press `q` or `Ctrl+C` in the terminal where the app is running.

---

## 🚢 Deployment

The provided `Dockerfile` uses a multi-stage process to build the Flutter web app and serve the static files using Nginx.

1. **Build the Image**:

   ```bash
   docker build -t stashpad-web ./stashpad-web
   ```

2. **Run the Container**:
   Deploy the container in detached mode, binding to port 80:

   ```bash
   docker run -d -p 8080:80 --restart always --name stashpad-web stashpad-web
   ```

3. **Configuration**: Ensure the Web Client is pointed to the correct domain of the deployed `stashpad-server` in its environment or configuration settings, and map it behind a reverse proxy for HTTPS termination.
