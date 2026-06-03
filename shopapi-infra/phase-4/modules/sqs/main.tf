resource "aws_sqs_queue" "product_events" {
  name                       = "${var.project}-${var.env}-product-events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 5
  tags                       = { Project = var.project, Env = var.env }
}

resource "aws_sqs_queue" "product_events_dlq" {
  name                      = "${var.project}-${var.env}-product-events-dlq"
  message_retention_seconds = 604800
  tags                      = { Project = var.project, Env = var.env }
}

resource "aws_sqs_queue_redrive_policy" "product_events" {
  queue_url = aws_sqs_queue.product_events.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.product_events_dlq.arn
    maxReceiveCount     = 3
  })
}
