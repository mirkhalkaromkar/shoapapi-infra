output "project_name"       { value = aws_codebuild_project.app.name }
output "artifact_bucket"    { value = aws_s3_bucket.artifacts.bucket }
output "artifact_bucket_arn" { value = aws_s3_bucket.artifacts.arn }
