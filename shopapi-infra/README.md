# ShopAPI

An e-commerce product catalog API built with Node.js + Express, deployed on AWS using a production-grade multi-AZ architecture. This project replicates a GCP enterprise architecture (Protect.AI reference design) on AWS Free Tier using Terraform, deployed in 6 progressive phases.

**Live:** `https://<your-cloudfront-domain>` — React frontend  
**API:** `http://<your-alb-dns>` — REST API via ALB

---

## Architecture

```
User (Browser)
  ↓
CloudFront (HTTPS)
  ├── /              → S3 (React frontend)
  ├── /products*     → ALB → EC2 (Node.js API)
  ├── /categories*   → ALB → EC2 (Node.js API)
  └── /images/*      → S3 (product images)
                ↓
         Auto Scaling Group
         (1–2 × EC2 t3.micro, ap-south-1a + 1b)
           ├── Node.js API (port 3000)
           ├── Redis 6 (cache-aside, localhost)
           └── SQS Worker (async events)
                ↓
         RDS MySQL 8.0 db.t3.micro
         (Multi-AZ: primary 1a, standby 1b)
                ↓
  ┌─────────────────────────────────┐
  │  SSM Parameter Store (secrets)  │
  │  SQS Queue + DLQ (events)       │
  │  CloudWatch (logs + alarms)     │
  │  GitHub Actions OIDC (CI/CD)    │
  └─────────────────────────────────┘
```

---

## Quick Start — Deploy from Phase 6

Phase 6 is the complete, self-contained deployment. You do not need to run previous phases.

### Prerequisites

- AWS account (Free Tier)
- AWS CLI configured (`aws configure`)
- Terraform >= 1.6
- Git

### Step 1 — Clone infra repo

```bash
git clone https://github.com/mirkhalkaromkar/shoapapi-infra.git
cd shoapapi-infra/shopapi-infra/phase-6
```

### Step 2 — Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region  = "ap-south-1"
project     = "shopapi"
env         = "dev"
db_password = "YourStrongPasswordHere!"   # min 8 chars
alert_email = "your-email@example.com"    # for CloudWatch alarm emails
github_org  = "mirkhalkaromkar"           # your GitHub username
github_repo = "shopapi"
```

### Step 3 — Deploy infrastructure

```bash
terraform init
terraform apply -auto-approve
```

Takes ~15 minutes (RDS provisioning is the slowest step).

### Step 4 — Collect outputs

```bash
terraform output github_actions_role_arn   # → AWS_DEPLOY_ROLE_ARN
terraform output frontend_bucket           # → FRONTEND_BUCKET
terraform output cloudfront_id             # → CLOUDFRONT_ID
terraform output app_url                   # → ALB_URL
terraform output -raw rds_endpoint         # RDS endpoint (for reference)
```

### Step 5 — Add GitHub secrets and variable

In the **shopapi** GitHub repository → Settings → Secrets and variables → Actions:

**Repository Secrets** (Settings → Secrets → Actions → New repository secret):

| Secret name | Value |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | From `terraform output github_actions_role_arn` |
| `FRONTEND_BUCKET` | From `terraform output frontend_bucket` |
| `CLOUDFRONT_ID` | From `terraform output cloudfront_id` |

**Repository Variable** (Settings → Secrets → Actions → Variables tab → New variable):

| Variable name | Value |
|---|---|
| `CLOUDFRONT_URL` | CloudFront domain, e.g. `https://d1xxxxx.cloudfront.net` |

> Note: Set `CLOUDFRONT_URL` as a **variable** (not a secret) and set it to the CloudFront URL, not the ALB URL directly. This avoids mixed content errors since CloudFront proxies API calls over HTTPS.

### Step 6 — Trigger first deployment

Push any change to the `shopapi` repository `main` branch:

```bash
git commit --allow-empty -m "trigger deploy"
git push origin main
```

Watch the pipeline in GitHub → Actions tab. Two jobs run:
1. **Deploy Backend** — SSM into EC2, git pull, npm install, restart services
2. **Deploy Frontend** — npm build, S3 sync, CloudFront invalidation

### Step 7 — Access the application

Open the CloudFront URL from Step 4 in your browser. The React product catalog should load showing 8 products across 4 categories.

---

## API Reference

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/products` | List all products (Redis cache-aside) |
| GET | `/products/:id` | Get product by ID |
| POST | `/products` | Create product + SQS event |
| PUT | `/products/:id` | Update product + invalidate cache |
| DELETE | `/products/:id` | Delete product + invalidate cache |
| GET | `/categories` | List categories |
| GET | `/categories/:id/products` | Products by category |

The `source` field in responses tells you whether data came from `db` or `cache`.

---

## Environment variables

All secrets are stored in AWS SSM Parameter Store and read at EC2 boot time. No `.env` file is committed to the repository.

| SSM Parameter | Description |
|---|---|
| `/shopapi/dev/db_host` | RDS endpoint |
| `/shopapi/dev/db_name` | Database name |
| `/shopapi/dev/db_username` | DB username |
| `/shopapi/dev/db_password` | DB password (SecureString) |
| `/shopapi/dev/redis_host` | Redis host (127.0.0.1) |
| `/shopapi/dev/sqs_queue_url` | SQS queue URL |

For local development, copy `.env.example` to `.env` and fill in values, then run:

```bash
docker compose up --build
```

---

## Infrastructure phases

| Phase | What it adds |
|---|---|
| 1 | VPC + EC2 + RDS + IAM + Security Groups |
| 2 | ALB + S3 + CloudFront + SSM Parameter Store |
| 3 | SQS Queue + DLQ + Redis on EC2 |
| 4 | CloudWatch Logs + Alarms + Dashboard + SNS alerts |
| 5 | GitHub Actions OIDC CI/CD |
| 6 | RDS Multi-AZ + Auto Scaling Group + React Frontend |

Each phase is a complete standalone Terraform deployment in `shopapi-infra/phase-N/`.

---

## Teardown

To avoid AWS charges when not in use:

```bash
cd shoapapi-infra/shopapi-infra/phase-6
terraform destroy -auto-approve
```

Rebuild anytime with `terraform apply -auto-approve` — takes ~15 minutes.

---

## Disaster Recovery

This architecture simulates active-passive DR:

**RDS failover:**
```bash
aws rds reboot-db-instance \
  --db-instance-identifier shopapi-dev-mysql \
  --force-failover \
  --region ap-south-1
```
RDS fails over to standby in the second AZ in ~60 seconds. Endpoint DNS stays the same.

**Instance failure:**
The Auto Scaling Group automatically replaces any terminated instance within ~3 minutes. No manual action required.

---

## Monitoring

CloudWatch dashboard: `shopapi-dev`

**Alarms configured:**
- EC2 CPU > 80%
- RDS Connections > 20
- SQS Queue Depth > 100
- ALB 5xx errors > 10/min

Email alerts via SNS to the configured `alert_email`.

---
Note: There are two directories phase-5(phase-5-v2 and pahse-5) so phase-5 directory include pipeline setup through AWS  using services like CodeDeploy, CodeBuild and CodePipeline and phase-5-v2 directory is pipeline setup directly through github actions. We can choose as per our requirements. 

## Tech stack

**Application:** Node.js 18, Express, mysql2, ioredis, @aws-sdk/client-sqs  
**Frontend:** React 18, no external UI libraries  
**Infrastructure:** Terraform >= 1.6, AWS Provider ~5.0  
**CI/CD:** GitHub Actions with AWS OIDC (no stored credentials)  
**Region:** ap-south-1 (Mumbai)
