#!/bin/bash


CALLER_REFERENCE=$(source get_config.sh CALLER_REFERENCE)
OAI_COMMENT=$(source get_config.sh OAI_COMMENT)
DEFAULT_ROOT_OBJECT=$(source get_config.sh DEFAULT_ROOT_OBJECT)
S3_BUCKET_NAME=$(source get_config.sh S3_BUCKET_NAME | tr -d '"')
DEFAULT_REGION=$(source get_config.sh DEFAULT_REGION | tr -d '"')
ORIGIN_DOMAIN_NAME=$(echo "'$S3_BUCKET_NAME.s3.$DEFAULT_REGION.amazonaws.com'" | tr "'" '"')
ORIGIN_DOMAIN_ID="$ORIGIN_DOMAIN_NAME"
CACHE_POLICY_ID=$(source get_config.sh CACHE_POLICY_ID)
ALIASES=$(source get_config.sh ALIASES)
VIEWER_PROTOCOL_POLICY=$(source get_config.sh VIEWER_PROTOCOL_POLICY)
CLOUDFRONT_DEFAULT_CERTIFICATE=$(source get_config.sh CLOUDFRONT_DEFAULT_CERTIFICATE)
ACM_CERTIFICATE_ARN=$(source get_config.sh ACM_CERTIFICATE_ARN)
SSL_SUPPORT_METHOD=$(source get_config.sh SSL_SUPPORT_METHOD)
MINIMUM_PROTOCOL_VERSION=$(source get_config.sh MINIMUM_PROTOCOL_VERSION)
CERTICIATE=$(source get_config.sh CERTICIATE)
CERTICIATE_SOURCE=$(source get_config.sh CERTICIATE_SOURCE)

echo -e "\nCreating CloudFront OAI"
OAI_ETAG=$(aws cloudfront list-cloud-front-origin-access-identities --max-items 1 --query "CloudFrontOriginAccessIdentityList.Items[].Id | [0]")

[[ $OAI_ETAG == null ]] && {
    echo "OAI does not exists; creating ..."
    aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config \
    CallerReference="$CALLER_REFERENCE",Comment="$OAI_COMMENT"
    OAI_ETAG=$(aws cloudfront list-cloud-front-origin-access-identities --max-items 1 --query 'CloudFrontOriginAccessIdentityList.Items[].Id' --output text)
}

ORIGIN_ACCESS_IDENTITY=$(echo "\"origin-access-identity/cloudfront/$(echo $OAI_ETAG | tr -d '"')\"")

which jq &> /dev/null || apt install jq -y

echo -e "\nConfiguring cloudfront.json file..."

jq  '.CallerReference='"$CALLER_REFERENCE"' | 
    .Aliases.Items[0] |= .+ '"$ALIASES"'  |
    .DefaultRootObject='"$DEFAULT_ROOT_OBJECT"' | 
    .Origins.Items[0].Id='"$ORIGIN_DOMAIN_ID"' |
    .Origins.Items[0].DomainName='"$ORIGIN_DOMAIN_NAME"' |
    .Origins.Items[0].S3OriginConfig.OriginAccessIdentity='"$ORIGIN_ACCESS_IDENTITY"' |
    .DefaultCacheBehavior.TargetOriginId='"$ORIGIN_DOMAIN_ID"' |
    .DefaultCacheBehavior.ViewerProtocolPolicy='"$VIEWER_PROTOCOL_POLICY"' |
    .ViewerCertificate.Certificate='"$CERTICIATE"' |
    .ViewerCertificate.CertificateSource='"$CERTICIATE_SOURCE"' |
    .ViewerCertificate.MinimumProtocolVersion='"$MINIMUM_PROTOCOL_VERSION"' |
    .ViewerCertificate.SSLSupportMethod='"$SSL_SUPPORT_METHOD"' |
    .ViewerCertificate.CloudFrontDefaultCertificate='"$CLOUDFRONT_DEFAULT_CERTIFICATE"' |
    .ViewerCertificate.ACMCertificateArn='"$ACM_CERTIFICATE_ARN"' |
    .DefaultCacheBehavior.CachePolicyId='"$CACHE_POLICY_ID"'' \
    cloudfront.template.json > tmp
    mv tmp cloudfront.json
    [[ -e tmp ]] && rm tmp

echo "Creating CloudFront..."
aws cloudfront create-distribution --distribution-config file://cloudfront.json &> /dev/null