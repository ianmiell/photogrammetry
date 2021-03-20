#!/bin/bash

set -o xtrace
set -o errexit
set -o nounset

INPUT_FILE="${HOME}/git/home/notes/3dprinting/photogrammetry/input_files/Zephyr_Dante_Statue_Dataset/input.tar.gz"

terraform plan
terraform apply -auto-approve

IP="$(terraform show -no-color | grep public_ip | awk '{print $3}' | tail -1 | sed 's/^"\(.*\)"/\1/')"

set +o errexit
while true
do
    scp script.sh "ec2-user@${IP}:" && break
done
set -o errexit
scp "${INPUT_FILE}" "ec2-user@${IP}:"

ssh "ec2-user@${IP}" echo 'now run: "sudo su; ./script.sh"'
