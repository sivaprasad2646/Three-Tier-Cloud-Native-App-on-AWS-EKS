from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import os
import time
##from prometheus_flask_exporter import PrometheusMetrics
##from prometheus_client import Gauge

app = Flask(__name__)
CORS(app)

##metrics = PrometheusMetrics(app)
##tasks_total = Gauge("taskmanager_tasks_total", "Total number of tasks in the database")


# -------------------------
# Database Connection
# -------------------------
def get_db():
    for i in range(10):
        try:
            return psycopg2.connect(
                host=os.environ.get("DB_HOST"),
                port=os.environ.get("DB_PORT", 5432),
                database=os.environ.get("DB_NAME"),
                user=os.environ.get("DB_USER"),
                password=os.environ.get("DB_PASSWORD"),
            )
        except Exception as e:
            print(f"Waiting for DB... ({i+1}/10): {e}", flush=True)
            time.sleep(5)

    raise Exception("Database not reachable")


# -------------------------
# Create Table
# -------------------------
def init_db():
    conn = get_db()
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS tasks (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        completed BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)

    conn.commit()
    cur.close()
    conn.close()


# -------------------------
# Health Check
# -------------------------
@app.route("/health")
def health():
    try:
        conn = get_db()
        conn.close()
        return jsonify({"status": "healthy"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500


# -------------------------
# GET Tasks
# -------------------------
@app.route("/tasks", methods=["GET"])
def get_tasks():
    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        "SELECT id, title, completed, created_at FROM tasks ORDER BY created_at DESC"
    )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    tasks = [
        {
            "id": r[0],
            "title": r[1],
            "completed": r[2],
            "created_at": str(r[3]),
        }
        for r in rows
    ]

    tasks_total.set(len(tasks))

    return jsonify(tasks)


# -------------------------
# POST Task
# -------------------------
@app.route("/tasks", methods=["POST"])
def create_task():
    data = request.get_json()

    title = data.get("title", "").strip()

    if not title:
        return jsonify({"error": "Title is required"}), 400

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        "INSERT INTO tasks(title) VALUES(%s) RETURNING id",
        (title,),
    )

    task_id = cur.fetchone()[0]

    conn.commit()

    cur.close()
    conn.close()

    return jsonify(
        {
            "id": task_id,
            "title": title,
            "completed": False,
        }
    ), 201


# -------------------------
# UPDATE Task
# -------------------------
@app.route("/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):
    data = request.get_json()

    completed = data.get("completed", False)

    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        "UPDATE tasks SET completed=%s WHERE id=%s",
        (completed, task_id),
    )

    conn.commit()

    cur.close()
    conn.close()

    return jsonify({"message": "Task updated"})


# -------------------------
# DELETE Task
# -------------------------
@app.route("/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    conn = get_db()
    cur = conn.cursor()

    cur.execute(
        "DELETE FROM tasks WHERE id=%s",
        (task_id,),
    )

    conn.commit()

    cur.close()
    conn.close()

    return jsonify({"message": "Task deleted"})


# -------------------------
# Initialize DB ONCE
# -------------------------
print("[DB INIT] Initializing database...", flush=True)
init_db()
print("[DB INIT] Database ready.", flush=True)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)