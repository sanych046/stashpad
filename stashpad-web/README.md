# Stashpad Web Client

Browser-based client application that connects to the mobile device for synchronized access to notes.

## Features

- View, edit, and manage notes
- Receive real-time updates from mobile device
- Light client with no persistent storage
- QR code-based authentication with mobile device

## Architecture

- Built with Flutter Web
- `web_socket_channel` for real-time communication
- Client-side decryption using the `cryptography` package
- Fully responsive Material 3 design
