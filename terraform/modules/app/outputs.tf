output "ecr_repo_url" {
  value = aws_ecr_repository.repo.repository_url
}

output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "iam_role_arn" {
  value = aws_iam_role.role.arn
}