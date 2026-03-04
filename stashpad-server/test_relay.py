import asyncio
import websockets
import json
import httpx

async def test_relay():
    base_url = "http://localhost:8000"
    user_id = "test-user-123"
    session_id = "session-abc-789"

    print("--- Testing HTTP Session Pairing ---")
    async with httpx.AsyncClient() as client:
        # 1. Web client requests session
        res = await client.post(f"{base_url}/api/auth/request", json={"session_id": session_id})
        print(f"Request Session: {res.json()}")

        # 2. Mobile device verifies session
        res = await client.post(f"{base_url}/api/auth/verify?session_id={session_id}&user_id={user_id}")
        print(f"Verify Session: {res.json()}")

    print("\n--- Testing WebSocket Relay ---")
    uri = f"ws://localhost:8000/ws/{user_id}"
    
    async with websockets.connect(uri) as ws_mobile, \
               websockets.connect(uri) as ws_web:
        
        print("Both clients connected.")

        # Message from Mobile to Web
        message_from_mobile = {
            "type": "SYNC_NOTE",
            "payload": "encrypted-content-from-mobile"
        }
        await ws_mobile.send(json.dumps(message_from_mobile))
        print("Mobile sent SYNC_NOTE")

        # Web should receive it
        received_by_web = await ws_web.recv()
        print(f"Web received: {received_by_web}")

        # Message from Web to Mobile
        message_from_web = {
            "type": "UPDATE_NOTE",
            "payload": "encrypted-content-from-web"
        }
        await ws_web.send(json.dumps(message_from_web))
        print("Web sent UPDATE_NOTE")

        # Mobile should receive it
        received_by_mobile = await ws_mobile.recv()
        print(f"Mobile received: {received_by_mobile}")

if __name__ == "__main__":
    asyncio.run(test_relay())
