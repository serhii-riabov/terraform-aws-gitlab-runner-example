data "aws_caller_identity" "current" {}

resource "aws_ssm_parameter" "gitlab_runner_token_1" {
  name  = "gitlab_runner_token_1"
  type  = "String"
  value = var.gitlab_runner_registration_token_1
}

locals {
  gitlab_worker_egress_rules = {
    allow_https_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS egress traffic to all destinations (IPv4)"
    },
    allow_https_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      description     = "Allow HTTPS egress traffic to all destinations (IPv6)"
    },
    allow_http_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP egress traffic to all destinations (IPv4)"
    },
    allow_http_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      description     = "Allow HTTP egress traffic to all destinations (IPv6)"
    },
    allow_ssh_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH egress traffic to all destinations (IPv4)"
    },
    allow_ssh_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      description     = "Allow SSH egress traffic to all destinations (IPv6)"
    },
    allow_icmp_ipv4 = {
      cidr_block  = "0.0.0.0/0"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "Allow ICMP to all destinations (IPv4)"
    },
    allow_icmp_ipv6 = {
      ipv6_cidr_block = "::/0"
      from_port       = -1
      to_port         = -1
      protocol        = "icmpv6"
      description     = "Allow ICMP to all destinations (IPv6)"
    }
  }

  gitlab_runners_config = {
    gitlab_runners_1 = {
      environment                       = "dev"
      ssm_param_name                    = aws_ssm_parameter.gitlab_runner_token_1.name
      prefix                            = "glr-1-"
      runner_manager_version            = "17.10.1"
      runner_manager_concurrent_jobs    = 5 # Max concurrent jobs on manager
      runner_manager_instance_type      = "t4g.micro"
      runner_manager_ami_filter         = "al2023-ami-2023*-arm64"
      runner_worker_max_jobs            = 5 # Max EC2 instances (parallel jobs)
      runner_worker_request_concurrency = 5
      runner_worker_instance_types      = ["m4.xlarge", "m5.xlarge"]
      runner_worker_root_device_name    = "/dev/sda1" # For Ubuntu
      runner_worker_instance_root_size  = 50
      runner_worker_egress_rules        = local.gitlab_worker_egress_rules
      runner_worker_ami_filter          = var.gitlab_runner_worker_ami_filter
      runner_worker_username            = "ubuntu"
      runner_worker_autoscaling_options = [
        {
          # From 8:00 to 17:59, Monday to Friday
          periods    = ["* 8-17 * * mon-fri"]
          idle_count = 1
          idle_time  = "10m0s"
          timezone   = "America/Edmonton"
        }
      ]
    }
    # gitlab_runners_2  = {
    # ...
    # }
  }
}

module "gitlab_runner" {
  source  = "cattle-ops/gitlab-runner/aws"
  version = "~> 9.0"

  for_each = local.gitlab_runners_config

  ### General parameters ###

  vpc_id            = var.vpc_id
  subnet_id         = one(var.subnet_ids)
  iam_object_prefix = "gitlab-${each.value.prefix}-"
  environment       = each.value.environment

  ### Runner Manager ###

  runner_gitlab = {
    runner_version = each.value.runner_manager_version
    url            = "https://gitlab.com"

    preregistered_runner_token_ssm_parameter_name = each.value.ssm_param_name
  }

  runner_manager = {
    maximum_concurrent_jobs = each.value.runner_manager_concurrent_jobs
  }

  # Needed for ECR auth to work properly  
  runner_install = {
    amazon_ecr_credential_helper = true
    pre_install_script           = <<-EOT
      mkdir -p /root/.docker
      echo '{"credsStore": "ecr-login"}' > /root/.docker/config.json
    EOT
  }

  runner_instance = {
    name = "gitlab-runner-manager-${each.key}"
    type = each.value.runner_manager_instance_type
  }

  runner_ami_filter = {
    name = [each.value.runner_manager_ami_filter]
  }

  runner_role = {
    policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }

  ### Runner Workers ###

  runner_worker_docker_autoscaler = {
    connector_config_user = each.value.runner_worker_username
  }

  runner_worker = {
    max_jobs            = each.value.runner_worker_max_jobs
    request_concurrency = each.value.runner_worker_request_concurrency
    type                = "docker-autoscaler"
  }

  runner_worker_docker_autoscaler_asg = {
    enable_mixed_instances_policy            = true
    on_demand_percentage_above_base_capacity = 0
    subnet_ids                               = var.subnet_ids
    types                                    = toset(each.value.runner_worker_instance_types)
    spot_allocation_strategy                 = "capacity-optimized"
  }

  runner_worker_docker_autoscaler_autoscaling_options = try(each.value.runner_worker_autoscaling_options, [])

  runner_worker_docker_autoscaler_role = {
    policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }

  runner_worker_docker_autoscaler_instance = {
    root_device_name     = each.value.runner_worker_root_device_name
    root_size            = each.value.runner_worker_instance_root_size
    volume_type          = "gp3"
    private_address_only = true
    ebs_optimized        = true
  }

  runner_worker_egress_rules = each.value.runner_worker_egress_rules

  runner_worker_docker_autoscaler_ami_owners = ["self"]
  runner_worker_docker_autoscaler_ami_filter = each.value.runner_worker_ami_filter

  runner_worker_docker_options = {
    disable_cache                         = "false"
    image                                 = "docker:28.4"
    privileged                            = "true"
    pull_policies                         = ["always"]
    shm_size                              = 0
    tls_verify                            = "false"
    runner_worker_docker_add_dind_volumes = true

    # For Docker Hub mirror to work in DinD container
    volumes = ["/cache", "/etc/docker/daemon.json:/etc/docker/daemon.json:ro"]
  }

}
