# Stashpad Android Client

Primary client application for Android devices. This serves as the main storage location for all notes and handles encryption/decryption of user data.

## Features

- Create, modify, delete, and share notes
- Support for various media types (text, audio, video, documents)
- End-to-end encryption
- QR code authentication for web clients
- Synchronization with web clients

## Architecture

<!-- - Built with Android SDK -->

- Built with Flutter (Dart)
- Local encrypted storage using `sqflite` + `sqlcipher`
- Communication layer using `web_socket_channel`
- Secure QR scanning with `mobile_scanner`
