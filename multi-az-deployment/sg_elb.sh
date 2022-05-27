#!/bin/bash

SG_NAME=$1
VPC=$2

aws ec2 create-security-group \
	--group-name $SG_NAME \
	--description "Allow http access to Elastic Load Balancer" \
	--vpc-id $VPC &> /dev/null || echo "The security group $SG_NAME already exists."

aws ec2 authorize-security-group-ingress \
	--group-name $SG_NAME \
	--protocol tcp \
	--port 80 \
	--cidr 0.0.0.0/0 &> /dev/null
