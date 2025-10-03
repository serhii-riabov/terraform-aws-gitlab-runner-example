variable "ami_name" {
  description = "AMI Base Name"
  type        = string
}

variable "ami_description" {
  description = "AMI Description"
  type        = string
}

variable "ssh_username" {
  description = "Username to log in to EC2 instance"
  type        = string
  default     = "ubuntu"
}

variable "instance_type" {
  description = "EC2 Instance Type for Build"
  type        = string
  default     = "t3.micro"
}

variable "architecture" {
  description = "EC2 Instance Architecture for Build"
  type        = string
  default     = "x86_64"
}

variable "bootstrap_tpl_vars" {
  description = "Template variables for bootstrap script"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}
