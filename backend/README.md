#Step 1 — Backend (Flask API)
We start from the database-side and work upward. Backend first because frontend depends on it.

Create your folder:

mkdir -p ~/taskmanager/backend
cd ~/taskmanager/backend

File 1 — app.py (The entire backend logic)

Why os.environ.get()? — Notice we never hardcode passwords. We read from environment variables. This is the foundation for AWS Secrets Manager in Phase 8.

# File 2 — requirements.txt

Why gunicorn? — Flask's built-in server is for development only. Gunicorn is a production-grade WSGI server. We use it in the Dockerfile.

# File 3 — Dockerfile (Backend)