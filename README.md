# Stashpad

A secure, cross-platform note-taking application with end-to-end encryption and device-to-device synchronization.

## Overview

Stashpad is designed to provide users with a secure way to store and access notes across different devices. The architecture follows the Signal model where the primary device (mobile phone) holds the master data and encryption keys, while other devices (web browsers) connect temporarily for access.

## Architecture

### Components

1. **stashpad-android**: Primary client application (Flutter)
   - Main storage location for all user data
   - Handles encryption/decryption of notes
   - Authenticates web client access via QR code

2. **stashpad-web**: Flutter Web client application
   - Lightweight client with no persistent storage
   - Connects to mobile device for data access
   - Receives and decrypts data from mobile device

3. **stashpad-server**: Coordination server (Python/FastAPI)
   - Acts as a "dumb pipe" between clients
   - Coordinates authentication process
   - Relays encrypted data without accessing content
   - Maintains no permanent user data

### Security Model

- End-to-end encryption using client-side keys
- Mobile device holds the master encryption keys
- Server never sees unencrypted data
- QR code authentication ensures secure pairing
- All data encrypted before transmission

### Synchronization Flow

1. User opens web client and initiates connection request
2. Web client generates temporary session token and displays QR code
3. Mobile app scans QR code to authorize the session
4. Mobile app encrypts notes with session-specific key
5. Encrypted data transmitted through server to web client
6. Web client decrypts data using shared session key
7. Real-time synchronization maintained during session

## Getting Started

Each component has its own setup instructions in its respective README file.
