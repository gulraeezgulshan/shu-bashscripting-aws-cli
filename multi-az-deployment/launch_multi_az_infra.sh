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


echo "Getting Subnet details..."
aws ec2 describe-subnets --query Subnets[].[AvailabilityZone,SubnetId] --output text --region $DEFAULT_REGION > subnets.txt
echo

echo "Creating key pairs..."
source aws_key_pairs.sh $KEY_PAIRS $DEFAULT_REGION
echo

echo "Creating security groups for Elastic Load Balancer"
source sg_elb.sh $SG_ELB $DEFAULT_VPC 
echo 

echo "Creating security groups for EC2 Instances"
source sg_ec2.sh $SG_EC2 $DEFAULT_VPC $SG_ELB
echo 

#EC2 Details
AMI=$(aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id --query 'Parameters[*].[Value]' --output text)
INSTANCE_TYPE="t2.micro"

SG_EC2_ID=$(aws ec2 describe-security-groups \
	--filters "Name=group-name,Values=$SG_EC2" "Name=vpc-id,Values=$DEFAULT_VPC" \
	--query "SecurityGroups[*].[GroupId]" \
	--output text)

i=1
while read -r line; do
	SUBNET_ID=$(echo $line | awk '{print $2}')

	echo "Launching EC2#$i..."
	aws ec2 run-instances \
	--image-id $AMI \
	--count 1 \
	--instance-type $INSTANCE_TYPE \
	--key-name $KEY_PAIRS \
	--security-group-ids $SG_EC2_ID \
	--subnet-id $SUBNET_ID \
	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_TAG-0$i},{Key=Project,Value=$PROJECT_TAG}]" \
	--user-data file://user_data.txt &> /dev/null

	#break loop after reading first three lines
    ((i++))
    if [[ "$i" == '4' ]]; then
        break
    fi
done < subnets.txt

echo
echo 'waiting 90 secs for EC2 provisioning...'
sleep 90

###### Creating Target Group
echo
echo "Creating Targing group..."
aws elbv2 create-target-group \
    --name $TG_NAME \
    --protocol HTTP \
    --port 80 \
    --target-type instance \
    --vpc-id $DEFAULT_VPC &> /dev/null

sleep 5
#Target Group ARN
TG_ARN=$(aws elbv2 describe-target-groups --names $TG_NAME --query TargetGroups[].TargetGroupArn --output text)

#Target IDs
aws ec2 describe-instances \
	--filters "Name=instance-type,Values=$INSTANCE_TYPE" "Name=tag:Project,Values=$PROJECT_TAG" "Name=instance-state-name,Values=running"\
    --query "Reservations[*].Instances[*].[InstanceId]" \
    --output text > ec2_targets.txt

#cat ec2_targets.txt | paste -s -d " " (past multiple lines into one with space as delim)

#Format as Id=<Instance Id>
EC2_TARGETS=$(cat ec2_targets.txt | awk '{print "Id="$1}' | paste -sd " " -)

###### Registering Targets
echo
echo "Registering EC2 targets..."
aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets $EC2_TARGETS

### Creating load balancer

ELB_SUBNETS=$(cat subnets.txt | awk '{print $2}' | paste -sd " " -)

SG_ELB_ID=$(aws ec2 describe-security-groups \
	--filters "Name=group-name,Values=$SG_ELB" "Name=vpc-id,Values=$DEFAULT_VPC" \
	--query "SecurityGroups[*].[GroupId]" \
	--output text)

aws elbv2 create-load-balancer \
    --name $ELB_NAME \
    --type application \
    --subnets $ELB_SUBNETS \
    --security-groups $SG_ELB_ID &> /dev/null  || echo "Load balancer $ELB_NAME already exsists"

echo 'Waiting 15 secs for ELB Provisioning...'
echo

ELB_ARN=$(aws elbv2 describe-load-balancers --name $ELB_NAME --query LoadBalancers[].[LoadBalancerArn,DNSName] --output text | awk '{print $1}')
ELB_DNS=$(aws elbv2 describe-load-balancers --name $ELB_NAME --query LoadBalancers[].[LoadBalancerArn,DNSName] --output text | awk '{print $2}')

echo 'Creating ELB Listerners...'
aws elbv2 create-listener \
    --load-balancer-arn $ELB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN &> /dev/null 

echo
echo "*****The multi-az infrastructure has been successfully deployed*****"
echo
echo "Open the Load Balancer DNS http://$ELB_DNS on browser to verify"



