#!/bin/bash

MESHROOM_NAME="Meshroom-2021.1.0-linux-cuda10"
PROJECT_NAME="this_project"
INPUT_FILE="/home/ec2-user/input.tar.gz"

# TODO
# Standard install:
# https://meshroom-manual.readthedocs.io/en/latest/install/linux/linux.html

## GUI?
## From: https://forums.centos.org/viewtopic.php?t=69793
#yum update -y
#yum groupinstall -y "Desktop"
#yum install -y pixman pixman-devel libXfont tigervnc-server
#echo "now 'passwd ec2-user'"
#echo "now 'vncpasswd'"
#echo "Edit the sshd_config file and set the password authentication parameter to 'yes'"
#echo service sshd restart
#echo 'Update the parameters of /etc/sysconfig/vncservers config file: '
#echo '    VNCSERVERS="1:ec2-user 2:user2"'
#echo '    VNCSERVERARGS[1]="-geometry 1024x768"'
#echo '    VNCSERVERARGS[2]="-geometry 1024x768"'
#echo 'service vncserver start'
#echo 'chkconfig vncserver on'
#echo 'iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 5901 -j ACCEPT'
#echo '14. Now we have an instance with GUI configured. To access it you need a VNC client. Go to this link to get a VNC viewer client. Install the software and open it.'
#echo '15. Enter the public IP of you instance followed by the port number 5901 (assuming you the first vnc server user) and click connect. When asked for a password, supply the password you created for vnc server in step 6.'
#echo '16. Now you will get the access to the GUI. If it asks for ec2-user password, supply the password you created in step 5.'


mkdir -p /data/project/${PROJECT_NAME}/input
mkdir -p /data/project/${PROJECT_NAME}/output

# Install meshroom
cd /data || exit 1
curl -L https://github.com/alicevision/meshroom/releases/download/v2019.2.0/Meshroom-2019.2.0-linux.tar.gz | tar -zxvf -
git clone https://github.com/alicevision/AliceVision.git --recursive
mkdir build && cd build
cmake -DALICEVISION_BUILD_DEPENDENCIES=ON -DCMAKE_INSTALL_PREFIX=$PWD/../install ../AliceVision
make -j10


# OLD
#ln -s Mesh* meshroom
#
## Install script
#cd /data/project || exit 1
#cat > script.sh << EOF
##!/bin/bash
#set -x
#set -o errexit
#if [ ! -f "project.mg" ]; then
#    /data/meshroom/meshroom_photogrammetry --input /data/project/${PROJECT_NAME}/input --output /data/project/${PROJECT_NAME}/output --save /data/project/${PROJECT_NAME}/project.mg
#fi
#/data/meshroom/meshroom_compute /data/project/${PROJECT_NAME}/project.mg --toNode Publish_1 --forceStatus
#EOF
#chmod +x script.sh
#chown -R root:root /data
#
#
#
## TODO:
## check out meshroom as well as donwloading 2021 version
##
## env setup
## export ALICEVISION_INSTALL=/path/to/alicevision/AliceVision/build/install
## if you need the plugins
## export QML2_IMPORT_PATH=/path/to/qmlAlembic/build/install/qml:/path/to/QtAliceVision/build/install/qml:$QML2_IMPORT_PATH
## export ALICEVISION_SENSOR_DB=${ALICEVISION_INSTALL}/share/aliceVision/cameraSensors.db
## export LD_LIBRARY_PATH=/usr/lib/nvidia-384:/usr/local/cuda-8.0/lib64/:$LD_LIBRARY_PATH
## export MESHROOMPATH=$PWD
## PYTHONPATH=${MESHROOMPATH} PATH=$PATH:${ALICEVISION_INSTALL}/bin python ${MESHROOMPATH}/meshroom/ui $@
#
#
#mv "${INPUT_FILE}" "/data/project/${PROJECT_NAME}/input"
#cd "/data/project/${PROJECT_NAME}/input" || exit 1
#tar -zxvf input.tar.gz && rm input.tar.gz
