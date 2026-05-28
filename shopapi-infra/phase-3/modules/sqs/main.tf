# ── SQS Queue ─────────────────────────────────────────────
resource "aws_sqs_queue" "product_events" {
  name                       = "${var.project}-${var.env}-product-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400   # 1 day
  receive_wait_time_seconds  = 5       # long polling

  tags = { Project = var.project, Env = var.env }
}

# ── Dead Letter Queue ─────────────────────────────────────
# Messages that fail 3 times go here for inspection
resource "aws_sqs_queue" "product_events_dlq" {
  name                      = "${var.project}-${var.env}-product-events-dlq"
  message_retention_seconds = 604800   # 7 days

  tags = { Project = var.project, Env = var.env }
}

resource "aws_sqs_queue_redrive_policy" "product_events" {
  queue_url = aws_sqs_queue.product_events.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.product_events_dlq.arn
    maxReceiveCount     = 3
  })
}
