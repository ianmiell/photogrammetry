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
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${INPUT_FILE}" "meshroom@${IP}:"
    sleep 10
done
set -o errexit

