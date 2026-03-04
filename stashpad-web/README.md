# Stashpad Web Client

A lightweight, browser-based Flutter application that provides synchronized, end-to-end encrypted access to notes by pairing with the Stashpad mobile app.

## Features

- **Real-time Sync**: View and edit notes with instant synchronization via the coordination server.
- **Privacy-First**: Notes are decrypted in-memory on the client; no data is ever stored persistently in the browser.
- **Secure Pairing**: Easy setup by scanning a QR code from the Android app to establish a shared trust session.
- **End-to-End Encryption**: Uses AES-GCM for all relayed data, ensuring only your devices can read your notes.

## Architecture

- **Framework**: [Flutter for Web](https://flutter.dev/multi-platform/web)
- **Encryption**: Uses the `cryptography` package for client-side AES-GCM decryption/encryption.
- **Relay Mechanism**: [web_socket_channel](https://pub.dev/packages/web_socket_channel) for persistent communication with the coordination server.
- **State Management**: [Provider](https://pub.dev/packages/provider) for managing sync state and note data.

## Deployment with Docker

The web client is containerized and served via Nginx. It is integrated into the root `docker-compose.yml`.

### Build and Run

From the project root:

```bash
docker compose up -d stashpad-web
```

The web client will be available at `http://localhost:8080` (or the port configured in `docker-compose.yml`).

## Development

### Prerequisites

- Flutter SDK (stable channel)

### Running Locally

```bash
cd stashpad-web
flutter pub get
flutter run -d chrome
```
