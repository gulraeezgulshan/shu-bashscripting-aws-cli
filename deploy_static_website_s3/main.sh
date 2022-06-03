#!/bin/bash

echo -e "\n"
echo -e "\033[0;35m*****Checking for Root User Rights*****\033[0m"
source ./check_for_root.sh

echo -e "\n"
echo -e "\033[0;35m*****Checking for AWS CLI*****\033[0m"
source ./install_aws_cli.sh

echo -e "\n"
echo -e "\033[0;35m*****Checking for AWS Credentials*****\033[0m"
source ./aws_credentials.sh

echo -e "\n"
echo -e "\033[0;35m*****Checking for GitHub CLI*****\033[0m"
source ./install_gh_cli.sh


echo -e "\n"
echo -e "\033[0;35m*****Extracting Folder in HTML*****\033[0m"
source ./extract_project.sh


echo -e "\n"
echo -e "\033[0;35m*****Creating Local and Remote Repository*****\033[0m"
source ./create_github_repo.sh

echo -e "\n"
echo -e "\033[0;35m*****Creating Amazon S3 Bucket*****\033[0m"
source ./create_s3_bucket.sh

echo -e "\n"
echo -e "\033[0;35m*****Creating Amazon CodePipeline*****\033[0m"
source ./create_codepipeline.sh

echo -e "\n"
echo -e "\033[0;35m*****Creating CloudFront Distribution*****\033[0m"
source ./create_cloudfront_dist.sh

echo -e "\n"
echo -e "\033[0;35m*****Creating Route53 Record Sets*****\033[0m"
source ./create_route_53_records.sh




