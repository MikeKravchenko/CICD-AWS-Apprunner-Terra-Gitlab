resource "aws_apprunner_service" "service" {
  service_name = "${var.app_name}_service-behavox-platform-sre"
  source_configuration {
    authentication_configuration {
      access_role_arn = var.ecr_access_role_arn
    }
    image_repository {
      image_identifier      = "${var.ecr_repo_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = var.port
        runtime_environment_variables = {
          NAME        = var.app_name
          PORT        = tostring(var.port)
          BUCKET_NAME = var.s3_bucket_name
        }
      }
    }
    auto_deployments_enabled = true
  }
  instance_configuration {
    cpu    = tostring(var.cpu)
    memory = tostring(var.memory)
    instance_role_arn = var.iam_role_arn
  }
}

