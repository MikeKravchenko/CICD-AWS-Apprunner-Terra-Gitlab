terraform {
  backend "s3" {
    bucket         = "behavox-platform-sre-tfstate"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "behavox-platform-sre-tfstate-lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  apps = var.apps
}

module "app" {
  source = "./modules/app"
  for_each = { for app in local.apps : app.name => app }

  app_name        = each.value.name
  port            = each.value.port
  cpu             = each.value.cpu
  memory          = each.value.memory
  aws_account_id  = var.aws_account_id
  aws_region      = var.aws_region
}

# App Runner module is only included/applied in the deploy stage
module "apprunner" {
  source = "./modules/apprunner"
  for_each = { for app in local.apps : app.name => app }

  app_name        = each.value.name
  port            = each.value.port
  cpu             = each.value.cpu
  memory          = each.value.memory
  aws_account_id  = var.aws_account_id
  aws_region      = var.aws_region
  ecr_repo_url    = module.app[each.key].ecr_repo_url
  s3_bucket_name  = module.app[each.key].s3_bucket_name
  iam_role_arn    = module.app[each.key].iam_role_arn
  ecr_access_role_arn = aws_iam_role.apprunner_ecr_access.arn
}

resource "aws_iam_role" "apprunner_ecr_access" {
  name = "service-role-AppRunnerECRAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}