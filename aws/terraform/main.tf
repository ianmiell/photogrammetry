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
  name                            = "allow_rdp"
  description                     = "Allow RDP inbound traffic"
  vpc_id                          = data.aws_vpc.default.id
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
#  aws --profile meirionconsulting ec2 get-password-data --priv-launch-key ~/.ssh/MyKeyPair.pem --instance-id INSTANCE_ID
resource "aws_spot_instance_request" "photogrammetry" {
  # See https://aws.amazon.com/ec2/spot/pricing/ for G instances
  ami                             = "ami-07817f5d0e3866d32" # Windows_Server-2019-English-Full-Base-2021.03.10 us-east-1
  #ami                             = "ami-00791cfc13337a406" # Windows_Server-2019-English-Full-Base-2021.03.10 us-west-1
  #ami                             = "ami-077475371a476c548" # Windows_Server-2019-English-Full-Base-2021.03.10 us-west-2
  instance_type                   = "g3s.xlarge"
  spot_type                       = "one-time"
  associate_public_ip_address     = true
  wait_for_fulfillment            = true
  vpc_security_group_ids          = [aws_security_group.allow_ssh.name, aws_security_group.allow_rdp.name]
  key_name                        = aws_key_pair.sshkey.key_name

  # Script to set up the instance for me
  # To view the logs of userdata in powershell:
  # dir -Force # To see hidden files
  # cat C:\ProgramData\Amazon\EC2-Windows\Launch\Log\Ec2Launch.log
  user_data     = <<EOF
<powershell>

#$username = "meshroom"
#$password = ConvertTo-SecureString "${var.password}" -AsPlainText -Force
#$cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)

# Set Administrator password
$admin = [adsi]("WinNT://./administrator, user")
$admin.psbase.invoke("SetPassword", "${var.password}")

# https://github.com/jirizarry426/Terraform-Playground/blob/c2cf040183fbb288e35c82aef8a4967548da9ca4/Windows/JI-TF-PG.tf
Set-ExecutionPolicy -executionpolicy unrestricted
New-LocalUser "meshroom" -Password (ConvertTo-SecureString "${var.password}" -AsPlainText -Force) -FullName "meshroom" -Description "run meshroom"
Add-LocalGroupmember -Group "Administrators" -Member "meshroom"

# Allow Remote Desktop connections : https://vmarena.com/how-to-enable-remote-desktop-rdp-remotely-using-powershell/
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1

# Install SSH client and server
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Restart-Service sshd
# Restart on reboot
Set-Service -Name sshd -StartupType 'Automatic'

Write-Host "Installing Cygwin x86..." -ForegroundColor Cyan

if(Test-Path C:\cygwin) {
    Write-Host "Deleting existing installation..."
    Remove-Item C:\cygwin -Recurse -Force
}

# download installer
New-Item -Path C:\cygwin -ItemType Directory -Force
$exePath = "C:\cygwin\setup-x86.exe"
(New-Object Net.WebClient).DownloadFile('https://cygwin.com/setup-x86.exe', $exePath)

# install cygwin
cmd /c start /wait $exePath -qnNdO -R C:/cygwin -s http://cygwin.mirror.constant.com -l C:/cygwin/var/cache/setup -P mingw64-i686-gcc-g++ -P mingw64-x86_64-gcc-g++ -P gcc-g++ -P autoconf -P automake -P bison -P libtool -P make -P python -P gettext-devel -P intltool -P libiconv -P pkg-config -P wget -P curl
C:\Cygwin\bin\bash -lc true

# C:\cygwin\bin\gcc --version
Write-Host "Installing Cygwin x64..." -ForegroundColor Cyan
if(Test-Path C:\cygwin64) {
    Write-Host "Deleting existing installation..."
    Remove-Item C:\cygwin64 -Recurse -Force
}

# CYGWIN
# download installer
New-Item -Path C:\cygwin64 -ItemType Directory -Force
$exePath = "C:\cygwin64\setup-x86_64.exe"
(New-Object Net.WebClient).DownloadFile('https://cygwin.com/setup-x86_64.exe', $exePath)
# install cygwin
cmd /c start /wait $exePath -qnNdO -R C:/cygwin64 -s http://cygwin.mirror.constant.com -l C:/cygwin64/var/cache/setup -P mingw64-i686-gcc-g++ -P mingw64-x86_64-gcc-g++ -P gcc-g++ -P autoconf -P automake -P bison -P libtool -P make -P python -P gettext-devel -P intltool -P libiconv -P pkg-config -P wget -P curl
C:\cygwin64\bin\bash -lc true
Write-Host "Installed Cygwin x86" -ForegroundColor Green
# compact folders
Write-Host "Compacting C:\cygwin..." -NoNewline
compact /c /i /s:C:\cygwin | Out-Null
Write-Host "OK" -ForegroundColor Green
Write-Host "Compacting C:\cygwin64..." -NoNewline
compact /c /i /s:C:\cygwin64 | Out-Null
Write-Host "OK" -ForegroundColor Green


# NVIDIA DRIVER (MANUALLY PLACED ON HOME SERVER)
$Destination = 'C:\Users\Administrator\NVIDIA.exe'
$Url = 'http://meirionconsulting.com/meirionconsulting/files/nvidia.exe'
Invoke-WebRequest -Uri $Url -OutFile $Destination


# Create images folder
[system.io.directory]::CreateDirectory("C:\Users\meshroom\images")

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
$Url = 'http://meirionconsulting.com/meirionconsulting/files/Meshroom-2021.1.0-win64.zip'
$ZipFile = 'C:\Users\meshroom\' + $(Split-Path -Path $Url -Leaf)
$Destination = 'C:\Users\meshroom\'
Invoke-WebRequest -Uri $Url -OutFile $ZipFile
# change ownership of meshroom
$ACL = Get-Acl $ZipFile
$User = New-Object  System.Security.Principal.NTAccount("meshroom")
Set-Acl -Path $ZipFile -AclObject $ACL
# Extract file
$ExtractShell = New-Object -ComObject Shell.Application
$Files = $ExtractShell.Namespace($ZipFile).Items()
$ExtractShell.NameSpace($Destination).CopyHere($Files)

# change ownership / session to meshroom
C:\cygwin64\bin\bash -c 'chown -R meshroom /cygdrive/c/home/meshroom'
C:\cygwin64\bin\bash -c 'ls -ltR /cygdrive/c/home/meshroom'


# Untar images (uploaded by now by run.sh)
cd 'C:\Users\meshroom\images'
tar -xvf images.tar
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
