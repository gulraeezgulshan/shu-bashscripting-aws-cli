#!/bin/bash
#Created by: Engr. Gulraeez Gulshan

BLUE="\e[1;34m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
GREEN="\e[1;32m"
CE="\e[m"

CHECK="\xE2\x9C\x85"
CROSS="\xE2\x9D\x8C"
WAIT="\xE2\x8C\x9B"
TEST="\xE2\x9C\x94"
CLOCK="\xE2\x8F\xB0"


EC2=("nginx-server-us-east-1-01" "nginx-server-us-east-1-02" "nginx-server-us-east-1-03" "Bastion Host")
EC2_SG=("nginx-server-us-east-1-sg" "nginx-server-us-east-1-sg" "nginx-server-us-east-1-sg" "ssh-only-sg")
EC2_AZ=("us-east-1a" "us-east-1b" "us-east-1c" "us-east-1d" )
ALL_SG=("nginx-server-us-east-1-sg" "alb-us-east-1-sg" "ssh-only-sg")
SG_PORTS=("80 22" "80" "22")
ELB="alb-us-east-1-01"
ELB_AZS="us-east-1a us-east-1b us-east-1c"
TG_ELB_NAME="tg-us-east-1-01"
TG_ELB_PROTO="HTTP"
PL_NAME="website-s3-pl"

INS_TYPE="t2.micro"

function line(){
   echo -n "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
}

function hash(){
   echo -n "######################################################################################################################################################################################"
}

file=students_list_complete.txt
#file=gulraiz-ro.txt

j=0
while IFS= read -r line || [ -n "$line" ]
do
   id=$(echo $line | awk -F ':' '{print $1}')
   name=$(echo $line | awk -F ':' '{print $2}')
 
   file_name="$id-$name.txt"
   echo -e "\n$WAIT$WAIT$WAIT RUNNING SCRIPTS TO CHECK $YELLOW ("$((j+1))") $name's $CE TASKS ON $RED$(date +%d-%b-%Y)$CE AT $RED$(date "+%I:%M %p")$CE $WAIT$WAIT$WAIT"

   which jq &> /dev/null || sudo apt install jq -y
   line
   echo -e "\n$CLOCK $GREEN 1) TESTING EC2 INSTANCE $CE $CLOCK"
   line
   printf "\n$BLUE%-30s | %-2s | %-2s | %-19s | %-18s | %-30s | %-25s$CE\n" "Instance Name" "E" "R" "KeyName" "AZone" "IsSecurityGroup" "IsAccessible"
   for i in 0 1 2 3
   do
      EC2_NGINX=$(aws ec2 describe-instances --profile $id \
                     --filters \
                     "Name=instance-type,Values=$INS_TYPE" \
                     "Name=tag-value,Values=${EC2[$i]}" | jq '[.Reservations[].Instances[] | {InstanceId,KeyName,Placement:.Placement.AvailabilityZone,PublicDnsName,PublicIpAddress,State:.State.Name,SecurityGroups:.SecurityGroups[].GroupName, Name:.Tags[].Value}] ')
      
      if [[ "$EC2_NGINX" == [] ]]
      then
         EXIST=$(echo -e "$CROSS")
         RUNNING=$(echo -e "$CROSS")
         KEYPAIR=$(echo -e "$CROSS")
         PLACEMENT=$(echo -e "$CROSS")
         ACCESS=$(echo -e "$CROSS")
         SGROUP=$(echo -e "$CROSS")
      else
         EXIST=$(echo -e $CHECK)
         STATE=$(echo $EC2_NGINX | jq -r '(.[] | {State}).State')
         [[ $STATE == "running" ]] && RUNNING=$(echo -e $CHECK) || RUNNING=$(echo -e $CROSS)
         
         KEYNAME=$(echo $EC2_NGINX | jq -r '(.[] | {KeyName}).KeyName')
         [[ $KEYNAME == "$id-kp" ]] && KEYPAIR=$(echo -e $KEYNAME $CHECK) || KEYPAIR=$(echo -e $KEYNAME $CROSS)

         AZ=$(echo $EC2_NGINX | jq -r '(.[] | {Placement}).Placement')
         [[ $AZ == "${EC2_AZ[$i]}" ]] && PLACEMENT=$(echo -e $AZ $CHECK) || PLACEMENT=$(echo -e $AZ $CROSS)

         SG=$(echo $EC2_NGINX | jq -r '(.[] | {SecurityGroups}).SecurityGroups')
         [[ $SG == "${EC2_SG[$i]}" ]] && SGROUP=$(echo -e $SG $CHECK) || SGROUP=$(echo -e $SG $CROSS)

         IP=$(echo $EC2_NGINX | jq '(.[] | {PublicIpAddress}).PublicIpAddress' | tr -d '"')
         curl -sf -m 3 http://$IP > /dev/null 
         [[ $IP == null ]] && IP=0.0.0.0
         [[ $? -eq 0 ]] && ACCESS=$(echo -e "http://$IP" $CROSS) || ACCESS=$(echo -e "http://$IP" $CHECK)

      fi

      printf \
      "$YELLOW%-30s$CE | %-2s | %-2s | %-20s | %-20s | %-30s | %-25s\n"\
      "$((($i+1))). ${EC2[$i]}"\
      "$EXIST"\
      "$RUNNING"\
      "$KEYPAIR"\
      "$PLACEMENT"\
      "$SGROUP"\
      "$ACCESS"
   done 
   
   line
   echo -e "\n$CLOCK $GREEN 2) TESTING SECURITY GROUPS $CE $CLOCK"
   line
   
   SG_ID_ELB=$(aws ec2 describe-security-groups --profile $id \
                     --filters "Name=group-name,Values=${ALL_SG[1]}" \
                     | jq -r '(.SecurityGroups[] | {GroupId}).GroupId') #if error remove -r
   
   SG_ID=("$SG_ID_ELB" "")

   printf "\n$BLUE%-30s | %-2s | %-14s | %-29s$CE\n" "Security Group Name" "E" "Inbound Ports" "Dependent Security Group"
   
   for i in 0 1 2
   do
      SG_LIST=$(aws ec2 describe-security-groups --profile $id \
                  --filters "Name=group-name,Values=${ALL_SG[$i]}" \
                  | jq '.SecurityGroups[] | {GroupId,GroupName,IpPermissionsIp:[.IpPermissions[].FromPort], GroupPairId: [.IpPermissions[].UserIdGroupPairs[].GroupId]}')
   
      PORTS=$(echo $SG_LIST | jq -rc '(. | {IpPermissionsIp}).IpPermissionsIp[]')
      GROUP_SG=$(echo $SG_LIST | jq -r '(. | {GroupPairId}).GroupPairId[]')


      if [[ "$SG_LIST" == [] || -z "$SG_LIST" ]]
      then
         EXIST=$(echo -e "$CROSS")
         PORTS_TEST=$(echo -e "$CROSS")
         GROUP_SG_TEST=$(echo -e "$CROSS")
      else
         EXIST=$(echo -e "$CHECK")
         [[ $(echo $PORTS) == "${SG_PORTS[$i]}" ]] && PORTS_TEST=$(echo -e $PORTS $CHECK) || PORTS_TEST=$(echo -e $PORTS $CROSS)
         [[ "$GROUP_SG" == "${SG_ID[$i]}" ]] && GROUP_SG_TEST=$(echo -e $GROUP_SG $CHECK) || GROUP_SG_TEST=$(echo -e $GROUP_SG $CROSS)
      fi

      printf "$YELLOW%-30s$CE | %-2s | %-15s | %-30s\n" "$((($i+1))). ${ALL_SG[$i]}" "$EXIST" "$PORTS_TEST" "$GROUP_SG_TEST"
   done
   line
   echo -e "\n$CLOCK $GREEN 3) TESTING ELASTIC LOAD BALANCER $CE $CLOCK"
   line
   ELB_LIST=$(aws elbv2 describe-load-balancers --profile $id \
                  --names $ELB 2> /dev/null\
                  | jq '.LoadBalancers[] | {LoadBalancerName,DNSName, State: .State.Code, SecurityGroups: .SecurityGroups[], AvailabilityZones: [.AvailabilityZones[].ZoneName]}') 
   
 
   if [[ -z $ELB_LIST ]] 
   then
      ELB_EXIST=$(echo -e "$CROSS")
      ELB_STATE_TEST=$(echo -e "$CROSS")
      SG_ELB_TEST=$(echo -e "$CROSS")
      ELB_AZS_TEST=$(echo -e "$CROSS")
      ELB_DNS_ACCESS=$(echo -e "$CROSS")
   else
      ELB_EXIST=$(echo -e $CHECK)

      ELB_STATE=$(echo $ELB_LIST | jq -r '(. | {State}).State') 
      [[ $ELB_STATE == "active" ]] && ELB_STATE_TEST=$(echo -e $CHECK) || ELB_STATE_TEST=$(echo -e $CROSS)

      SG_ELB_ID=$(echo $ELB_LIST | jq -r '(. | {SecurityGroups}).SecurityGroups')
      [[ $SG_ELB_ID == $SG_ID_ELB ]] && SG_ELB_TEST=$(echo -e $SG_ELB_ID $CHECK) || SG_ELB_TEST=$(echo -e $SG_ELB_ID $CROSS)
      
      ELB_AZS_LIST=$(echo $ELB_LIST | jq -rc '(. | {AvailabilityZones}).AvailabilityZones[]' | sort)
      [[ $(echo $ELB_AZS_LIST) == "$ELB_AZS" ]] && ELB_AZS_TEST=$(echo -e $ELB_AZS_LIST $CHECK) || ELB_AZS_TEST=$(echo -e $ELB_AZS_LIST $CROSS)

      ELB_DNS=$(echo $ELB_LIST | jq -rc '(. | {DNSName}).DNSName')
      curl -sf -m 3 http://$ELB_DNS > /dev/null
      [[ $? -eq 0 ]] && ELB_DNS_ACCESS=$(echo -e "http://$ELB_DNS" $CHECK) || ELB_DNS_ACCESS=$(echo -e "http://$ELB_DNS" $CROSS)
   fi

   printf "\n$BLUE%-20s | %-2s | %-2s | %-24s | %-35s | %s$CE" "Load Balancer Name" "E" "A" "Security Group" "ELB Availibility Zones" "ELB DNS Accessibility Test"
   printf "\n$YELLOW%-20s$CE | %-2s | %-2s | %-25s | %-35s | %s\n" "1. $ELB" "$ELB_EXIST" "$ELB_STATE_TEST" "$SG_ELB_TEST" "$ELB_AZS_TEST" "$ELB_DNS_ACCESS"
   
   line
   echo -e "\n$CLOCK $GREEN 4) TESTING TARGET GROUPS $CE $CLOCK"
   line

   TG_ELB_LIST=$(aws elbv2 describe-target-groups --profile $id \
                     --names $TG_ELB_NAME 2> /dev/null \
                     | jq '.TargetGroups[] | {TargetGroupName,Protocol,HealthCheckProtocol,HealthCheckPath,LoadBalancer:.LoadBalancerArns[], TargetType}')
   
   if [[ -z $TG_ELB_LIST ]]
   then
      TG_ELB_EXIST=$(echo -e $CROSS)
      ELB_PROTO_NAME_TEST=$(echo -e $CROSS)
      ELB_HEALTH_CHECK_TEST=$(echo -e $ELB_HEALTH_CHECK $CROSS)
      ELB_HEALTH_CHECK_PATH_TEST=$(echo -e $ELB_HEALTH_CHECK $CROSS)
      TG_ELB_NAME_ATT_TEST=$(echo -e $ELB_HEALTH_CHECK $CROSS)
   else
      TG_ELB_EXIST=$(echo -e $CHECK)

      ELB_PROTO_NAME=$(echo $TG_ELB_LIST | jq -r '(. | {Protocol}).Protocol')
      [[ $ELB_PROTO_NAME == "HTTP" ]] && ELB_PROTO_NAME_TEST=$(echo -e $ELB_PROTO_NAME $CHECK) || ELB_PROTO_NAME_TEST=$(echo -e $ELB_PROTO_NAME $CROSS)

      ELB_HEALTH_CHECK_PROTO=$(echo $TG_ELB_LIST | jq -r '(. | {HealthCheckProtocol}).HealthCheckProtocol')
      [[ $ELB_HEALTH_CHECK_PROTO == "HTTP" ]] && ELB_HEALTH_CHECK_TEST=$(echo -e $ELB_HEALTH_CHECK_PROTO $ELB_HEALTH_CHECK $CHECK) || ELB_HEALTH_CHECK_TEST=$(echo -e $ELB_HEALTH_CHECK_PROTO $CROSS)

      ELB_HEALTH_CHECK_PATH=$(echo $TG_ELB_LIST | jq -r '(. | {HealthCheckPath}).HealthCheckPath')
      [[ $ELB_HEALTH_CHECK_PATH == "/" ]] && ELB_HEALTH_CHECK_PATH_TEST=$(echo -e $ELB_HEALTH_CHECK_PATH $ELB_HEALTH_CHECK $CHECK) || ELB_HEALTH_CHECK_PATH_TEST=$(echo -e $ELB_HEALTH_CHECK_PATH $CROSS)
   
      TG_ELB_NAME_ATT=$(echo $TG_ELB_LIST | jq -r '(. | {LoadBalancer}).LoadBalancer' | awk -F ':' '{print $6}' | awk -F '/' '{print $3}')
      [[ $TG_ELB_NAME_ATT == "$ELB" ]] && TG_ELB_NAME_ATT_TEST=$(echo -e $TG_ELB_NAME_ATT $CHECK) || TG_ELB_NAME_ATT_TEST=$(echo -e $TG_ELB_NAME_ATT $CROSS)
   fi

   printf "\n$BLUE%-20s | %-2s | %-9s | %-14s | %-9s | %s$CE" "Target Group Name" "E" "Protocol" "Health Proto" "PATH" "Attached ELB"
   printf "\n$YELLOW%-20s$CE | %-2s | %-10s | %-15s | %-10s | %s\n" "1. $TG_ELB_NAME" "$TG_ELB_EXIST" "$ELB_PROTO_NAME_TEST" "$ELB_HEALTH_CHECK_TEST" "$ELB_HEALTH_CHECK_PATH_TEST" "$TG_ELB_NAME_ATT_TEST"

   line
   echo -e "\n$CLOCK $GREEN 5) TESTING AMAZON S3 BUCKETS $CE $CLOCK"
   line

   S3_BUCKET_NAME="website-s3-$(echo $id | tr '[:upper:]' '[:lower:]')"
   S3_BUCKET=$(aws s3 ls --profile $id | grep -w "$S3_BUCKET_NAME")

   if [[ -z $S3_BUCKET ]]
   then
      S3_EXIST=$(echo -e $CROSS)
      S3_BUCKET_POLICY_EXIST=$(echo -e $CROSS)
      S3_BUCKET_OBJECTS_EXIST=$(echo -e $CROSS)
      S3_SITE_EN_TEST=$(echo -e $CROSS)
      S3_POLICY_STATUS_TEST=$(echo -e $CROSS)
      S3_BUCKET_EP_URL_ACCESS=$(echo -e $CROSS)
   else
      S3_EXIST=$(echo -e $CHECK)
      
      S3_BUCKET_POLICY=$(aws s3api get-bucket-policy --bucket $S3_BUCKET_NAME --output text --profile $id 2> /dev/null)
      [[ -z $(echo $S3_BUCKET_POLICY) ]] && S3_BUCKET_POLICY_EXIST=$(echo -e $CROSS) || S3_BUCKET_POLICY_EXIST=$(echo -e $CHECK)

      S3_OBJECTS=$(aws s3api list-objects --bucket $S3_BUCKET_NAME --query 'Contents[].{Key: Key}' --output text --profile $id)
      
      [[ $(echo "$S3_OBJECTS") == None ]] && S3_OBJECTS_COUNT=0 || S3_OBJECTS_COUNT=$(echo "$S3_OBJECTS" | wc -l)
      [[ S3_OBJECTS_COUNT -ne 0 ]] && S3_BUCKET_OBJECTS_EXIST=$(echo -e $S3_OBJECTS_COUNT $CHECK) || S3_BUCKET_OBJECTS_EXIST=$(echo -e $S3_OBJECTS_COUNT $CROSS)

      S3_SITE_EN=$(aws s3api get-bucket-website --bucket $S3_BUCKET_NAME --profile $id 2> /dev/null | jq -rc '(. | {IndexDocument: .IndexDocument.Suffix}).IndexDocument')
      [[ "$S3_SITE_EN" == "index.html" ]] && S3_SITE_EN_TEST=$(echo -e $S3_SITE_EN $CHECK) || S3_SITE_EN_TEST=$(echo -e $S3_SITE_EN $CROSS)

      S3_POLICY_STATUS=$(aws s3api get-bucket-policy-status --bucket $S3_BUCKET_NAME --profile $id 2> /dev/null | jq '(. | {PolicyStatus: .PolicyStatus.IsPublic}).PolicyStatus')
      [[ "$S3_POLICY_STATUS" == "true" ]] && S3_POLICY_STATUS_TEST=$(echo -e "Public" $CROSS) || S3_POLICY_STATUS_TEST=$(echo -e "No" $CHECK) 

      S3_BUCKET_EP_URL="http://$S3_BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
      curl -sf -m 3 $S3_BUCKET_EP_URL > /dev/null
      [[ $? -eq 0 ]] && S3_BUCKET_EP_URL_ACCESS=$(echo -e "$S3_BUCKET_EP_URL" $CROSS) || S3_BUCKET_EP_URL_ACCESS=$(echo -e "$S3_BUCKET_EP_URL" $CHECK)

   fi

   printf "\n$BLUE%-25s | %-2s | %-14s | %-14s | %-14s | %-9s | %s$CE" "S3 Bucket Name" "E" "Bucket Policy" "Object Count" "IsWebsite" "IsPublic" "Bucket Website Accesibility"
   printf "\n$YELLOW%-25s$CE | %-2s | %-15s | %-15s | %-15s | %-10s | %s\n" "1. $S3_BUCKET_NAME" "$S3_EXIST" "$S3_BUCKET_POLICY_EXIST" "$S3_BUCKET_OBJECTS_EXIST" "$S3_SITE_EN_TEST" "$S3_POLICY_STATUS_TEST" "$S3_BUCKET_EP_URL_ACCESS"
   
   [[ ! -z $(echo $S3_BUCKET_POLICY) ]] && {
      echo -e "\n***** AMAZON S3 BUCKET POLICY START *****\n"
      echo $S3_BUCKET_POLICY | jq .
      echo -e "\n***** AMAZON S3 BUCKET POLICY END *****"
      } 

   line
   echo -e "\n$CLOCK $GREEN 6) TESTING AMAZON CLOUDFRONT $CE $CLOCK"
   line
   
   CF_DIST=$(aws cloudfront list-distributions \
               --max-items 1 \
               --profile $id 2> /dev/null \
               | jq '.DistributionList.Items[] | {Id, Status, DomainName, Origin: .Origins.Items[].DomainName, OAI: .Origins.Items[].S3OriginConfig.OriginAccessIdentity}')   

   if [[ -z "$CF_DIST" ]]
   then
      CF_EXIST=$(echo -e $CROSS)
      CF_STATUS_TEST=$(echo -e $CROSS)
      CF_ORIGIN_TEST=$(echo -e $CROSS)
      OAI_EXIST=$(echo -e $CROSS)
      CF_DNS_TEST=$(echo -e $CROSS)
   else
      CF_ID=$(echo $CF_DIST | jq -rc '(. | {Id}).Id')
      [[ -z "$CF_ID" ]] && CF_EXIST=$(echo -e "NO CF Found" $CROSS) || CF_EXIST=$(echo -e "$CF_ID" $CHECK)

      CF_STATUS=$(echo $CF_DIST | jq -rc '(. | {Status}).Status')
      [[ "$CF_STATUS" == "Deployed" ]] && CF_STATUS_TEST=$(echo -e "$CF_STATUS" $CHECK) || CF_STATUS_TEST=$(echo -e "Deploying..." $CROSS)

      CF_ORIGIN=$(echo $CF_DIST | jq -rc '(. | {Origin}).Origin')
      [[ "$CF_ORIGIN" == "$S3_BUCKET_NAME.s3.us-east-1.amazonaws.com" ]] && CF_ORIGIN_TEST=$(echo -e "$CF_ORIGIN" $CHECK) || CF_ORIGIN_TEST=$(echo -e "$CF_ORIGIN" $CROSS)

      CF_OAI=$(echo $CF_DIST | jq -rc '(. | {OAI}).OAI')
      [[ -z "$CF_OAI" ]] && OAI_EXIST=$(echo -e $CROSS) || OAI_EXIST=$(echo -e $CHECK)

      CF_DNS=$(echo $CF_DIST | jq -rc '(. | {DomainName}).DomainName')
      curl -sf -m 3 "https://$CF_DNS" > /dev/null
      [[ $? -eq 0 ]] && CF_DNS_TEST=$(echo -e "https://$CF_DNS" $CHECK) || CF_DNS_TEST=$(echo -e "https://$CF_DNS" $CROSS)
   fi

   printf "\n$BLUE%-21s | %-14s | %-49s | %-9s | %s$CE" "CF Distribution" "Status" "CF Origin" "IsOAI" "CF DNS Accessibility"
   printf "\n$YELLOW%-22s$CE | %-15s | %-50s | %-10s | %s\n" "1. $CF_EXIST" "$CF_STATUS_TEST" "$CF_ORIGIN_TEST" "$OAI_EXIST" "$CF_DNS_TEST"
   
   line
   echo -e "\n$CLOCK $GREEN 7) TESTING CODEPIPELINE $CE $CLOCK"
   line

   PL_LIST=$(aws codepipeline get-pipeline --profile $id --name $PL_NAME 2> /dev/null)
   if [[ $? -ne 0 ]]
   then
      PL_EXSIST=$(echo -e $CROSS)
      REPO_TEST=$(echo -e $CROSS) 
      PL_BUCKET_TEST=$(echo -e $CROSS)
   else
      PL_EXSIST=$(echo -e $CHECK)
      
      REPO=$(aws codepipeline get-pipeline \
               --profile $id \
               --name $PL_NAME \
               | jq -rc '((.pipeline.stages[] | select(.name=="Source")) | {repo: .actions[].configuration.FullRepositoryId}).repo')
      
      [[ -z $REPO ]] && REPO_TEST=$(echo -e $CROSS) || REPO_TEST=$(echo -e "https://github.com/$REPO $CHECK") 

      PL_BUCKET=$(aws codepipeline get-pipeline \
                  --profile $id \
                  --name $PL_NAME \
                  | jq -rc '((.pipeline.stages[] | select(.name=="Deploy")) | {bucket: .actions[].configuration.BucketName}).bucket')

      [[ "$PL_BUCKET" == "$S3_BUCKET_NAME" ]] && PL_BUCKET_TEST=$(echo -e $PL_BUCKET $CHECK)  || PL_BUCKET_TEST=$(echo -e $CROSS)
   fi

   printf "\n$BLUE%-20s | %-2s | %-50s | %s$CE" "CodePipeline" "E" "Source Repository" "Deploy Bucket"
   printf "\n$YELLOW%-20s$CE | %-2s | %-50s | %s\n" "1. $PL_NAME" "$PL_EXSIST" "$REPO_TEST" "$PL_BUCKET_TEST"
   echo -e '\n'
   hash
   echo -e '\n'
   ((j++))
done < $file
