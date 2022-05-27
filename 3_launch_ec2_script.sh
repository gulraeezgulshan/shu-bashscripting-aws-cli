#!/bin/bash

ROOT_UID=0     
E_NOTROOT=100

#AWS Credentials
AWS_ACCESS_KEY_ID=<ACCESS_KEY>
AWS_SECRET_ACCESS_KEY=<SECRET_KEY>
AWS_DEFAULT_REGION=us-east-1

#EC2 DETAILS
AMI="ami-09d56f8956ab235b3"
COUNT=1
INSTANCE_TYPE="t2.micro"
KEY_NAME="first-class"
SUBNET_ID="subnet-0a8a6e012d998ba6c"
TAG='ResourceType=instance,Tags=[{Key=Name,Value=UbuntuServer}]'
SG="sg-0013099db32950982"


if [ "$UID" -ne "$ROOT_UID" ]
    then
        echo "Must be root to run this script."
        exit $E_NOTROOT
fi  

source 2_install_aws_cli-v2.sh

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_DEFAULT_REGION


aws ec2 run-instances \
	--image-id $AMI \
	--count $COUNT \
	--instance-type $INSTANCE_TYPE \
	--key-name $KEY_NAME \
	--security-group-ids $SG \
	--subnet-id $SUBNET_ID \
	--tag-specifications $TAG \
	--user-data file://user_data.txt
