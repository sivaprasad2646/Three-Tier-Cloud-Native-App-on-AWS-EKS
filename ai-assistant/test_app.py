import pytest
import json
from unittest.mock import patch, MagicMock
from app import app

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

# Test 1 — health endpoint
def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "healthy"
    assert data["service"] == "ai-assistant"

# Test 2 — missing query field returns 400
def test_missing_query(client):
    res = client.post("/api/ai-assistant",
        data=json.dumps({}),
        content_type="application/json"
    )
    assert res.status_code == 400
    data = json.loads(res.data)
    assert "error" in data

# Test 3 — empty query returns 400
def test_empty_query(client):
    res = client.post("/api/ai-assistant",
        data=json.dumps({"query": "   "}),
        content_type="application/json"
    )
    assert res.status_code == 400

# Test 4 — query too long returns 400
def test_query_too_long(client):
    res = client.post("/api/ai-assistant",
        data=json.dumps({"query": "x" * 501}),
        content_type="application/json"
    )
    assert res.status_code == 400

# Test 5 — successful Bedrock call (mocked)
def test_successful_query(client):
    mock_response = {
        "content": [{"text": "CrashLoopBackOff means your container keeps crashing."}]
    }

    # Mock the entire bedrock call
    with patch("app.call_bedrock", return_value="CrashLoopBackOff means your container keeps crashing."):
        res = client.post("/api/ai-assistant",
            data=json.dumps({"query": "What is CrashLoopBackOff?"}),
            content_type="application/json"
        )
        assert res.status_code == 200
        data = json.loads(res.data)
        assert "answer" in data
        assert "latency_seconds" in data
        assert data["query"] == "What is CrashLoopBackOff?"