
locals {
  ssh_sg_name          = "${var.project_id}-ssh-sg"
  public_http_sg_name  = "${var.project_id}-public-http-sg"
  private_http_sg_name = "${var.project_id}-private-http-sg"

  common_tags = {
    Project = var.project_id
  }
}

data "aws_instance" "public" {
  instance_id = var.public_instance_id
}

data "aws_instance" "private" {
  instance_id = var.private_instance_id
}

# SSH security group
resource "aws_security_group" "ssh" {
  name        = local.ssh_sg_name
  description = "Allow SSH and ICMP from approved IP ranges"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.ssh.id

  description = "SSH from approved IP ranges"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = var.allowed_ip_range
}

resource "aws_security_group_rule" "ssh_icmp_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.ssh.id

  description = "ICMP from approved IP ranges"
  protocol    = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_blocks = var.allowed_ip_range
}

# Public HTTP security group
resource "aws_security_group" "public_http" {
  name        = local.public_http_sg_name
  description = "Allow public HTTP and approved ICMP traffic"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

resource "aws_security_group_rule" "public_http_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.public_http.id

  description = "HTTP from approved IP ranges"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = var.allowed_ip_range
}

resource "aws_security_group_rule" "public_http_icmp_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.public_http.id

  description = "ICMP from approved IP ranges"
  protocol    = "icmp"
  from_port   = -1
  to_port     = -1
  cidr_blocks = var.allowed_ip_range
}

# Private HTTP security group
resource "aws_security_group" "private_http" {
  name        = local.private_http_sg_name
  description = "Allow HTTP only from the public HTTP security group"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

resource "aws_security_group_rule" "private_http_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.private_http.id
  source_security_group_id = aws_security_group.public_http.id

  description = "HTTP from instances associated with the public HTTP SG"
  protocol    = "tcp"
  from_port   = 8080
  to_port     = 8080
}

resource "aws_security_group_rule" "private_http_icmp_ingress" {
  type                     = "ingress"
  security_group_id        = aws_security_group.private_http.id
  source_security_group_id = aws_security_group.public_http.id

  description = "ICMP from instances associated with the public HTTP SG"
  protocol    = "icmp"
  from_port   = -1
  to_port     = -1
}

# Attach SSH and public HTTP security groups to the public instance
resource "aws_network_interface_sg_attachment" "public_ssh" {
  security_group_id    = aws_security_group.ssh.id
  network_interface_id = data.aws_network_interface.public_primary.id
}

resource "aws_network_interface_sg_attachment" "public_http" {
  security_group_id    = aws_security_group.public_http.id
  network_interface_id = data.aws_network_interface.public_primary.id
}

# Attach SSH and private HTTP security groups to the private instance
resource "aws_network_interface_sg_attachment" "private_ssh" {
  security_group_id    = aws_security_group.ssh.id
  network_interface_id = data.aws_network_interface.private_primary.id
}

resource "aws_network_interface_sg_attachment" "private_http" {
  security_group_id    = aws_security_group.private_http.id
  network_interface_id = data.aws_network_interface.private_primary.id
}


data "aws_network_interface" "public_primary" {
  filter {
    name   = "attachment.instance-id"
    values = [var.public_instance_id]
  }

  filter {
    name   = "attachment.device-index"
    values = ["0"]
  }
}

data "aws_network_interface" "private_primary" {
  filter {
    name   = "attachment.instance-id"
    values = [var.private_instance_id]
  }

  filter {
    name   = "attachment.device-index"
    values = ["0"]
  }
}
