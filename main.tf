provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Example Route Table"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    name = "Example Subnet"
  }
}

resource "aws_route_table_association" "connection-RT-subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route-table.id
}

# note that for production use, the security group should be more restrictive
resource "aws_security_group" "sg" {
  name        = "test_security_group"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Example Security Group"
  }
}

#ssh key-pairs
module "key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.0"

  key_name           = "example-key"
  create_private_key = true

}

resource "local_file" "key_pem" {
  content         = module.key_pair.private_key_pem
  filename        = "key.pem"
  file_permission = "0600"
}

resource "local_file" "key_pub_pem" {
  content         = module.key_pair.public_key_pem
  filename        = "key_pub.pem"
  file_permission = "0600"
}

resource "aws_instance" "inf_nodes" {
  for_each = { cpu = 0, gpu = 1 }
  ami                         = each.key == "cpu" ? var.ami_cpu : var.ami_gpu
  associate_public_ip_address = true
  instance_type = each.key == "cpu" ? var.cpu_instance_type : var.gpu_instance_type
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = module.key_pair.key_pair_name
  root_block_device {
    volume_size           = each.key == "cpu" ? 50 : 150
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = { 
    Name = "node-${each.key}" 
  }
  
}

resource "local_file" "setup" {
  content  = <<-EOT
    #!/usr/bin/env bash
    cat <<EOF > install-docker-compose.sh
    #!/bin/bash
    curl -SL https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    EOF

    # Use SCP/SSH to execute commands on the remote host
    scp -i ${local_file.key_pem.filename} install-docker-compose.sh ec2-user@${aws_instance.inf_nodes["cpu"].public_ip}:/home/ec2-user/install-docker-compose.sh
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["cpu"].public_ip} sudo bash /home/ec2-user/install-docker-compose.sh
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["cpu"].public_ip} "sudo dnf update -y && sudo dnf install git docker -y"
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["cpu"].public_ip} "sudo systemctl start docker && sudo systemctl enable docker"
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["cpu"].public_ip} git clone https://github.com/BerriAI/litellm.git
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["cpu"].public_ip} "cd litellm && cp .env.example .env && docker-compose up -d"

    scp -i ${local_file.key_pem.filename} install-docker-compose.sh ec2-user@${aws_instance.inf_nodes["gpu"].public_ip}:/home/ec2-user/install-docker-compose.sh
    scp -i ${local_file.key_pem.filename} "${path.module}/docker/docker-compose.yml" ec2-user@${aws_instance.inf_nodes["gpu"].public_ip}:/home/ec2-user/docker-compose.yml
    scp -i ${local_file.key_pem.filename} "${path.module}/docker/.env.example" ec2-user@${aws_instance.inf_nodes["gpu"].public_ip}:/home/ec2-user/.env
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["gpu"].public_ip} sudo bash /home/ec2-user/install-docker-compose.sh
    ssh -n -i ${local_file.key_pem.filename} ec2-user@${aws_instance.inf_nodes["gpu"].public_ip} "docker-compose up -d"

  EOT
  filename = "setup.sh"
}