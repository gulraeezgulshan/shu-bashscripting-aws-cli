#!/bin/bash

S3_BUCKET_NAME=$(source get_config.sh S3_BUCKET_NAME | tr -d '"')
DEFAULT_REGION=$(source get_config.sh DEFAULT_REGION | tr -d '"')
S3_DEFAULT_PAGE=$(source get_config.sh S3_DEFAULT_PAGE)

echo -e "\nCreating Amazon S3 Bucket [$S3_BUCKET_NAME]"
aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $DEFAULT_REGION &> /dev/null

echo -e "\nUnblocking Public Access to S3 Bucket..."
aws s3api put-public-access-block \
    --bucket $S3_BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

echo -e "\nEnabling S3 Bucket to host Static Website..."
aws s3 website s3://$S3_BUCKET_NAME/ --index-document $S3_DEFAULT_PAGE

which jq &> /dev/null || apt install jq

jq '.Statement[0].Resource[]="arn:aws:s3:::'"$S3_BUCKET_NAME"'/*"' bucket_policy.template.json > tmp 
mv tmp bucket_policy.json
[[ -e tmp ]] && rm tmp

echo -e "\nAttaching Bucket Policy to S3 Bucket..."
aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy file://bucket_policy.json