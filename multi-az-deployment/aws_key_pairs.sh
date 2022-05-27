#!/bin/bash
KEY_NAME=$1
REGION=$2

#aws ec2 create-key-pair --key-name MyKeyPair

aws ec2 create-key-pair \
    --region $REGION \
    --key-name $KEY_NAME \
    --key-type rsa \
    --query "KeyMaterial" \
    --output text 1> $KEY_NAME.pem 2> /dev/null || echo "The keypair $KEY_NAME already exists."



command -option aa \
    dfsdfds \
    dfsdfsdfdsfs     