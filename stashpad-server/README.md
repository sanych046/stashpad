# Stashpad Server

Coordination server that facilitates communication between mobile and web clients without accessing user data.

## Features
- Authentication coordination
- Data relay between clients
- Session management
- Access control verification

## Architecture
- Minimal server that acts as a "dumb pipe"
- No access to decrypted user data
- WebSocket connections for real-time communication
- Temporary session management
- End-to-end encryption maintained throughout