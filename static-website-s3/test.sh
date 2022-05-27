#!/bin/bash

# aws elbv2 create-target-group \
#     --name testing \
#     --protocol HTTP \
#     --port 80 \
#     --target-type instance \
#     --vpc-id vpc-0dabbe7ce5c98d079

# aws elbv2 describe-target-groups --names testing --query TargetGroups[].TargetGroupArn --output text

# aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro" "Name=tag:Project,Values=multi-az" \
#     --query "Reservations[*].Instances[*].[InstanceId]" \
#     --output text


#  echo 'hi'
#  sleep 5
#  echo 'hi'

#cat ec2_targets.txt | awk '{print "Id="$1}' | paste -sd " " -

#cat subnets.txt | awk '{print $2}' | paste -sd " " -
# ELB_NAME=elb

# ELB_ARN=$(aws elbv2 describe-load-balancers --name $ELB_NAME --query LoadBalancers[].[LoadBalancerArn,DNSName] --output text | awk '{print $1}')
# ELB_DNS=$(aws elbv2 describe-load-balancers --name $ELB_NAME --query LoadBalancers[].[LoadBalancerArn,DNSName] --output text | awk '{print $2}')

# echo $ELB_ARN
# echo $ELB_DNS


# EC2_IDS=EC2_TARGETS=$(cat ec2_targets.txt | paste -sd " " -)
# echo $EC2_IDS


# aws elbv2 describe-listeners --load-balancer-arn arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188

# print_something () {
#     local a=85
#     echo Hello $1
#     return 5
# }

# ls () {
#     command ls -ltr
# }

# ls

#S3_BUCKET_NAME=website-s3-03457847091
# aws s3 website s3://$S3_BUCKET_NAME/ --index-document index.html

#aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy file://bucket_policy.json

#aws codestar-connections create-connection --provider-type GitHub --connection-name GullConnection

#aws codepipeline get-pipeline --name sample-pl

#aws codepipeline create-pipeline --cli-input-json file://pipeline.json

#aws cloudfront get-distribution-config --id ECDPEZZGG6I0X > cf_dist.json

#aws cloudfront create-distribution --distribution-config file://cf_dist.json



