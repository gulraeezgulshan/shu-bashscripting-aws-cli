#!/bin/bash

gh_cli_version (){
    GH_VERSION=$(gh --version | grep "gh version" | awk '{print $3}')
    echo $GH_VERSION
}

which gh &> /dev/null || {
	echo "**** Installing GitHub CLI ****"
    echo -e "\GitHub CLI installation depends on CURL"

    which curl &> /dev/null || {
        echo -e "\nCURL is not installed. Installing curl...."
        apt install curl -y
     } && echo -e "\nCurl is already installed !"
     
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt update -y
    apt install gh -y 

    echo -e "\n$(gh_cli_version) have been sucessfully installed to your machine !"
	
    } && {
		echo -e "gh-$(gh_cli_version) is already installed"
	}
