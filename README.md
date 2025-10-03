# Using `terraform-aws-gitlab-runner` Terraform module with the Docker Autoscaler executor

This example demonstrates how to use the [terraform-aws-gitlab-runner](https://github.com/cattle-ops/terraform-aws-gitlab-runner) module with the Docker Autoscaler executor.

## Repository layout

* `ubuntu-docker-ami-packer/` — Packer template for building an AMI for self‑hosted GitLab Runner workers (Docker Autoscaler executor).
* `terraform/` — Example Terraform configuration that consumes the module.

## AMI details

The AMI is based on **Ubuntu 24.04** and includes:

* The latest Docker Engine.
* Docker Hub mirror configuration to help mitigate rate limits.
* The Amazon ECR credential helper for pulling images from ECR.
* The AWS Systems Manager (SSM) Agent enabled.

Build for AMD64: `packer build -var-file=./pkrvars/amd64.pkrvars.hcl .`
Build for ARM64: `packer build -var-file=./pkrvars/arm64.pkrvars.hcl .`