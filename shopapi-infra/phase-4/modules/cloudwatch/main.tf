# ── Log Groups ────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project}/${var.env}/shopapi"
  retention_in_days = 7
  tags = { Project = var.project, Env = var.env }
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/${var.project}/${var.env}/shopapi-worker"
  retention_in_days = 7
  tags = { Project = var.project, Env = var.env }
}

# ── SNS Topic for alerts ──────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.env}-alerts"
  tags = { Project = var.project, Env = var.env }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── EC2 CPU Alarm ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project}-${var.env}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU > 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.ec2_instance_id
  }
}

# ── RDS Connections Alarm ─────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project}-${var.env}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "RDS connections > 20"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
}

# ── SQS Queue Depth Alarm ─────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "sqs_depth" {
  alarm_name          = "${var.project}-${var.env}-sqs-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 100
  alarm_description   = "SQS queue depth > 100 — worker may be falling behind"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    QueueName = var.sqs_queue_name
  }
}

# ── ALB 5xx Alarm ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.env}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5xx errors > 10 in 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# ── CloudWatch Dashboard ──────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.env}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type       = "metric"
        x = 0; y = 0; width = 12; height = 6
        properties = {
          title   = "EC2 CPU Utilization"
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", var.ec2_instance_id]]
          period  = 60
          stat    = "Average"
          region  = var.aws_region
        }
      },
      {
        type       = "metric"
        x = 12; y = 0; width = 12; height = 6
        properties = {
          title   = "RDS Connections"
          metrics = [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_identifier]]
          period  = 60
          stat    = "Average"
          region  = var.aws_region
        }
      },
      {
        type       = "metric"
        x = 0; y = 6; width = 12; height = 6
        properties = {
          title   = "SQS Queue Depth"
          metrics = [["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.sqs_queue_name]]
          period  = 60
          stat    = "Maximum"
          region  = var.aws_region
        }
      },
      {
        type       = "metric"
        x = 12; y = 6; width = 12; height = 6
        properties = {
          title   = "ALB 5xx Errors"
          metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]]
          period  = 60
          stat    = "Sum"
          region  = var.aws_region
        }
      }
    ]
  })
}
