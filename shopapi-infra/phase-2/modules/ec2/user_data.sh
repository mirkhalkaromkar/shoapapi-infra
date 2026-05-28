#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1

echo "=== ShopAPI bootstrap started at $(date) ==="

# ── 1. System update + install packages ───────────────────
dnf update -y
dnf install -y nodejs npm git mariadb105

node --version
npm --version

# ── 2. Clone app ──────────────────────────────────────────
cd /home/ec2-user
git clone https://github.com/mirkhalkaromkar/shopapi.git
cd shopapi/shopapi

# ── 3. Install dependencies ───────────────────────────────
npm install --omit=dev

# ── 4. Read secrets from SSM Parameter Store ─────────────
# Phase 2: no more hardcoded credentials in user_data
echo "Reading secrets from SSM..."

DB_HOST=$(aws ssm get-parameter \
  --name "/${project_env}/db_host" \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

DB_NAME=$(aws ssm get-parameter \
  --name "/${project_env}/db_name" \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

DB_USER=$(aws ssm get-parameter \
  --name "/${project_env}/db_username" \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

DB_PASSWORD=$(aws ssm get-parameter \
  --name "/${project_env}/db_password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

echo "Secrets loaded from SSM."

# ── 5. Write .env ─────────────────────────────────────────
cat > .env << ENVEOF
PORT=3000
DB_HOST=$DB_HOST
DB_PORT=3306
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
REDIS_HOST=
REDIS_PORT=6379
SQS_QUEUE_URL=
AWS_REGION=${aws_region}
ENVEOF

# ── 6. Wait for RDS then load schema ─────────────────────
echo "Waiting for RDS to be reachable..."
for i in {1..10}; do
  if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" 2>/dev/null; then
    echo "RDS is up."
    break
  fi
  echo "  attempt $i — waiting 15s..."
  sleep 15
done

mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" < /home/ec2-user/shopapi/shopapi/init.sql || true
echo "Schema loaded."

# ── 7. Systemd service ────────────────────────────────────
cat > /etc/systemd/system/shopapi.service << 'SVCEOF'
[Unit]
Description=ShopAPI Node.js service
After=network.target

[Service]
Type=simple
User=root
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

systemctl daemon-reload
systemctl enable shopapi
systemctl start shopapi

echo "=== Bootstrap complete at $(date) ==="
