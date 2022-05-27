#!/bin/bash

#Installing aws-cli based on Linux Hardware Arch

ROOT_UID=0     
E_NOTROOT=100
ARCH=$(uname -i)
#ARCH=`uname -i`

if [ "$UID" -ne "$ROOT_UID" ]
then
    echo "Must be root to run this script."
    exit $E_NOTROOT
fi  

which aws &> /dev/null || {
	echo "Installing aws-cli"
    which curl &> /dev/null || apt install curl -y && echo "curl is installed"
    which unzip &> /dev/null || apt install unzip -y && echo "unzip is installed"

    curl "https://awscli.amazonaws.com/awscli-exe-linux-$ARCH.zip" -o "awscliv2.zip"
    
    unzip $PWD/awscliv2.zip
    sudo $PWD/aws/install

    rm $PWD/awscliv2.zip

	} && {
        AWS_VERSION=$(aws --version | awk '{print $1}' | tr '/' '-')
		echo "$AWS_VERSION is already installed"
	}

#exit 0