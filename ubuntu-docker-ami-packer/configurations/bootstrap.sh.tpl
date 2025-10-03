#!/bin/bash
set -euo pipefail
set -x

# Remove any pre-existing Docker packages (ignore errors if package is not found)
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg || true
done

# Install Docker dependencies
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker's official repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

# Install Docker CE, CLI, Containerd, Buildx, and Compose plugins
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker registry mirror
sudo mkdir -p /etc/docker
echo '{
  "registry-mirrors": ["${docker_mirror}"]
}' | sudo tee /etc/docker/daemon.json

sudo systemctl restart docker

# Configure Docker permissions
sudo usermod -aG docker ubuntu

# Install ECR credentials helper
sudo apt-get install -y amazon-ecr-credential-helper

# Configure Docker to use ECR credential helper for ubuntu user
sudo -u ubuntu mkdir -p /home/ubuntu/.docker
echo '{"credsStore": "ecr-login"}' | sudo tee /home/ubuntu/.docker/config.json
sudo chown ubuntu:ubuntu /home/ubuntu/.docker/config.json

# Configure Docker to use ECR credential helper for root user
sudo mkdir -p /root/.docker
echo '{"credsStore": "ecr-login"}' | sudo tee /root/.docker/config.json

# Enabling SSM Agent
sudo snap start amazon-ssm-agent
