#!/bin/bash

ARCH=$(uname -i)

aws_cli_version (){
    AWS_VERSION=$(aws --version | awk '{print $1}'| tr '/' '-')
    echo $AWS_VERSION
}

which aws &> /dev/null || {
	echo "**** Installing AWS CLI ****"
    echo -e "\nAWS CLI installation depends on CURL, UNZIP package "

    which curl &> /dev/null || {
        echo -e "\nCURL is not installed. Installing curl...."
        apt install curl -y
     } && echo -e "\nCurl is already installed !"

    which unzip &> /dev/null || {
        echo -e "\nUNZIP is not installed. Installing unzip...."
        apt install unzip -y 
    } && echo -e "\nUNZIP is already installed !"

    curl "https://awscli.amazonaws.com/awscli-exe-linux-$ARCH.zip" -o "awscliv2.zip"
    
    unzip $PWD/awscliv2.zip
    $PWD/aws/install
    rm $PWD/awscliv2.zip

    echo -e "\n$(aws_cli_version) have been sucessfully installed to your machine !"
	
    } && {
		echo -e "$(aws_cli_version) is already installed"
	}
