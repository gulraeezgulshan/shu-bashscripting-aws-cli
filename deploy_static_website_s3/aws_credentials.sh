#!/bin/bash

E_AWS_CREDENTIALS=101

access_key_id_param=$(source get_config.sh AWS_ACCESS_KEY_ID)
access_secret_access_key_param=$(source get_config.sh AWS_SECRET_ACCESS_KEY)

AWS_DEFAULT_REGION=$(source get_config.sh DEFAULT_REGION | tr -d '"')

AWS_ACCESS_KEY_ID=$(aws ssm get-parameter --region $AWS_DEFAULT_REGION --name $access_key_id_param --with-decryption --output text --query Parameter.Value )
AWS_SECRET_ACCESS_KEY=$(aws ssm get-parameter --region $AWS_DEFAULT_REGION --name $access_secret_access_key_param --with-decryption --output text --query Parameter.Value)


[[ -n $AWS_ACCESS_KEY_ID && -n $AWS_SECRET_ACCESS_KEY ]] && {

    echo -e "\nConfiguring AWS CLI Credentials..."
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set default.region $AWS_DEFAULT_REGION

} || {
    echo "Something went wrong with AWS CLI Credentials !"
    exit $E_AWS_CREDENTIALS
}

