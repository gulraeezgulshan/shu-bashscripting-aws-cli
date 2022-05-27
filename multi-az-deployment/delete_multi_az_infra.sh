#!/bin/bash

ROOT_UID=0     
E_NOTROOT=100
DEFAULT_REGION=us-east-1
KEY_PAIRS="project-kp"
SG_ELB="elb-sg"
SG_EC2="ec2-sg"
PROJECT_TAG="multi-az"
EC2_TAG="UbuntuServer"
TG_NAME="elb-tg"
ELB_NAME="elb"

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
echo

# terminate ec2 instances

echo "Deleting EC2 instances...."
EC2_IDS=$(cat ec2_targets.txt | paste -sd " " -)
[[ -z $EC2_IDS ]] && echo "EC2 instances does not exsists" || aws ec2 terminate-instances --instance-ids $EC2_IDS &> /dev/null && echo "" > ec2_targets.txt

echo
echo "Deleting key-pairs..."
aws ec2 delete-key-pair --key-name $KEY_PAIRS &> /dev/null || echo "$KEY_PAIRS does not exsists"

echo
echo "Deleting EC2 Security Group..."
SG_EC2_ID=$(aws ec2 describe-security-groups \
	--filters "Name=group-name,Values=$SG_EC2" "Name=vpc-id,Values=$DEFAULT_VPC" \
	--query "SecurityGroups[*].[GroupId]" \
	--output text)

[[ -z $SG_EC2_ID ]] && echo "$SG_EC2 does not exsists" || aws ec2 delete-security-group --group-id $SG_EC2_ID &> /dev/null

echo
echo "Deleting ELB Security Group..."
SG_ELB_ID=$(aws ec2 describe-security-groups \
	--filters "Name=group-name,Values=$SG_ELB" "Name=vpc-id,Values=$DEFAULT_VPC" \
	--query "SecurityGroups[*].[GroupId]" \
	--output text)

[[ -z $SG_ELB_ID ]] && echo "$SG_ELB does not exsists" || aws ec2 delete-security-group --group-id $SG_ELB_ID &> /dev/null 


echo
echo "Deleting ELB Listener"

ELB_ARN=$(aws elbv2 describe-load-balancers --name $ELB_NAME --query LoadBalancers[].LoadBalancerArn --output text 2> /dev/null)
ELB_LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ELB_ARN --query Listeners[].ListenerArn --output text 2> /dev/null)

[[ -z $ELB_LISTENER_ARN ]] && echo "Listener does not exsists" || aws elbv2 delete-listener --listener-arn $ELB_LISTENER_ARN
echo

echo "Deleting load balancer..."
[[ -z $ELB_ARN ]] && echo "$ELB_NAME does not exsists" || aws elbv2 delete-load-balancer --load-balancer-arn $ELB_ARN

echo
echo "Deleting target group..."
TG_ARN=$(aws elbv2 describe-target-groups --names $TG_NAME --query TargetGroups[].TargetGroupArn --output text 2> /dev/null)
[[ -z $TG_ARN ]] && echo "$TG_NAME does not exsists" || aws elbv2 delete-target-group --target-group-arn $TG_ARN

echo
echo "*****The multi-az infrastructure has been successfully DELETED*****"
echo


