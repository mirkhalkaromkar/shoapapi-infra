#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1

echo "=== ShopAPI bootstrap started at $(date) ==="

# 1. Install all packages
dnf update -y
dnf install -y nodejs npm git mariadb105 redis6

node --version
npm --version

# 2. Start Redis locally
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis6/redis6.conf
systemctl enable redis6
systemctl start redis6
/usr/bin/redis6-cli ping && echo "Redis is up"

# 3. Clone app
cd /home/ec2-user
git clone https://github.com/mirkhalkaromkar/shopapi.git
cd shopapi/shopapi

# 4. Install dependencies
npm install --omit=dev

# 5. Read secrets from SSM
echo "Reading secrets from SSM..."

DB_HOST=$(aws ssm get-parameter \
  --name "/${project_env}/db_host" \
  --query "Parameter.Value" \
  --output text --region ${aws_region})

DB_NAME=$(aws ssm get-parameter \
  --name "/${project_env}/db_name" \
  --query "Parameter.Value" \
  --output text --region ${aws_region})

DB_USER=$(aws ssm get-parameter \
  --name "/${project_env}/db_username" \
  --query "Parameter.Value" \
  --output text --region ${aws_region})

DB_PASSWORD=$(aws ssm get-parameter \
  --name "/${project_env}/db_password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text --region ${aws_region})

SQS_QUEUE_URL=$(aws ssm get-parameter \
  --name "/${project_env}/sqs_queue_url" \
  --query "Parameter.Value" \
  --output text --region ${aws_region})

echo "Secrets loaded."

# 6. Write .env — Redis is local
cat > .env << ENVEOF
PORT=3000
DB_HOST=$DB_HOST
DB_PORT=3306
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
SQS_QUEUE_URL=$SQS_QUEUE_URL
AWS_REGION=${aws_region}
ENVEOF

# 7. Wait for RDS then load schema
echo "Waiting for RDS..."
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

# 8. Install CloudWatch agent
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << CWEOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/${project_env}/shopapi",
            "log_stream_name": "bootstrap",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          }
        ]
      }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# 9. Create systemd services
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

cat > /etc/systemd/system/shopapi-worker.service << 'WORKEREOF'
[Unit]
Description=ShopAPI SQS Worker
After=network.target shopapi.service

[Service]
Type=simple
User=root
WorkingDirectory=/home/ec2-user/shopapi/shopapi
ExecStart=/usr/bin/node src/worker.js
Restart=on-failure
RestartSec=5
EnvironmentFile=/home/ec2-user/shopapi/shopapi/.env
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
WORKEREOF

systemctl daemon-reload
systemctl enable shopapi shopapi-worker
systemctl start shopapi shopapi-worker

echo "=== Bootstrap complete at $(date) ==="
