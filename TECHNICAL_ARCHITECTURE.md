# Stashpad Technical Architecture

## Security & Encryption Approach

### End-to-End Encryption Model

- Stashpad implements a Signal Protocol-based encryption system (X3DH + Double Ratchet) where:
- The Android mobile device is the primary trust anchor and "Prekey" provider
- Encryption keys are generated and stored only on the mobile device
- The server never has access to unencrypted data (acts as a "dumb pipe")
- Web clients receive encrypted data and decrypt it locally using session keys established through the Double Ratchet algorithm

### Key Management

- Master encryption key pair generated on mobile device during account setup
- Private key remains on mobile device only (never transmitted)
- Public key distributed to authorized web clients during QR code authentication
- Session-specific symmetric keys generated for each web client session
- Keys encrypted with user's master key before storage on device

### Data Encryption

- Individual notes encrypted with AES-256-GCM before storage
- Note metadata (title, category) encrypted separately
- Attachments encrypted individually before storage
- All data encrypted before transmission to server

## Synchronization Mechanism

### Connection Flow

```
Web Client                    Server                     Mobile Client
     |                          |                            |
     |------ Request Access ----->|                            |
     |                          |---- Request Access -------->|
     |                          |                            |
     |<----- Display QR --------|                            |
     |                          |                            |
     |                          |<--- Scan & Authorize ----- |
     |                          |                            |
     |<-- Session Established ---|<--- Approve Connection ----|
     |                          |                            |
     |<-- Encrypted Data ------->|<--- Relay Data ---------- |
     |                          |                          |
```

### Real-time Sync

- WebSocket connections maintain persistent communication
- Mobile client pushes updates to server when notes change
- Server relays encrypted updates to connected web clients
- Conflict resolution handled on mobile device (authoritative source)
- Timestamp-based version control prevents data loss

### Session Management

- Temporary session tokens generated for each web client connection
- Sessions expire after predetermined timeout period
- Mobile client can terminate sessions remotely
- Multiple concurrent web sessions supported

## Data Models

### Note Entity

```json
{
  "id": "unique_identifier",
  "title": "Note title",
  "content": "Text content of the note",
  "category": "Category tag",
  "type": "TEXT|AUDIO|VIDEO|FILE_ATTACHMENT",
  "attachments": [
    {
      "id": "attachment_id",
      "filename": "original_filename",
      "size": 123456,
      "mimeType": "application/pdf",
      "encryptedData": "encrypted_binary_data"
    }
  ],
  "createdAt": "ISO_timestamp",
  "updatedAt": "ISO_timestamp",
  "isPinned": true|false,
  "color": "#hex_color_code",
  "sharedWith": ["user_id1", "user_id2"]
}
```

### User Session

```json
{
  "sessionId": "session_identifier",
  "userId": "user_identifier",
  "deviceType": "WEB_BROWSER|MOBILE",
  "deviceInfo": {
    "browser": "Chrome 98.0",
    "os": "Windows 10",
    "resolution": "1920x1080"
  },
  "createdAt": "ISO_timestamp",
  "expiresAt": "ISO_timestamp",
  "isActive": true|false
}
```

### Encrypted Payload Format

```json
{
  "nonce": "base64_encoded_nonce",
  "ciphertext": "base64_encoded_encrypted_content",
  "tag": "base64_encoded_authentication_tag",
  "keyId": "identifier_for_decryption_key"
}
```

## API Specifications

### WebSocket Commands

#### From Mobile to Server

- `SYNC_NOTE`: Send updated note to server for distribution
- `DELETE_NOTE`: Notify server of deleted note
- `SHARE_ACCESS`: Grant access to another user
- `REVOKE_ACCESS`: Revoke access from user

#### From Web Client to Server

- `REQUEST_ACCESS`: Request access to user's notes
- `UPDATE_NOTE`: Send note update to mobile device
- `PIN_NOTE`: Toggle pin status
- `CHANGE_CATEGORY`: Update note category

#### From Server to Clients

- `ACCESS_GRANTED`: Authentication successful
- `ACCESS_DENIED`: Authentication failed
- `NOTE_UPDATE`: Note has been updated
- `NOTE_DELETE`: Note has been deleted
- `SESSION_EXPIRED`: Session has expired

### HTTP Endpoints (Server)

#### Authentication

- `POST /api/auth/request`: Request authentication session
- `POST /api/auth/verify`: Verify QR code token

#### Notes

- `GET /api/notes/sync`: Get latest sync token
- `POST /api/notes/batch`: Batch send note updates

## QR Code Authentication System

### Token Generation

1. Web client generates random session ID
2. Session ID + timestamp + HMAC signature encoded in QR code
3. Server stores session info temporarily (valid for 2 minutes)
4. Mobile app scans QR code and validates token

### Verification Process

1. Mobile app verifies HMAC signature to prevent tampering
2. Checks timestamp for validity (prevents replay attacks)
3. Prompts user for authorization
4. If approved, sends public key to server for this session
5. Server establishes encrypted communication channel

### Security Measures

- QR codes contain short-lived tokens (2-minute expiration)
- HMAC signatures prevent unauthorized token generation
- Rate limiting prevents brute force attacks
- Session keys rotated for each connection
- Device fingerprinting to detect suspicious activity

## Technology Stack

### stashpad-android

- Language: Flutter (Dart)
- Encryption: `cryptography` package (supporting AES-GCM, DH, and HKDF)
- Storage: `sqflite` with `sqlcipher` for encrypted local storage
- Networking: `http` with `web_socket_channel` support
- QR Scanner: `mobile_scanner` or `qr_code_scanner`

### stashpad-web

- Language: Flutter (Web)
- Framework: Flutter
- Encryption: `cryptography` package (Web Crypto API wrapper)
- Real-time: `web_socket_channel`
- UI: Flutter Material Design components
- Deployment: Docker (Nginx/Stateless)

### stashpad-server

- Language: Python (FastAPI or Flask-SocketIO)
- Security: CORS, rate limiting, JWT for session validation (encrypted payloads)
- WebSocket: `websockets` or `FastAPI` WebSockets
- Deployment: Docker
