import pytest
from fastapi.testclient import TestClient
from main import app, manager

client = TestClient(app)

def test_websocket_connect_and_ping():
    # 1. Test connection with a valid mock token prefix
    with client.websocket_connect("/ws?token=mock-pharmacy-1") as websocket:
        # Check that the connection manager correctly registers the active websocket
        assert "mock-pharmacy-1" in manager.active_connections
        assert len(manager.active_connections["mock-pharmacy-1"]) == 1
        
        # 2. Test ping-pong communication
        websocket.send_text("ping")
        response = websocket.receive_text()
        assert response == "pong"

    # 3. Verify connection cleanup upon client exit
    assert "mock-pharmacy-1" not in manager.active_connections

def test_websocket_invalid_token():
    # Test connection rejection for invalid token format (fails to resolve sub claim)
    with pytest.raises(Exception):
        with client.websocket_connect("/ws?token=invalid_token"):
            pass

def test_websocket_broadcast_alert():
    target_id = "mock-pharmacy-2"
    test_msg = {"alert_id": "test-alert-123", "drug": "Panadol", "quantity": 100}
    
    # 1. Establish the target pharmacy's active WebSocket connection
    with client.websocket_connect(f"/ws?token={target_id}") as websocket:
        assert target_id in manager.active_connections
        
        # 2. Trigger a targeted alert broadcast via the POST endpoint using mock Auth headers
        headers = {"Authorization": "Bearer mock-sender-9999"}
        payload = {
            "target_pharmacy_ids": [target_id],
            "message": test_msg
        }
        
        response = client.post("/alerts/broadcast", json=payload, headers=headers)
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "success"
        assert data["sender"] == "mock-sender-9999"
        
        # 3. Verify the WebSocket client received the broadcast payload
        received_msg = websocket.receive_json()
        assert received_msg == test_msg
        
    # 4. Verify connection manager memory cleanup on exit
    assert target_id not in manager.active_connections
