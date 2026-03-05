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
        # user_id -> {session_id: set of WebSockets}
        self.active_sessions: Dict[str, Dict[str, Set[WebSocket]]] = {}

    async def connect(self, user_id: str, session_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_sessions:
            self.active_sessions[user_id] = {}
        if session_id not in self.active_sessions[user_id]:
            self.active_sessions[user_id][session_id] = set()
        self.active_sessions[user_id][session_id].add(websocket)
        
        # Update session metadata if it exists
        if session_id in qr_sessions:
            qr_sessions[session_id]["last_activity"] = time.time()
            
        logger.info(f"Client connected for user {user_id}, session {session_id}. Active sessions: {len(self.active_sessions[user_id])}")

    def disconnect(self, user_id: str, session_id: str, websocket: WebSocket):
        if user_id in self.active_sessions and session_id in self.active_sessions[user_id]:
            self.active_sessions[user_id][session_id].discard(websocket)
            if not self.active_sessions[user_id][session_id]:
                del self.active_sessions[user_id][session_id]
            if not self.active_sessions[user_id]:
                del self.active_sessions[user_id]
        logger.info(f"Client disconnected for user {user_id}, session {session_id}")

    async def relay_to_user(self, user_id: str, message: dict, exclude: Optional[WebSocket] = None):
        if user_id in self.active_sessions:
            data = json.dumps(message)
            tasks = []
            for session_id, connections in self.active_sessions[user_id].items():
                for connection in connections:
                    if connection != exclude:
                        tasks.append(connection.send_text(data))
            if tasks:
                await asyncio.gather(*tasks)

    async def disconnect_session(self, user_id: str, session_id: str):
        if user_id in self.active_sessions and session_id in self.active_sessions[user_id]:
            connections = list(self.active_sessions[user_id][session_id])
            data = json.dumps({"type": "SESSION_REVOKED"})
            for connection in connections:
                try:
                    await connection.send_text(data)
                    await connection.close()
                except:
                    pass
            del self.active_sessions[user_id][session_id]
            if not self.active_sessions[user_id]:
                del self.active_sessions[user_id]

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
        "expires_at": time.time() + PAIRING_CODE_DURATION,
        "created_at": time.time(),
        "last_activity": time.time(),
        "user_agent": "" # Will be populated on connect
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

@app.get("/api/sessions")
async def get_user_sessions(user_id: str):
    """Get active sessions for a user."""
    sessions = []
    for sid, session in qr_sessions.items():
        if session.get("authorized") and session.get("peer_id") == user_id:
            sessions.append({
                "session_id": sid,
                "user_agent": session.get("user_agent", "Unknown Device"),
                "last_activity": session.get("last_activity", session.get("created_at")),
                "is_online": user_id in manager.active_sessions and sid in manager.active_sessions[user_id]
            })
    return {"sessions": sessions}

@app.post("/api/sessions/revoke")
async def revoke_session(session_id: str, user_id: str):
    """Revoke a session."""
    if session_id in qr_sessions:
        session = qr_sessions[session_id]
        if session.get("peer_id") == user_id:
            logger.info(f"Revoking session {session_id} for user {user_id}")
            # Disconnect active WS
            await manager.disconnect_session(user_id, session_id)
            # Remove from sessions
            del qr_sessions[session_id]
            return {"status": "ok"}
    raise HTTPException(status_code=404, detail="Session not found")

@app.websocket("/ws/{user_id}/{session_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str, session_id: str):
    # Try to grab user agent for identification
    ua = websocket.headers.get("user-agent", "Unknown Browser")
    if session_id in qr_sessions:
        qr_sessions[session_id]["user_agent"] = ua

    await manager.connect(user_id, session_id, websocket)
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Update last activity
            if session_id in qr_sessions:
                qr_sessions[session_id]["last_activity"] = time.time()

            logger.info(f"Relaying message type '{message.get('type')}' for user {user_id}")
            await manager.relay_to_user(user_id, message, exclude=websocket)
            
    except WebSocketDisconnect:
        manager.disconnect(user_id, session_id, websocket)
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        manager.disconnect(user_id, session_id, websocket)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
