# Three-Tier Cloud-Native App on AWS EKS

> End-to-end DevOps implementation of a production-grade three-tier application — from infrastructure provisioning to CI/CD, GitOps, security, and observability — entirely on AWS EKS.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Project Phases](#project-phases)
- [Application Structure](#application-structure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Infrastructure](#infrastructure)
- [Kubernetes Setup](#kubernetes-setup)
- [GitOps with ArgoCD](#gitops-with-argocd)
- [Helm Charts](#helm-charts)
- [Observability](#observability)
- [How to Run](#how-to-run)

---

## Project Overview

This project demonstrates a complete DevOps lifecycle for a **Task Manager** application — themed as a Royal Enfield Dealer & Service Portal — deployed on AWS EKS. It covers every layer a production DevOps team owns:

| Layer | What's Built |
|---|---|
| Application | React frontend + Flask REST API + PostgreSQL |
| Containerization | Multi-stage Dockerfiles for all 3 tiers |
| CI/CD | 7-stage GitLab pipeline with security gates |
| Infrastructure | Terraform-provisioned VPC, EKS, RDS, ECR on AWS |
| Deployment | Kubernetes manifests migrated to Helm charts |
| GitOps | ArgoCD with automated sync and self-healing |
| Observability | Prometheus + Grafana + Alertmanager with real alert rules |
| Secrets | AWS Secrets Manager via External Secrets Operator |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          DEVELOPER                                   │
│                    git push → GitLab                                 │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    GITLAB CI/CD PIPELINE                             │
│                                                                      │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌────────┐  ┌──────────┐  │
│  │  Test   │→ │SonarQube │→ │ Build  │→ │ Trivy  │→ │ Push ECR │  │
│  │ pytest  │  │   SAST   │  │ Docker │  │  Scan  │  │ SHA tag  │  │
│  └─────────┘  └──────────┘  └────────┘  └────────┘  └──────────┘  │
│                                                   ↓                  │
│                                        Update image tag in Git       │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            ▼ Git change detected
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS CLOUD                                    │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                    VPC (10.0.0.0/16)                        │   │
│   │                                                              │   │
│   │   Public Subnets          Private Subnets                   │   │
│   │   ┌──────────────┐        ┌────────────────────────────┐   │   │
│   │   │ ALB          │        │    EKS Cluster              │   │   │
│   │   │ (Ingress)    │───────▶│                             │   │   │
│   │   └──────────────┘        │  ┌──────────┐ ┌─────────┐  │   │   │
│   │   ┌──────────────┐        │  │ Frontend │ │ Backend │  │   │   │
│   │   │ NAT Gateway  │        │  │  (Nginx) │ │ (Flask) │  │   │   │
│   │   └──────────────┘        │  └──────────┘ └────┬────┘  │   │   │
│   │                           │                     │        │   │   │
│   │   ┌──────────────┐        │  ┌──────────────────┘        │   │   │
│   │   │ ArgoCD       │─sync──▶│  │  RDS PostgreSQL            │   │   │
│   │   │ (GitOps)     │        │  │  (Private Subnet)          │   │   │
│   │   └──────────────┘        │  └───────────────────────┐   │   │   │
│   │                           │                            │   │   │   │
│   │   ┌──────────────┐        │  ┌─────────────────────┐  │   │   │   │
│   │   │  Prometheus  │◀──────│  │  Grafana Dashboards  │  │   │   │   │
│   │   │  Alertmanager│        │  └─────────────────────┘  │   │   │   │
│   │   └──────────────┘        └────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   ┌──────────┐   ┌─────────────────┐   ┌──────────────────────┐    │
│   │   ECR    │   │  S3 (TF State)  │   │  AWS Secrets Manager │    │
│   └──────────┘   └─────────────────┘   └──────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

**Traffic Flow:**
```
User → ALB (public subnet) → Ingress Controller
                                  ├── /api/* → Backend Service → Flask Pods → RDS
                                  └── /*     → Frontend Service → Nginx Pods
```

---

## Tech Stack

| Category | Tools |
|---|---|
| **Application** | React 18, Flask 3.0, PostgreSQL 15 |
| **Containerization** | Docker, Multi-stage builds, Nginx |
| **CI/CD** | GitLab CI/CD (7-stage pipeline) |
| **Security** | SonarQube (SAST), Trivy (image scan) |
| **Registry** | Amazon ECR |
| **Infrastructure** | Terraform, AWS (VPC, EKS, RDS, ECR, IAM, NAT Gateway) |
| **Orchestration** | Kubernetes (EKS 1.29), Helm 3 |
| **GitOps** | ArgoCD |
| **Observability** | Prometheus, Grafana, Alertmanager |
| **Secrets** | AWS Secrets Manager, External Secrets Operator |
| **State Management** | S3 remote state, DynamoDB state locking |

---

## Project Phases

```
Phase 1 ✅ — Application Code + Multi-stage Dockerfiles
Phase 2 ✅ — GitLab CI/CD Pipeline (7 stages)
Phase 3 ✅ — Terraform AWS Infrastructure
Phase 4 ✅ — Kubernetes Manifests (Deployments, Services, HPA, Ingress)
Phase 5 ✅ — ArgoCD GitOps Setup
Phase 6 ✅ — Prometheus + Grafana + Alertmanager
Phase 7 ✅ — Helm Chart Migration (multi-environment)
Phase 8 🔄 — AWS Secrets Manager + External Secrets Operator
```

---

## Application Structure

```
├── frontend/                  # React app served via Nginx
│   ├── src/App.js             # Task Manager UI (CRUD)
│   ├── nginx.conf             # Reverse proxy config
│   └── Dockerfile             # Multi-stage build (Node → Nginx)
├── backend/                   # Flask REST API
│   ├── app.py                 # API routes + Prometheus metrics
│   ├── test_app.py            # Unit tests (pytest)
│   ├── requirements.txt
│   └── Dockerfile             # Python slim image
├── infrastructure/            # Terraform modules
│   ├── main.tf                # Provider + S3 backend
│   ├── vpc.tf                 # VPC, subnets, IGW, NAT
│   ├── eks.tf                 # EKS cluster + node group
│   ├── rds.tf                 # PostgreSQL RDS
│   ├── ecr.tf                 # Container registries
│   ├── iam.tf                 # Roles and policies
│   └── outputs.tf
├── k8s/                       # Raw Kubernetes manifests (reference)
│   ├── backend/               # Deployment, Service, HPA
│   ├── frontend/              # Deployment, Service
│   ├── database/              # ConfigMap, Secret
│   └── ingress.yaml
├── helm/                      # Helm chart (active deployments)
│   └── taskmanager/
│       ├── Chart.yaml
│       ├── values.yaml        # Production defaults
│       ├── values-dev.yaml    # Dev overrides
│       └── templates/
├── argocd/
│   └── application.yaml      # ArgoCD Application manifest
├── .gitlab-ci.yml            # Full 7-stage pipeline
└── docker-compose.yml        # Local development
```

---

## CI/CD Pipeline

7-stage GitLab CI/CD pipeline — every stage is a security or quality gate:

```
┌──────────┬──────────────┬───────────┬──────────┬──────────┬──────────┬────────────┐
│  Stage 1 │   Stage 2    │  Stage 3  │ Stage 4  │ Stage 5  │ Stage 6  │  Stage 7   │
│   test   │     sast     │   build   │   scan   │   push   │  update  │   deploy   │
│          │              │           │          │          │          │            │
│  pytest  │  SonarQube   │  Docker   │  Trivy   │   ECR    │ Git tag  │    Helm    │
│  3 tests │  code scan   │  build ×2 │  image   │  push ×2 │  update  │  upgrade   │
└──────────┴──────────────┴───────────┴──────────┴──────────┴──────────┴────────────┘
     ↓            ↓             ↓           ↓          ↓          ↓           ↓
   Fails?      Fails?        Fails?      CRITICAL    Pushes    ArgoCD      --atomic
   Stop.       Stop.         Stop.       CVE found?  SHA tag   detects     rollback
                                         Stop.       to ECR    Git change  on fail
```

**Key pipeline decisions:**
- Images tagged with `$CI_COMMIT_SHA` — every build traceable to exact commit
- Trivy with `--exit-code 1` — CRITICAL CVEs **block** the pipeline, not just warn
- `[skip ci]` on tag-update commits — prevents infinite pipeline loop
- `helm upgrade --atomic` — auto-rollback if new pods don't become healthy

---

## Infrastructure

All AWS infrastructure provisioned with Terraform. Remote state in S3 with DynamoDB locking.

```
VPC: 10.0.0.0/16
├── Public Subnets  (10.0.1.0/24, 10.0.2.0/24)  — ALB, NAT Gateway
└── Private Subnets (10.0.3.0/24, 10.0.4.0/24)  — EKS nodes, RDS

EKS Cluster: taskmanager-cluster (v1.29)
└── Node Group: 2x t3.medium (min:1, max:4, auto-scaling)

RDS: PostgreSQL 15 (db.t3.micro, encrypted, private subnet only)
ECR: taskmanager-backend, taskmanager-frontend (scan on push enabled)
```

```bash
# Provision everything
cd infrastructure/
terraform init
terraform plan -var="db_username=postgres" -var="db_password=<pass>"
terraform apply  # ~15 mins — EKS takes longest

# Connect kubectl
aws eks update-kubeconfig --region ap-south-1 --name taskmanager-cluster
```

**Why private subnets for EKS nodes?**
Worker nodes have no public IP. Outbound traffic routes through NAT Gateway → Internet Gateway. Inbound traffic only comes through the ALB. Nodes are never directly reachable from the internet.

---

## Kubernetes Setup

```bash
# Apply manifests (order matters)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/database/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/frontend/
kubectl apply -f k8s/ingress.yaml

# Verify
kubectl get pods -n taskmanager
kubectl get ingress -n taskmanager
```

**Key K8s decisions:**

| Decision | Reason |
|---|---|
| `maxUnavailable: 0` in rolling update | Zero downtime — new pod ready before old one killed |
| Liveness + Readiness probes on `/health` | Liveness restarts crashed pods; Readiness removes unhealthy pods from LB |
| HPA at 70% CPU | Auto-scales backend 2→6 replicas under load |
| ClusterIP for all services | Services not exposed directly; ALB Ingress is single entry point |
| Resource requests + limits on every pod | Prevents one pod starving the node |

---

## GitOps with ArgoCD

ArgoCD runs inside the cluster and watches the GitLab repo. **Git is the single source of truth.**

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy application
kubectl apply -f argocd/application.yaml

# Check sync status
argocd app get taskmanager
# Sync Status:   Synced  ✅
# Health Status: Healthy ✅
```

**Self-healing demo:**
```bash
# Simulate unauthorized manual change
kubectl scale deployment backend -n taskmanager --replicas=5

# Wait 3 minutes — ArgoCD auto-reverts to 2 (what Git says)
kubectl get pods -n taskmanager
# Back to 2 pods — Git always wins
```

**Push vs Pull deployment:**

| Push (old way) | Pull — ArgoCD |
|---|---|
| CI pipeline runs kubectl | ArgoCD polls Git every 3 mins |
| CI needs cluster credentials | No credentials leave the cluster |
| Manual drift undetected | Drift detected + auto-corrected |
| Rollback = re-run pipeline | Rollback = `git revert` |

---

## Helm Charts

Raw YAML migrated to Helm for multi-environment support.

```bash
# Validate chart
helm lint helm/taskmanager/
helm template taskmanager ./helm/taskmanager --values helm/taskmanager/values.yaml

# Deploy production
helm install taskmanager ./helm/taskmanager \
  --namespace taskmanager \
  --values helm/taskmanager/values.yaml

# Deploy dev environment (same chart, different values)
helm install taskmanager-dev ./helm/taskmanager \
  --namespace taskmanager-dev \
  --values helm/taskmanager/values.yaml \
  --values helm/taskmanager/values-dev.yaml

# Upgrade with new image tag (what CI/CD runs)
helm upgrade taskmanager ./helm/taskmanager \
  --set backend.image.tag=a3f8c21 \
  --set frontend.image.tag=a3f8c21 \
  --atomic \
  --timeout 5m

# Rollback to previous release
helm rollback taskmanager 1
```

**Environment differences managed by Helm:**

| Setting | Production | Dev |
|---|---|---|
| Backend replicas | 2 | 1 |
| HPA | Enabled (2→6) | Disabled |
| Memory limit | 256Mi | 128Mi |
| DB host | prod-rds endpoint | dev-rds endpoint |

---

## Observability

### Grafana Dashboard

![Grafana Dashboard](./screenshots/grafana-dashboard.png)

*Live dashboard showing: Cluster Nodes Ready (2), Running Pods (18), Memory Usage (60.3%), CPU Usage (4.61%), Pod Restarts (0), Node Disk Usage (21.5% / 27.4%), and real-time Request Rate across all backend pods.*

**6 dashboards built:**

| Dashboard | Key Panels |
|---|---|
| Cluster Health | Nodes ready, running pods, node disk usage |
| Pod Restarts | Restart count per pod — crash-loop detection |
| Request Latency | p50 / p95 / p99 response time per endpoint |
| Error Rate | % of 5xx responses over time |
| Resource Usage | Memory/CPU per pod vs configured limits |
| Business Metrics | Total tasks in DB (custom Gauge metric) |

### Prometheus Alert Rules

4 real alert rules configured — not just dashboards:

```yaml
TaskManagerPodDown   # fires if any pod not ready for 2+ minutes → CRITICAL
HighErrorRate        # fires if 5xx rate > 5% over 5 mins → CRITICAL
HighMemoryUsage      # fires if pod uses > 85% memory limit → WARNING
SlowAPIResponse      # fires if p95 latency > 1 second → WARNING
```

### Alertmanager Routing

```
CRITICAL alerts → Slack #devops-alerts (repeat every 1 hour until resolved)
WARNING alerts  → Slack #devops-alerts (repeat every 4 hours)
RESOLVED        → automatic resolution notification sent
```

**Incident detection time: ~2 minutes** (pod down → Prometheus detects → Alertmanager fires → Slack notification received)

### Custom Application Metric

```python
# Added to Flask backend — tracks business metric, not just infra
tasks_total = Gauge("taskmanager_tasks_total",
                    "Total number of tasks in the database")
```

Visible in Prometheus: `http://backend:5000/metrics`

---

## How to Run

### Local Development (Docker Compose)

```bash
git clone https://github.com/sivaprasad2646/Three-Tier-Cloud-Native-App-on-AWS-EKS.git
cd Three-Tier-Cloud-Native-App-on-AWS-EKS

docker compose up --build

# Open http://localhost — Task Manager running locally
# Frontend → Nginx → Flask → PostgreSQL (all in containers)
```

### Full AWS Deployment

**Prerequisites:**
- AWS CLI configured (`aws configure`)
- Terraform >= 1.6.0
- kubectl
- Helm 3
- ArgoCD CLI

```bash
# 1. Create S3 state bucket + DynamoDB lock table (one time)
aws s3api create-bucket --bucket taskmanager-tfstate-YOUR_ACCOUNT_ID \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws dynamodb create-table --table-name taskmanager-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region ap-south-1

# 2. Provision AWS infrastructure
cd infrastructure/
terraform init
terraform apply -var="db_username=postgres" -var="db_password=YourPass123"

# 3. Connect kubectl to EKS
aws eks update-kubeconfig --region ap-south-1 --name taskmanager-cluster

# 4. Deploy with Helm
helm install taskmanager ./helm/taskmanager \
  --namespace taskmanager \
  --values helm/taskmanager/values.yaml \
  --create-namespace

# 5. Install ArgoCD + connect repo
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml

# 6. Install observability stack
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm install prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

# 7. Verify everything
kubectl get pods -n taskmanager
kubectl get pods -n monitoring
argocd app get taskmanager
```

---

## Repository

**GitHub:** [https://github.com/sivaprasad2646/Three-Tier-Cloud-Native-App-on-AWS-EKS](https://github.com/sivaprasad2646/Three-Tier-Cloud-Native-App-on-AWS-EKS)

---

*Built by Mavaturu Shivacharam Siva Prasad Reddy — DevOps Engineer, Bangalore*
*[LinkedIn](https://linkedin.com/in/m-s-siva-prasad-reddy) · [GitHub](https://github.com/sivaprasad2646)*
