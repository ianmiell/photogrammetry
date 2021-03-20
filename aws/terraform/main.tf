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

resource "aws_spot_instance_request" "photogrammetry" {
  ami                             = "ami-00991ab7b04e5a26f" # us-east-1
  # See https://aws.amazon.com/ec2/spot/pricing/ for G instances
  #instance_type                   = "t2.micro"              # for testing (not g instance)
  instance_type                   = "g3s.xlarge"            # for slow, cheap testing (g instance)
  #instance_type                   = "g3s.4xlarge"            # fast g instance
  spot_type                       = "one-time"
  associate_public_ip_address     = true
  wait_for_fulfillment            = true
  vpc_security_group_ids          = [aws_security_group.allow_ssh.name]
  key_name                        = aws_key_pair.sshkey.key_name
  instance_interruption_behaviour = "terminate"
}

resource "aws_key_pair" "sshkey" {
  key_name   = "sshkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL3OmPrKxJN436tuw6h2hmE2B2toi7PMb3GbgYntgBXx0Kif3z6a+Je1kKZEQ1gAlH2UOjvbz+cnuZLRcqa+S+r8Tz86fNLlHsJ86SiBXw1gDm0WmF0rkxGwyRqc96o2P3tl2rVrAwnMVt9Xe5Z5hGFruH9lU7bz2smvyw6g0OSlWd1TMrXTGACHaf4u6CWuRWgHkTFi31NsZX2EQQbK4YK6HVVsQUrV6ygyk6qe0zKyp8fqiYyYCI7QEbkhgLq27xG4tSRTySjRbm1DBLNFRHRrPoKSHgZ7jOca0TjO07Mgf0Knv7zvDeRdmhB3iSuO6ZfYAx1hdlAt9W06Pr3BKR imiell@Ians-MacBook-Pro.local"
}

