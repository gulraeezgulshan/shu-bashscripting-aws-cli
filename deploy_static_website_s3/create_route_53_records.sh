#!/bin/bash

E_NOHOSTED_ZONE=500

HOSTED_ZONE_DOMAIN=$(source get_config.sh HOSTED_ZONE_DOMAIN)
CLOUDFRONT_HOSTED_ZONE_ID=$(source get_config.sh CLOUDFRONT_HOSTED_ZONE_ID)
DOMAIN=$(source get_config.sh DOMAIN)
SUB_DOMAIN=$(source get_config.sh SUB_DOMAIN)

echo -e "\nGetting Route53 Hosted Zone Info for [$DOMAIN].."
which jq &> /dev/null || apt install jq -y
HOSTED_ZONE=$(aws route53 list-hosted-zones | jq '(.HostedZones[] | select(.Name == '"$HOSTED_ZONE_DOMAIN"')).Id, (.HostedZones[] | select(.Name == '"$HOSTED_ZONE_DOMAIN"')).Name')

test -z "$HOSTED_ZONE" && {
    echo "ERROR: No hosted found for domain [$HOSTED_ZONE_DOMAIN]"
    exit $E_NOHOSTED_ZONE
}

HOSTED_ZONE_ID=$(echo "$HOSTED_ZONE" | awk '{if(NR==1) print $0}' | tr -d '/hostedzone/')
HOSTED_ZONE_DOMAIN_NAME=$(echo "$HOSTED_ZONE" | awk '{if(NR==2) print $0}')

echo -e "\nGetting CloudFront Info for [$DOMAIN].."
CLOUDFRONT_ORIGIN_ID=$(cat cloudfront.json | jq '.Origins.Items[0].Id')
CLOUD_FRONT_DOMAIN=$(aws cloudfront list-distributions | jq '(.DistributionList.Items[] | select(.Origins.Items[0].Id=='"$CLOUDFRONT_ORIGIN_ID"')).DomainName')

echo -e "\nGetting TLS/SSL Certificate Info for [$DOMAIN].."
CERTIFICATE_ARN=$(aws acm list-certificates | jq '(.CertificateSummaryList[] | select(.DomainName=='"$DOMAIN"')).CertificateArn')

CERTIFICATE_RECORD_SET=$(aws acm describe-certificate \
                        --certificate-arn $(echo $CERTIFICATE_ARN | tr -d '"') \
                        | jq '.Certificate.DomainValidationOptions[0].ResourceRecord | {Name,Value}' | awk '{print $2}' | grep -v -e '^[[:space:]]*$')


CERTIFICATE_RECORD_SET_NAME=$(echo $CERTIFICATE_RECORD_SET | awk '{print $1}' | tr -d ',')
CERTIFICATE_RECORD_SET_VALUE=$(echo $CERTIFICATE_RECORD_SET | awk '{print $2}')

echo -e "\nGenerating Route53 Config File..."

jq  '.Changes[0].ResourceRecordSet.Name='"$HOSTED_ZONE_DOMAIN_NAME"' |
    .Changes[0].ResourceRecordSet.AliasTarget.HostedZoneId='"$CLOUDFRONT_HOSTED_ZONE_ID"' |
    .Changes[0].ResourceRecordSet.AliasTarget.DNSName='"$CLOUD_FRONT_DOMAIN"' |
    .Changes[1].ResourceRecordSet.Name='"$SUB_DOMAIN"' |
    .Changes[1].ResourceRecordSet.ResourceRecords[0].Value='"$DOMAIN"' |
    .Changes[2].ResourceRecordSet.Name='"$CERTIFICATE_RECORD_SET_NAME"' |
    .Changes[2].ResourceRecordSet.ResourceRecords[0].Value='"$CERTIFICATE_RECORD_SET_VALUE"'' \
    alias_record.template.json > tmp
    mv tmp alias_record.json
    [[ -e tmp ]] && rm tmp

echo -e "\nAdding Recordsets for CloudFront DNS, ACM Certificate to Route53..."
aws route53 change-resource-record-sets \
    --hosted-zone-id $(echo $HOSTED_ZONE_ID | tr -d '"') \
    --change-batch file://alias_record.json &> /dev/null || echo "Record exsists !"

