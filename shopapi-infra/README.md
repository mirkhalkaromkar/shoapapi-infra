# shopapi-aws-infra

Terraform infrastructure for ShopAPI — AWS Free Tier, deployed in phases.

## Phase structure

```
phase-1/   VPC + EC2 + RDS + IAM + Security Groups
phase-2/   S3 + CloudFront + ALB + SSM (coming)
phase-3/   SQS + Redis on EC2 (coming)
phase-4/   CloudWatch + Alarms (coming)
phase-5/   CodePipeline + CodeBuild + CodeDeploy (coming)
phase-6/   Multi-AZ + Auto Scaling Group (coming)
```

## Phase 1 — Quick start

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.6 installed
- AWS Free Tier account

### Steps

```bash
cd phase-1

# 1. Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_password

# 2. Initialise Terraform
terraform init

# 3. Preview what will be created
terraform plan

# 4. Apply (takes ~10 min — RDS takes the longest)
terraform apply

# 5. Get your app URL from output
terraform output app_url
```

### What gets created

| Resource           | Type            | Free tier? |
|--------------------|-----------------|------------|
| VPC                | custom          | ✅ free    |
| Public subnets x2  | ap-south-1a/1b  | ✅ free    |
| Private subnets x2 | ap-south-1a/1b  | ✅ free    |
| Internet Gateway   | —               | ✅ free    |
| Route tables       | public + private| ✅ free    |
| App Security Group | EC2             | ✅ free    |
| DB Security Group  | RDS             | ✅ free    |
| IAM Role + Profile | EC2             | ✅ free    |
| EC2 t2.micro       | Amazon Linux 23 | ✅ 750 hrs |
| RDS db.t2.micro    | MySQL 8.0       | ✅ 750 hrs |

### Test the API

```bash
# Get the IP
terraform output app_url

# Health check
curl http://<EC2_IP>:3000/health

# List products (from DB — first request)
curl http://<EC2_IP>:3000/products

# List products again (from Redis cache — Phase 3 adds this)
curl http://<EC2_IP>:3000/products

# Create a product
curl -X POST http://<EC2_IP>:3000/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","price":499,"category_id":1,"stock":10}'
```

### Teardown (important — stop the free tier clock)

```bash
terraform destroy
```
