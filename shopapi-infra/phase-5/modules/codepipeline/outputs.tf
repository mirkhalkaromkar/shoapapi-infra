output "pipeline_name"       { value = aws_codepipeline.app.name }
output "github_connection_arn" { value = aws_codestarconnections_connection.github.arn }
output "github_connection_status" { value = aws_codestarconnections_connection.github.connection_status }
