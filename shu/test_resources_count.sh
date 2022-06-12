#!/bin/bash

file=students_list_complete.txt

BLUE="\e[1;34m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
CE="\e[m"

CHECK="\xE2\x9C\x85"
CROSS="\xE2\x9D\x8C"
STAR="\xE2\xAD\x90"
CLOCK="\xE2\x8F\xB0"

EC2_D=0
KP_D=0
SG_D=0
ELB_D=0
TG_D=0
S3_D=0
CF_D=0
PL_D=0

i=0

figlet SHU CS

echo -e "\n$CLOCK$CLOCK$CLOCK TESTING FOR NUMBER OF RESOURCES IN STUDENT'S AWS ACCOUNTS ON $RED$(date +%d-%b-%Y)$CE AT $RED$(date "+%I:%M %p")$CE $CLOCK$CLOCK$CLOCK \n"

printf "\
[%3s]: $BLUE%-20s$CE\
[%3s]: $BLUE%-20s$CE\
[%3s]: $BLUE%-20s$CE\
[%3s]: $BLUE%-20s$CE\n\
[%3s]: $BLUE%-20s$CE\
[%3s]: $BLUE%-20s$CE\
[%3s]: $BLUE%-20s$CE\
[%3s]: $BLUE%-20s$CE\n\n" \
"EC2" "Elastic Compute" \
"SG" "Security Groups" \
"KP" "Key Pairs" \
"ELB" "Elastic Load Balancer" \
"TG" "Target Groups" \
"S3" "S3 Bucket" \
"CF" "CloudFront" \
"PL" "CodePipeline"

function CHECK_CROSS () {
    [[ $1 -eq $2 ]] && echo -e "$CHECK" || echo -e "$CROSS"
}
i=0
while IFS= read -r line || [ -n "$line" ]
do
  id=$(echo $line | awk -F ':' '{print $1}')
  name=$(echo $line | awk -F ':' '{print $2}')

  EC2_COUNT=$(aws ec2 describe-instances \
                  --profile $id \
                  --filters "Name=instance-type,Values=t2.micro" \
                  --query "Reservations[*].Instances[*].[InstanceId]" \
                  --output text | wc -l)
  
  SG_NONDEFAULT=$(sudo aws ec2 describe-security-groups \
                    --profile $id \
                    --query "SecurityGroups[*].{Name:GroupName}" \
                    --output text | grep -vw "default" | tr '\n' ',' | sed 's/\(.*\),/\1 /')

  SG_COUNT=$(aws ec2 describe-security-groups \
              --profile $id \
              --filters "Name=group-name,Values=$SG_NONDEFAULT" \
              --query "SecurityGroups[*].{Name:GroupName}"  --output text | wc -l)

  KP_COUNT=$(aws ec2 describe-key-pairs \
                  --profile $id \
                  --query "KeyPairs[].[KeyPairId]" \
                  --output text | wc -l)

  ELB_COUNT=$(aws elbv2 describe-load-balancers \
                  --profile $id \
                  --query "LoadBalancers[*].[LoadBalancerName]" \
                  --output text | wc -l)

  TG_COUNT=$(aws elbv2 describe-target-groups \
                  --profile $id \
                  --query "TargetGroups[*].[TargetGroupName]" \
                  --output text | wc -l)

  S3_COUNT=$(aws s3 ls --profile $id | wc -l)
  
  CF_LIST=$(aws cloudfront list-distributions \
                  --profile $id \
                  --query "DistributionList.Items[*].[Id]" \
                  --output text)
  
  if [[ $CF_LIST == None ]]
  then
    CF_COUNT=0
  else
    CF_COUNT=$(echo $CF_LIST | wc -l)
  fi
            
  PL_COUNT=$(aws codepipeline list-pipelines \
                  --profile $id \
                  --query "pipelines[*].[name]" \
                  --output text | wc -l)

  printf "%02d.\
  %-30s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  | %s:$YELLOW(%02d)$CE %s\
  |\n" \
          "$((($i+1)))"\
          "$name"\
          "EC2" $EC2_COUNT $(CHECK_CROSS "$EC2_COUNT" "EC_D")\
          "KP" $KP_COUNT $(CHECK_CROSS "$KP_COUNT" "KP_D")\
          "SG" $SG_COUNT $(CHECK_CROSS "$SG_COUNT" "SG_D")\
          "ELB" $ELB_COUNT $(CHECK_CROSS "$ELB_COUNT" "ELB_D")\
          "TG" $TG_COUNT $(CHECK_CROSS "$TG_COUNT" "TG_D")\
          "S3" $S3_COUNT $(CHECK_CROSS "$S3_COUNT" "S3_D")\
          "CF" $CF_COUNT $(CHECK_CROSS "$CF_COUNT" "CF_D")\
          "PL" $PL_COUNT $(CHECK_CROSS "$PL_COUNT" "PL_D")
  ((i++))
done <$file
echo -e "\n"