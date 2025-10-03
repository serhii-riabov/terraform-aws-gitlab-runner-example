aws_region      = "change_me"
vpc_id          = "change_me"
subnet_id       = "change_me"
ami_name        = "gitlab-runner-worker-ubuntu-24.04-amd64"
ami_description = "GitLab Runner Worker - Ubuntu Linux 24.04 (AMD64)"
ssh_username    = "ubuntu"
instance_type   = "t3.micro"
architecture    = "x86_64"
bootstrap_tpl_vars = {
  docker_mirror = "https://mirror.gcr.io" # Example
}
