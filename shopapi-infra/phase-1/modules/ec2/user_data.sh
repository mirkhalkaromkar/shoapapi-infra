#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1   # log everything to a file for debugging

echo "=== ShopAPI bootstrap started at $(date) ==="

# ── 1. System update ──────────────────────────────────────
dnf update -y

# ── 2. Install Node.js 20 (LTS) ──────────────────────────
dnf install -y nodejs npm git

node --version
npm --version

# ── 3. Clone the app from GitHub ─────────────────────────
cd /home/ec2-user
git clone https://github.com/mirkhalkaromkar/shopapi.git
cd shopapi/shopapi

# ── 4. Install dependencies ───────────────────────────────
npm install --omit=dev

# ── 5. Write .env file ────────────────────────────────────
# In Phase 2 we will replace this with SSM Parameter Store reads.
# For Phase 1, we write the env directly from Terraform template vars.
cat > .env << 'ENVEOF'
PORT=3000
DB_HOST=${db_host}
DB_PORT=3306
DB_USER=${db_username}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
REDIS_HOST=
REDIS_PORT=6379
SQS_QUEUE_URL=
AWS_REGION=ap-south-1
ENVEOF
# ── 6. Run DB schema + seed ───────────────────────────────
# Wait for RDS to be reachable (it may take a minute after Terraform apply)
echo "Waiting for RDS to be reachable..."
for i in {1..10}; do
  if mariadb105 -h "${db_host}" -u "${db_username}" -p"${db_password}" -e "SELECT 1;" 2>/dev/null; then
    echo "RDS is up."
    break
  fi
  echo "  attempt $i — waiting 15s..."
  sleep 15
done

# Install mysql client for schema init
dnf install -y mariadb105

mariadb105 -h "${db_host}" -u "${db_username}" -p"${db_password}" < /home/ec2-user/shopapi/shopapi/init.sql
echo "Schema + seed data loaded."

# ── 7. Set up systemd service (auto-restart on crash) ────
cat > /etc/systemd/system/shopapi.service << 'SVCEOF'
[Unit]
Description=ShopAPI Node.js service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/shopapi/shopapi
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
EnvironmentFile=/home/ec2-user/shopapi/shopapi/.env
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

