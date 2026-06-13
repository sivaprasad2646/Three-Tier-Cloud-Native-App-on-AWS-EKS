Phase 1 — Application Code + Dockerfiles
Phase 2 — Docker Compose (local 3-tier testing)
Phase 3 — GitLab CI Pipeline (build, test, scan, push to ECR)
Phase 4 — Terraform (VPC + EKS + ECR + RDS on AWS)
Phase 5 — Kubernetes Manifests → then migrate to Helm charts
Phase 6 — ArgoCD GitOps setup
Phase 7 — Prometheus + Grafana + Alertmanager
Phase 8 — AWS Secrets Manager integration
Phase 9 — Full pipeline end-to-end test + documentation

###########################################################################################

What is a 3-Tier Architecture?

┌─────────────────────────────────────────────────────┐
│                   USER (Browser)                     │
└─────────────────────┬───────────────────────────────┘
                      │ HTTP Request
┌─────────────────────▼───────────────────────────────┐
│           TIER 1 — FRONTEND (React)                  │
│         Runs in Nginx container on port 80           │
│    "What the user sees — buttons, forms, lists"      │
└─────────────────────┬───────────────────────────────┘
                      │ API Call (fetch/axios)
┌─────────────────────▼───────────────────────────────┐
│           TIER 2 — BACKEND (Flask API)               │
│              Runs on port 5000                       │
│   "Business logic — handles requests, talks to DB"   │
└─────────────────────┬───────────────────────────────┘
                      │ SQL Query
┌─────────────────────▼───────────────────────────────┐
│           TIER 3 — DATABASE (PostgreSQL)             │
│              Runs on port 5432                       │
│         "Stores all data permanently"                │
└─────────────────────────────────────────────────────┘
Rule: Frontend never talks to Database directly. Always goes through Backend. This is the core principle of 3-tier architecture — separation of concerns.

##############################################################################################

Folder Structure

taskmanager/
├── frontend/
│   ├── src/
│   │   └── App.js
│   ├── public/
│   │   └── index.html
│   ├── package.json
│   ├── nginx.conf
│   └── Dockerfile
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── docker-compose.yml
└── README.md

Step 3 — Docker Compose (Glue Everything Together)

****** Key thing to understand — depends_on with service_healthy means backend won't start until PostgreSQL is actually accepting connections, not just "started". This fixes the classic race condition bug. ********

# Now Let's Run It

cd ~/taskmanager

docker compose up --build

# Check all containers are running
docker compose ps

# Check backend logs
docker compose logs backend

# Check DB logs
docker compose logs db

# Stop everything
docker compose down

# Stop and delete volumes (fresh DB)
docker compose down -v