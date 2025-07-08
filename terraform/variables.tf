variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "apps" {
  type = list(object({
    name   = string
    port   = number
    cpu    = number
    memory = number
  }))
}
