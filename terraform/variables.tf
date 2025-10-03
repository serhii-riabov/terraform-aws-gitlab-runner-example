variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "gitlab_runner_worker_ami_filter" {
  description = "GitLab Runner Worker AMI Filter"
  type        = map(list(string))
  default = {
    name = ["gitlab-runner-worker-ubuntu-24.04-amd64-*"]
  }
}

variable "gitlab_runner_registration_token_1" {
  description = "GitLab Runner Registration token 1"
  type        = string
  sensitive   = true
}

