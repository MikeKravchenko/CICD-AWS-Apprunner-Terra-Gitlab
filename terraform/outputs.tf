output "ecr_repos" {
  value = { for k, v in module.app : k => v.ecr_repo_url }
}

output "apprunner_services" {
  value = { for k, v in module.apprunner : k => v.apprunner_service_url }
}