resource "aws_s3_bucket" "bucket" {
  bucket = "${var.app_name}-data-behavox-platform-sre"
  force_destroy = true
}

resource "aws_ecr_repository" "repo" {
  name = "${var.app_name}_repository-behavox-platform-sre"
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name = "${var.app_name}_role-behavox-platform-sre"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

resource "aws_iam_role_policy" "s3_access" {
  name = "s3-access"
  role = aws_iam_role.role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecr_read" {
  name = "ecr-read"
  role = aws_iam_role.role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

