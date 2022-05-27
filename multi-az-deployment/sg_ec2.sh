#!/bin/bash

SG_NAME=$1
VPC=$2
SG_SOURCE=$3

aws ec2 create-security-group \
	--group-name $SG_NAME \
	--description "My ssh and http access to ec2 instances" \
	--vpc-id $VPC &> /dev/null || echo "The security group $SG_NAME already exists."

aws ec2 authorize-security-group-ingress \
	--group-name $SG_NAME \
	--protocol tcp \
	--port 80 \
	--source-group $SG_SOURCE  &> /dev/null

aws ec2 authorize-security-group-ingress \
	--group-name $SG_NAME \
	--protocol tcp \
	--port 22 \
	--cidr 0.0.0.0/0 &> /dev/null