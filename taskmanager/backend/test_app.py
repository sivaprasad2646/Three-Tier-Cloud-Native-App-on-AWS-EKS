import pytest
import json
from unittest.mock import patch, MagicMock
from app import app

@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client

# Test 1 — health endpoint returns 200
def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "healthy"

# Test 2 — creating task without title returns 400
def test_create_task_no_title(client):
    with patch("app.get_db") as mock_db:
        res = client.post("/api/tasks",
            data=json.dumps({"title": ""}),
            content_type="application/json"
        )
        assert res.status_code == 400
        data = json.loads(res.data)
        assert "error" in data

# Test 3 — GET tasks returns a list
def test_get_tasks(client):
    mock_conn = MagicMock()
    mock_cur = MagicMock()
    mock_cur.fetchall.return_value = [
        (1, "Test task", False, "2024-01-01 00:00:00")
    ]
    mock_conn.cursor.return_value = mock_cur

    with patch("app.get_db", return_value=mock_conn):
        res = client.get("/api/tasks")
        assert res.status_code == 200
        data = json.loads(res.data)
        assert isinstance(data, list)
        assert data[0]["title"] == "Test task"