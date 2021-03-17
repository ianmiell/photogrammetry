terraform {
  required_providers {
    aws = {
      version    = "~> 2.51"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  profile    = "meirionconsulting"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "photogrammetry" {
  ami           = "ami-00991ab7b04e5a26f" # us-east-1
  instance_type = "t2.micro"
  security_groups = [aws_security_group.allow_ssh.name]
}
