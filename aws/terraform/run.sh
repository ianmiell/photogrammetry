#!/bin/bash

set -o xtrace
set -o errexit
set -o nounset

# TODO: take in folder as input
# TODO: rsync folder, rather than scp
INPUT_FILE="${HOME}/git/home/notes/3dprinting/photogrammetry/input_files/Zephyr_Dante_Statue_Dataset/input.tar.gz"

terraform plan
terraform apply -auto-approve

IP="$(terraform show -no-color | grep public_ip | awk '{print $3}' | tail -1 | sed 's/^"\(.*\)"/\1/')"

set +o errexit
while true
do
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null script.sh "ec2-user@${IP}:" && break
    sleep 10
done
set -o errexit
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${INPUT_FILE}" "ec2-user@${IP}:"

echo "# NOW RUN"
echo ssh "ec2-user@${IP}"
echo "sudo su"
echo "./script.sh"
