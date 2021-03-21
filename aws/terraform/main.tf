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
resource "aws_security_group" "allow_rdp" {
  name        = "allow_rdp"
  description = "Allow RDP inbound traffic"
  vpc_id      = data.aws_vpc.default.id
  ingress {
    description = "SSH"
    from_port   = 3389
    to_port     = 3389
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


# WINDOWS PHOTOGRAMMETRY INSTANCE
# To get Administrator password (.pem in ~/.ssh, see below for how it was generated):
#  aws --profile meirionconsulting ec2 get-password-data --instance-id INSTANCE_ID --priv-launch-key MyKeyPair.pem
resource "aws_spot_instance_request" "photogrammetry" {
  #ami                             = "ami-00991ab7b04e5a26f" # meshroom graphics, us-east-1
  ami                             = "ami-07817f5d0e3866d32" # windows server 2019
  # See https://aws.amazon.com/ec2/spot/pricing/ for G instances
  instance_type                   = "t2.micro"              # for testing (not g instance)
  #instance_type                   = "g3s.xlarge"            # for slow, cheap testing (g instance)
  #instance_type                   = "g3s.4xlarge"            # fast g instance
  spot_type                       = "one-time"
  associate_public_ip_address     = true
  wait_for_fulfillment            = true
  vpc_security_group_ids          = [aws_security_group.allow_ssh.name, aws_security_group.allow_rdp.name]
  key_name                        = aws_key_pair.sshkey.key_name
  instance_interruption_behaviour = "terminate"

  # Script to set up the instance for me
  # To view the logs of userdata in powershell:
  # dir -Force # To see hidden files
  # cat C:\ProgramData\Amazon\EC2-Windows\Launch\Log\Ec2Launch.log
  user_data     = <<EOF
<powershell>
# https://github.com/jirizarry426/Terraform-Playground/blob/c2cf040183fbb288e35c82aef8a4967548da9ca4/Windows/JI-TF-PG.tf
Set-ExecutionPolicy -executionpolicy unrestricted
New-LocalUser "meshroom" -Password (ConvertTo-SecureString "!QA2ws3ed" -AsPlainText -Force) -FullName "meshroom" -Description "run meshroom"
Add-LocalGroupmember -Group "Administrators" -Member "meshroom"

# Allow Remote Desktop connections : https://vmarena.com/how-to-enable-remote-desktop-rdp-remotely-using-powershell/
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1

# Download meshroom
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
$Url = 'https://81.149.204.19/files/Meshroom-2021.1.0-win64.zip'
$ZipFile = 'C:\Users\meshroom' + $(Split-Path -Path $Url -Leaf)
$Destination= 'C:\Users\meshroom'

Invoke-WebRequest -Uri $Url -OutFile $ZipFile

# change ownership of meshroom
$ACL = Get-Acl $ZipFile
$User = New-Object  System.Security.Principal.NTAccount("meshroom")
Set-Acl -Path $ZipFile -AclObject $ACL

# Extract file
$ExtractShell = New-Object -ComObject Shell.Application
$Files = $ExtractShell.Namespace($ZipFile).Items()
$ExtractShell.NameSpace($Destination).CopyHere($Files)

# Install SSH client and server
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Install Cygwin
param ( $TempCygDir="$env:temp\cygInstall" )
if(!(Test-Path -Path $TempCygDir -PathType Container))
 {
    $null = New-Item -Type Directory -Path $TempCygDir -Force
 }
$client = new-object System.Net.WebClient
$client.DownloadFile("http://cygwin.com/setup.exe", "$TempCygDir\setup.exe" )
Start-Process -wait -FilePath "$TempCygDir\setup.exe" -ArgumentList "-q -n -l $TempCygDir -s http://mirror.nyi.net/cygwin/ -R c:\Cygwin"
Start-Process -wait -FilePath "$TempCygDir\setup.exe" -ArgumentList "-q -n -l $TempCygDir -s http://mirror.nyi.net/cygwin/ -R c:\Cygwin -P openssh"
</powershell>
EOF
}


# This key was generated outside Terraform with:
# Generated: aws --profile meirionconsulting ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem
# Pub key: ssh-keygen -f MyKeyPair.pem -y > MyKeyPair.pub
resource "aws_key_pair" "sshkey" {
  key_name   = "sshkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCGcOG42d9/cI5VvgzNW2ZUSlJIVM9zYL0TYpBuuybZyO5yiWqo34akF/+WunTT9Z6dLC3r77yqnAWeLIhyyT6jilpn/pwvtW+ROBBe56FpHZeAyYMM+/ks3uhsbos+fIo6HUlvssUihfQoatB2ydrpBiZnevwqmg4v0QB7/PRrRFlKFkotZwKKRnsYLpVEnhaVii9oNZFtuocrlbDRaA2lvjUBYppMpPyQQ2wb+PXMyp6ddeJLea9SM8kk/GbFnKKzFzjKXw1azvK7MkMDHY/X9WsyYRYwCYgBFVc2Bp9Ise034G9j4F11Z0t1LpLSDrCGXjDzwkqhuAwmwm55wX7F"
}
