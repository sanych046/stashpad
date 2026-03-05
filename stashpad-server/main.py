import logging
import time
import random
import string
import json
import asyncio
from typing import Dict, Set, Optional
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("stashpad-server")

app = FastAPI(title="Stashpad Coordination Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory stores for pairing and active relays
# QR Session Store: session_id -> { "created_at": timestamp, "authorized": bool, "peer_id": optional, "pairing_code": str, "expires_at": float }
qr_sessions: Dict[str, dict] = {}
# Mapping from 6-char code to session_id
pairing_codes: Dict[str, str] = {}

def generate_pairing_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

PAIRING_CODE_DURATION = 45 # seconds

# Connection Manager for WebSockets
class ConnectionManager:
    def __init__(self):
        # user_id -> set of active WebSockets
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)
        logger.info(f"Client connected for user {user_id}. Active connections: {len(self.active_connections[user_id])}")

    def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
        logger.info(f"Client disconnected for user {user_id}")

    async def relay_to_user(self, user_id: str, message: dict, exclude: Optional[WebSocket] = None):
        if user_id in self.active_connections:
            connections = self.active_connections[user_id]
            data = json.dumps(message)
            tasks = []
            for connection in connections:
                if connection != exclude:
                    tasks.append(connection.send_text(data))
            if tasks:
                await asyncio.gather(*tasks)

manager = ConnectionManager()

class QRSessionRequest(BaseModel):
    session_id: str

@app.post("/api/auth/request")
async def request_session(request: QRSessionRequest):
    """Web client requests a new pairing session."""
    session_id = request.session_id
    code = generate_pairing_code()
    
    qr_sessions[session_id] = {
        "authorized": False,
        "peer_id": None,
        "pairing_code": code,
        "expires_at": time.time() + PAIRING_CODE_DURATION
    }
    pairing_codes[code] = session_id
    
    logger.info(f"Session request: {session_id} with code {code}")
    return {"status": "ok", "message": "Session initiated", "pairing_code": code}

@app.get("/api/auth/lookup")
async def lookup_code(code: str):
    """Mobile device looks up a session by its 6-character code."""
    code = code.upper()
    if code not in pairing_codes:
        raise HTTPException(status_code=404, detail="Invalid or expired code")
    
    session_id = pairing_codes[code]
    session = qr_sessions[session_id]
    
    if time.time() > session["expires_at"]:
        # Clean up expired entry if encountered during lookup
        del pairing_codes[code]
        raise HTTPException(status_code=404, detail="Code expired")
        
    return {"status": "ok", "session_id": session_id}

@app.post("/api/auth/verify")
async def verify_session(session_id: str, user_id: str, pairing_key: str):
    """Mobile device verifies and authorizes the session, providing the pairing key."""
    if session_id not in qr_sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    qr_sessions[session_id]["authorized"] = True
    qr_sessions[session_id]["peer_id"] = user_id
    qr_sessions[session_id]["pairing_key"] = pairing_key
    logger.info(f"Session {session_id} authorized for user {user_id}")
    return {"status": "ok", "message": "Session authorized"}

@app.get("/api/auth/status")
async def get_session_status(session_id: str):
    """Web client polls for session status and rotates code if needed."""
    if session_id not in qr_sessions:
        raise HTTPException(status_code=404, detail="Session not found")
    
    session = qr_sessions[session_id]
    
    # Check if authorized
    if session["authorized"]:
        return {
            "authorized": True,
            "user_id": session["peer_id"],
            "pairing_key": session["pairing_key"]
        }
    
    # Check if code needs rotation
    current_time = time.time()
    if current_time > session["expires_at"]:
        # Remove old code
        old_code = session["pairing_code"]
        if old_code in pairing_codes:
            del pairing_codes[old_code]
            
        # Generate new code
        new_code = generate_pairing_code()
        session["pairing_code"] = new_code
        session["expires_at"] = current_time + PAIRING_CODE_DURATION
        pairing_codes[new_code] = session_id
        logger.info(f"Rotated code for session {session_id} to {new_code}")

    return {
        "authorized": False,
        "pairing_code": session["pairing_code"],
        "expires_in": int(session["expires_at"] - current_time)
    }

@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(user_id, websocket)
    try:
        while True:
            # Wait for data from one client
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Relay encrypted payload to all other clients of the same user
            # The server does not decrypt the 'payload' field
            logger.info(f"Relaying message type '{message.get('type')}' for user {user_id}")
            await manager.relay_to_user(user_id, message, exclude=websocket)
            
    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        manager.disconnect(user_id, websocket)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
