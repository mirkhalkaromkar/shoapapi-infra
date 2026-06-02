output "queue_url" { value = aws_sqs_queue.product_events.url }
output "queue_arn" { value = aws_sqs_queue.product_events.arn }
output "dlq_url"   { value = aws_sqs_queue.product_events_dlq.url }
