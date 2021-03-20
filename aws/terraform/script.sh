#!/bin/bash

MESHROOM_NAME="Meshroom-2021.1.0-linux-cuda10"
PROJECT_NAME="this_project"
INPUT_FILE="/home/ec2-user/input.tar.gz"

mkdir -p /data/project/${PROJECT_NAME}/input
mkdir -p /data/project/${PROJECT_NAME}/output

# Install meshroom
cd /data || exit 1
curl -L https://github.com/alicevision/meshroom/releases/download/v2021.1.0/${MESHROOM_NAME}.tar.gz | tar -zxvf -
ln -s Mesh* meshroom

# Install script
cd /data/project || exit 1
cat > script.sh << EOF
#!/bin/bash
set -x
set -o errexit
if [ ! -f "project.mg" ]; then
    mkdir /data/project/${PROJECT_NAME}/output
    /data/meshroom/meshroom_photogrammetry --input /data/project/${PROJECT_NAME}/input --output /data/project/${PROJECT_NAME}/output --save /data/project/${PROJECT_NAME}/project.mg
fi
/data/meshroom/meshroom_compute /data/project/${PROJECT_NAME}/project.mg --toNode Publish_1 --forceStatus
EOF

mv "${INPUT_FILE}" "/data/project/${PROJECT_NAME}/input"
cd "/data/project/${PROJECT_NAME}/input" || exit 1
tar -zxvf input.tar.gz && rm input.tar.gz

