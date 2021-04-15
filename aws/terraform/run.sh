#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset

# TODO: take in folder as input
# TODO: rsync folder, rather than scp
INPUT_FILE="${HOME}/git/home/notes/3dprinting/photogrammetry/input_files/yesno/input.tar"

terraform plan
terraform apply -auto-approve

IP="$(terraform show -no-color | grep public_ip | awk '{print $3}' | tail -1 | sed 's/^"\(.*\)"/\1/')"
INSTANCE_ID="$(terraform show -json | jq . | grep 'spot_instance_id": "' | awk '{print $NF}' | sed 's/^.\(.*\)",/\1/g')"

set +o errexit
while true
do
    if scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${INPUT_FILE}" "meshroom@${IP}":'C:\Users\meshroom\images\images.tar'
    then
        break
    fi
    sleep 10
done
echo "================================================================================"
echo ADMINISTRATOR PASSWORD:
aws --profile meirionconsulting ec2 get-password-data --priv-launch-key ~/.ssh/MyKeyPair.pem --instance-id "$INSTANCE_ID" | grep Password
echo "================================================================================"
echo ""
echo "1) Run exe, taking defaults"
echo "2) Restart"
echo ""
echo "OR"
echo ""
echo "Run C:\Users\Administrator\NVIDIA.exe"
echo "and restart"

