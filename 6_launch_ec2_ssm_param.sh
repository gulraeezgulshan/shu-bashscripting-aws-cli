#!/bin/bash

ROOT_UID=0     
E_NOTROOT=100


if [ "$UID" -ne "$ROOT_UID" ]
    then
        echo "Must be root to run this script."
        exit $E_NOTROOT
fi 

echo "Checking for AWS CLI..."
source 2_install_aws_cli-v2.sh

#AWS Credentials gettimg from AWS parameter store

echo "Getting Credential Details..."
AWS_ACCESS_KEY_ID=$(aws --region=us-east-1 ssm get-parameter --name "_____" --with-decryption --output text --query Parameter.Value)
AWS_SECRET_ACCESS_KEY=$(aws --region=us-east-1 ssm get-parameter --name "_____" --with-decryption --output text --query Parameter.Value)
AWS_DEFAULT_REGION=us-east-1

echo "Getting VPC Details..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query Vpcs[].VpcId --output text)

#Key-pairs

#EC2 DETAILS
AMI=$(aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id --query 'Parameters[*].[Value]' --output text)
COUNT=1
INSTANCE_TYPE="t2.micro"
KEY_NAME="ec2-kp"
SUBNET_ID="subnet-0a8a6e012d998ba6c"
TAG='ResourceType=instance,Tags=[{Key=Name,Value=UbuntuServer}]'
SECURITY_GROUP="ec2-sg"


aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_DEFAULT_REGION

echo "Creating key-pairs..."
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-type rsa \
    --query "KeyMaterial" \
    --output text 1> $KEY_NAME.pem 2> /dev/null || echo "The keypair $KEY_NAME already exists."

echo "Creating Security Groups..."
aws ec2 create-security-group \
	--group-name $SECURITY_GROUP \
	--description "My EC2 security group" \
	--vpc-id $DEFAULT_VPC &> /dev/null || echo "The keypair $SECURITY_GROUP already exists."

aws ec2 authorize-security-group-ingress \
	--group-name $SECURITY_GROUP \
	--protocol tcp \
	--port 80 \
	--cidr 0.0.0.0/0 &> /dev/null

aws ec2 authorize-security-group-ingress \
	--group-name $SECURITY_GROUP \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0 &> /dev/null

SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
	--filters "Name=group-name,Values=$SECURITY_GROUP" "Name=vpc-id,Values=$DEFAULT_VPC" \
	--query "SecurityGroups[*].[GroupId]" \
	--output text)

echo "Launching EC2...."
aws ec2 run-instances \
	--image-id $AMI \
	--count $COUNT \
	--instance-type $INSTANCE_TYPE \
	--key-name $KEY_NAME \
	--security-group-ids $SECURITY_GROUP_ID \
	--subnet-id $SUBNET_ID \
	--tag-specifications $TAG \
	--user-data file://user_data.txt
