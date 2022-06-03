#!/bin/bash

E_NOCONNECTION=400
E_CONNECTION_PENDING=401

ARTIFACT_STORE_LOCATION=$(source get_config.sh ARTIFACT_STORE_LOCATION)
GITHUB_BRANCH_NAME=$(source get_config.sh GITHUB_BRANCH_NAME)
REGION=$(source get_config.sh DEFAULT_REGION)
TAGS_KEY=$(source get_config.sh TAGS_KEY)
TAGS_VALUE=$(source get_config.sh TAGS_VALUE)
SERVICE_ROLE_NAME=$(source get_config.sh SERVICE_ROLE_NAME)
REPO_OWNER=$(source get_config.sh REPO_OWNER)
GITHUB_REPO_NAME=$(source get_config.sh GITHUB_REPO_NAME)
DEPLOY_BUCKET_NAME=$(source get_config.sh S3_BUCKET_NAME)
FULL_REPOSITORY_ID=$(source get_config.sh FULL_REPOSITORY_ID)
CODEPIPELINE_NAME=$(source get_config.sh CODEPIPELINE_NAME)

echo -e "\nCreating CodePipeline Service Role"
aws iam create-role \
    --role-name $SERVICE_ROLE_NAME \
    --assume-role-policy-document file://codepipeline_trust_policy.json &> /dev/null || echo "Role Already Exsists" 

aws iam put-role-policy --role-name $SERVICE_ROLE_NAME --policy-name $SERVICE_ROLE_NAME --policy-document file://code_pipeline_service_role_policy.json

ROLE_ARN=$(aws iam get-role --role-name $SERVICE_ROLE_NAME --query Role.Arn)

echo -e "\nGetting CodeStar GitHub Connection"

CODESTAR_GITHUB_CONN=$(aws codestar-connections list-connections \
                        --provider-type-filter GitHub \
                        --max-results 1 \
                        --query Connections[].[ConnectionArn,ConnectionStatus])

[[ -z $CODESTAR_GITHUB_CONN ]] && {
    echo "No CodeStar GitHub Connection Found in AWS"
    exit $E_NOCONNECTION
}

CONNECTION_ARN=$(echo $CODESTAR_GITHUB_CONN | jq '.[0][0]')
CONNECTION_STATUS=$(echo $CODESTAR_GITHUB_CONN | jq '.[0][1]')

echo $CONNECTION_STATUS | grep -w "AVAILABLE" &> /dev/null || {
    echo "CodeStart Github Connection is not in AVAILABLE state. Complete the PENDING connection first"
    exit $E_CONNECTION_PENDING
}


which jq &> /dev/null || apt install jq

echo -e "\nCreating CodePipeline Configuration file..."
jq '.pipeline.name='"$CODEPIPELINE_NAME"' | 
    .pipeline.roleArn='"$ROLE_ARN"' |
    (.pipeline.stages[] | select(.name=="Source")).actions[].configuration.BranchName='"$GITHUB_BRANCH_NAME"' |
    (.pipeline.stages[] | select(.name=="Source")).actions[].configuration.ConnectionArn='"$CONNECTION_ARN"' |
    (.pipeline.stages[] | select(.name=="Source")).actions[].configuration.FullRepositoryId='"$FULL_REPOSITORY_ID"' |
    (.pipeline.stages[] | select(.name=="Source")).actions[].region='"$REGION"' |
    (.pipeline.stages[] | select(.name=="Deploy")).actions[].configuration.BucketName='"$DEPLOY_BUCKET_NAME"' |
    (.pipeline.stages[] | select(.name=="Deploy")).actions[].region='"$REGION"'' \
    pipeline.template.json > tmp
    mv tmp pipeline.json
    [[ -e tmp ]] && rm tmp


echo -e "\nCreating CodePipeline..."
aws codepipeline create-pipeline --cli-input-json file://pipeline.json &> /dev/null

