# Step 2 — Frontend (React)

mkdir -p ~/taskmanager/frontend/src
mkdir -p ~/taskmanager/frontend/public

File 1 — public/index.html
File 2 — src/App.js
File 3 — package.json
File 4 — nginx.conf

############## Why nginx.conf matters — Nginx serves your React build files AND proxies /api/ calls to Flask. This means your frontend container handles both static files and API routing. Interviewers love this answer.

File 5 — Dockerfile (Frontend)

This is a multi-stage build — Stage 1 builds React (large, has node_modules). Stage 2 copies only the final build output into Nginx. Final image size: ~25MB instead of ~400MB. This is a must-know concept for interviews.

# Step 3 — Docker Compose (Glue Everything Together) ---- MAin README.md