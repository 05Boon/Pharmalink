from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, Query, status
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict, Set, List
import logging

from dependencies import resolve_token, get_current_user_uuid

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("routing_engine")

class ConnectionManager:
    def __init__(self):
        # Maps pharmacy_id (Supabase User UUID string) to a set of active WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, pharmacy_id: str):
        await websocket.accept()
        if pharmacy_id not in self.active_connections:
            self.active_connections[pharmacy_id] = set()
        self.active_connections[pharmacy_id].add(websocket)
        logger.info(f"WebSocket connected for pharmacy: {pharmacy_id}. Active connections: {len(self.active_connections[pharmacy_id])}")

    def disconnect(self, websocket: WebSocket, pharmacy_id: str):
        if pharmacy_id in self.active_connections:
            self.active_connections[pharmacy_id].discard(websocket)
            if not self.active_connections[pharmacy_id]:
                del self.active_connections[pharmacy_id]
            logger.info(f"WebSocket disconnected for pharmacy: {pharmacy_id}")

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_json(message)

    async def broadcast_to_pharmacy(self, pharmacy_id: str, message: dict) -> int:
        """
        Sends a JSON message to all active WebSocket connections for a given pharmacy_id.
        Returns the number of successful transmissions.
        """
        if pharmacy_id not in self.active_connections:
            return 0
        
        sent_count = 0
        # Iterate over a list copy to prevent race conditions during concurrent set modifications
        connections = list(self.active_connections[pharmacy_id])
        for connection in connections:
            try:
                await connection.send_json(message)
                sent_count += 1
            except Exception as e:
                logger.error(f"Error sending message to pharmacy {pharmacy_id}: {e}")
                self.disconnect(connection, pharmacy_id)
        return sent_count

manager = ConnectionManager()

app = FastAPI(
    title="Pharmalink Routing Engine",
    description="Real-time geo-routing and alert broadcasting engine.",
    version="1.0"
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "healthy", "service": "Pharmalink Routing Engine"}

@app.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="JWT token or mock pharmacy UUID")
):
    pharmacy_id = resolve_token(token)
    if not pharmacy_id:
        logger.warning("Rejected WebSocket connection: Invalid token.")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return
        
    await manager.connect(websocket, pharmacy_id)
    try:
        while True:
            # Keep the connection open and listen for heartbeat/messages from the client
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        manager.disconnect(websocket, pharmacy_id)
    except Exception as e:
        logger.error(f"WebSocket error for pharmacy {pharmacy_id}: {e}")
        manager.disconnect(websocket, pharmacy_id)

@app.post("/alerts/broadcast")
async def broadcast_alert(
    target_pharmacy_ids: List[str],
    message: dict,
    current_user_id: str = Depends(get_current_user_uuid)
):
    """
    POST route allowing authorized senders to broadcast alerts to specific neighboring pharmacies.
    """
    broadcast_results = {}
    for pharmacy_id in target_pharmacy_ids:
        sent = await manager.broadcast_to_pharmacy(pharmacy_id, message)
        broadcast_results[pharmacy_id] = f"Delivered to {sent} active socket(s)"
        
    return {
        "status": "success",
        "sender": current_user_id,
        "results": broadcast_results
    }
