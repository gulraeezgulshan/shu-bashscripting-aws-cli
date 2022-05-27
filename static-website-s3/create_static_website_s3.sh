#!/bin/bash

#!/bin/bash

ROOT_UID=0     
E_NOTROOT=100
DEFAULT_REGION=us-east-1
S3_BUCKET_NAME=website-s3-03457847091
CODE_PL_NAME=website-pl

#Must be a root user to run this script
if [ "$UID" -ne "$ROOT_UID" ]
    then
        echo "Must be root to run this script."
        exit $E_NOTROOT
fi 

echo "Checking for aws-cli..."
source aws_cli.sh
echo

echo "Checking for aws-credentials..."
source aws_credentials.sh
echo

echo "Getting VPC details..."
DEFAULT_VPC=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query Vpcs[].VpcId --output text --region $DEFAULT_REGION)


#Create S3 Bucket 
echo
echo "Creating S3 Bucket..."
aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $DEFAULT_REGION &> /dev/null

# Unblock public access to S3 Bucket
echo
echo "Unblocking Public Access to S3 Bucket..."
aws s3api put-public-access-block \
    --bucket $S3_BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Enable S3 bucket to host Static Website
echo
echo "Enabling S3 Bucket to host Static Website..."
aws s3 website s3://$S3_BUCKET_NAME/ --index-document index.html

# Attach bukcet policy
echo
echo "Attaching Bucket policy to S3 Bucket..."
aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy file://bucket_policy.json

echo
echo "Waiting 15 secs to provision resources..."
sleep 15

#Create CodePipeline
echo 
echo "Creating CodePipeline..."
aws codepipeline create-pipeline --cli-input-json file://pipeline.json &> /dev/null


#Create CloudFront
echo 
echo "Creating CloudFront..."
aws cloudfront create-distribution --distribution-config file://cf_dist.json
