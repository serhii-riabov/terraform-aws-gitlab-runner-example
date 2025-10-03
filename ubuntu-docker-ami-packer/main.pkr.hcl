locals {
  ami_name = "${var.ami_name}-${formatdate("YYYYMMDD-HHmm", timestamp())}"
  tags = {
    Name = var.ami_name
  }
}

source "amazon-ebs" "aws_ami" {
  region          = var.aws_region
  instance_type   = var.instance_type
  ssh_username    = var.ssh_username
  ami_name        = local.ami_name
  ami_description = var.ami_description
  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-*-server-*"
      architecture        = var.architecture
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["099720109477"] # Canonical
    most_recent = true
  }

  ami_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = local.tags
}


build {
  sources = ["source.amazon-ebs.aws_ami"]

  provisioner "file" {
    content     = templatefile("./configurations/bootstrap.sh.tpl", var.bootstrap_tpl_vars)
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/bootstrap.sh",
      "sudo /tmp/bootstrap.sh"
    ]
  }
}
