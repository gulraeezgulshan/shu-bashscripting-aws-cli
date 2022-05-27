#!/bin/bash

echo "Getting Credential Details from SSM..."
AWS_ACCESS_KEY_ID=$(aws --region=us-east-1 ssm get-parameter --name "______" --with-decryption --output text --query Parameter.Value)
AWS_SECRET_ACCESS_KEY=$(aws --region=us-east-1 ssm get-parameter --name "______" --with-decryption --output text --query Parameter.Value)
AWS_DEFAULT_REGION=us-east-1

echo "Configuring aws locally..."
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_DEFAULT_REGION