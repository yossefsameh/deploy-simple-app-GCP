# Three-Tier App on GCP

A minimal but production-ready three-tier web application deployed on Google Cloud Platform using Terraform, Docker, and GitHub Actions.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       GCP Project                           │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌───────────┐   │
│  │  Cloud Run   │     │  Cloud Run   │     │ Cloud SQL │   │
│  │  Frontend    │────▶│  Backend API │────▶│ PostgreSQL│   │
│  │  (nginx)     │     │  (Node.js)   │     │  (private │   │
│  └──────────────┘     └──────────────┘     │   IP)     │   │
│                             │              └───────────┘   │
│                     VPC Access Connector                    │
│                     (private egress)                        │
└─────────────────────────────────────────────────────────────┘
```

| Layer    | Technology          | Hosting         |
|----------|---------------------|-----------------|
| Frontend | Static HTML + nginx | Cloud Run       |
| Backend  | Node.js / Express   | Cloud Run       |
| Database | PostgreSQL 15       | Cloud SQL       |

## Repository Structure

```
.
├── backend/                  # Node.js Express API
│   ├── src/index.js
│   ├── tests/api.test.js
│   ├── Dockerfile            # Multi-stage, non-root user
│   └── package.json
├── frontend/                 # Static HTML + nginx
│   ├── index.html
│   ├── nginx.conf
│   └── Dockerfile
├── terraform/
│   ├── modules/
│   │   ├── networking/       # VPC, subnet, VPC connector, firewall
│   │   ├── compute/          # Cloud Run services (backend + frontend)
│   │   ├── database/         # Cloud SQL (PostgreSQL 15, private IP, SSL)
│   │   ├── iam/              # Least-privilege service account
│   │   └── monitoring/       # Alert policies, log-based metrics
│   └── environments/
│       └── prod/             # Production environment wiring
└── .github/
    └── workflows/
        └── ci-cd.yml         # GitHub Actions pipeline
```

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci-cd.yml`) runs on every push to `main` and on pull requests:

1. **Test** – runs `npm test` (Jest + Supertest) against the backend
2. **Build & Push** – builds Docker images and pushes them to Artifact Registry (main branch only)
3. **Terraform Plan** – posts a plan as a PR comment (pull requests)
4. **Terraform Apply** – deploys infrastructure changes and updates Cloud Run with the new images (main branch only)

### Secret Management

**No secrets are hard-coded in the repository.** All sensitive values are injected at runtime:

| Secret name             | Purpose                              | How supplied              |
|-------------------------|--------------------------------------|---------------------------|
| `WIF_PROVIDER`          | Workload Identity Federation provider| GitHub Actions secret     |
| `WIF_SERVICE_ACCOUNT`   | GCP SA for OIDC auth                 | GitHub Actions secret     |
| `GCP_PROJECT_ID`        | Target GCP project                   | GitHub Actions secret     |
| `DB_PASSWORD`           | Database password                    | GitHub Actions secret → TF var |
| `ALERT_EMAIL`           | Monitoring alert recipient           | GitHub Actions secret     |

Authentication uses [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation) — no long-lived service account keys are stored anywhere.

## Security Highlights

- **Least-privilege IAM**: Cloud Run uses a dedicated service account with only the roles it needs (`logging.logWriter`, `monitoring.metricWriter`, `cloudsql.client`, `secretmanager.secretAccessor`).
- **No public DB access**: Cloud SQL is configured with `ipv4_enabled = false`; the backend reaches it over private IP via a VPC connector.
- **TLS enforced on DB**: `require_ssl = true` on the Cloud SQL instance.
- **Docker non-root**: The backend container runs as a non-root user (`appuser`).
- **Minimal firewall**: Only GCP health-check probe ranges are allowed inbound; all other traffic goes through Cloud Run's managed ingress.

## Monitoring & Alerts

Three alert policies are provisioned via Terraform:

| Alert                        | Threshold          | Channel |
|------------------------------|--------------------|---------|
| Backend 5xx error rate       | > 5 % over 5 min   | Email   |
| Backend p99 latency          | > 3 s over 5 min   | Email   |
| Application ERROR log entries| > 10 in 5 min      | Email   |

All Cloud Run logs are automatically shipped to **Google Cloud Logging** (no configuration needed).

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- A GCP project with billing enabled
- A GCS bucket for Terraform remote state

### 1. Set up GCS backend

Edit `terraform/environments/prod/main.tf` and replace `REPLACE_WITH_YOUR_TF_STATE_BUCKET` with your bucket name.

### 2. Configure variables

```bash
cd terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
export TF_VAR_db_password="$(openssl rand -base64 32)"
```

### 3. Apply infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Build and push images manually (first deploy)

```bash
cd backend
docker build -t gcr.io/YOUR_PROJECT/backend:latest .
docker push gcr.io/YOUR_PROJECT/backend:latest

cd ../frontend
docker build -t gcr.io/YOUR_PROJECT/frontend:latest .
docker push gcr.io/YOUR_PROJECT/frontend:latest
```

After the first manual deploy, the GitHub Actions pipeline takes over for subsequent changes.

### 5. Set up GitHub Actions secrets

In your GitHub repository settings → Secrets and variables → Actions, create:
- `WIF_PROVIDER`
- `WIF_SERVICE_ACCOUNT`
- `GCP_PROJECT_ID`
- `DB_PASSWORD`
- `ALERT_EMAIL`

See [Using Workload Identity Federation](https://github.com/google-github-actions/auth#workload-identity-federation) for how to configure `WIF_PROVIDER` and `WIF_SERVICE_ACCOUNT`.

## Running Tests Locally

```bash
cd backend
npm ci
npm test
```