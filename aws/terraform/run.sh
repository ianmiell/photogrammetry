#!/bin/bash

set -o xtrace
set -o errexit
set -o nounset

# TODO: take in folder as input
# TODO: rsync folder, rather than scp
INPUT_FILE="${HOME}/git/dataset_monstree/full/images.tar"

terraform plan
terraform apply -auto-approve

IP="$(terraform show -no-color | grep public_ip | awk '{print $3}' | tail -1 | sed 's/^"\(.*\)"/\1/')"

set +o errexit
while true
do
    if sshpass -p '!QA2ws3ed' | scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${INPUT_FILE}" "meshroom@${IP}:"
    then
        break
    fi
    sleep 10
done
echo "Now run: aws --profile meirionconsulting ec2 get-password-data --priv-launch-key ~/.ssh/MyKeyPair.pem --instance-id INSTANCE_ID"
echo "to get the admin password"
echo "Install NVIDIA drivers"
echo "To download a public NVIDIA driver
echo "Log on to your Windows instance and download the 64-bit NVIDIA driver appropriate for the instance type from http://www.nvidia.com/Download/Find.aspx. For Product Type, Product Series, and Product, use the options in the following table."
echo "Instance	Product Type	Product Series	Product"
echo "G3	Tesla	M-Class	M60"
