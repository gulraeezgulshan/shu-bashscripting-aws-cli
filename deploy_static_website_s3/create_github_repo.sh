#!/bin/bash

E_TOKEN=300
E_NOSSHKEY=301
E_FOLDER=302
E_GIT=303

which git &> /dev/null || {
    echo -e "Installing git..."
    apt install update
    apt install git -y &> /dev/null 
}

github_access_token_param=$(source get_config.sh GITHUB_ACCESS_TOKEN)
default_region=$(source get_config.sh DEFAULT_REGION | tr -d '"')

GITHUB_ACCESS_TOKEN=$(aws --region $default_region ssm get-parameter --name $github_access_token_param --with-decryption --output text --query Parameter.Value 2> /dev/null)

[[ -n $GITHUB_ACCESS_TOKEN ]] && echo $GITHUB_ACCESS_TOKEN > gh_access_token.txt || {
    echo "Something went wrong with GitHub CLI Credentials !"
    exit $E_TOKEN
}

[[ -e gh_access_token.txt ]] && gh auth login --with-token -p ssh < gh_access_token.txt || {
    echo "GitHub token file not found!"
    exit $E_TOKEN
}

KEY_NAME=$(source get_config.sh KEY_NAME)
SSH_KEY_TITLE=$(source get_config.sh SSH_KEY_TITLE)
GITHUB_REPO_NAME=$(source get_config.sh GITHUB_REPO_NAME)
GITHUB_REPO_DESC=$(source get_config.sh GITHUB_REPO_DESC)
LOCAL_FOLDER=$(source get_config.sh LOCAL_FOLDER)
REPO_OWNER=$(source get_config.sh REPO_OWNER)

# Check if *.pub key already exsists
pub_key_count=$(ls -1 ~/.ssh/$KEY_NAME.pub 2>/dev/null | wc -l)

[[ pub_key_count -eq 0 ]] && {
    echo -e "\nCreating SSH key pairs..."
    ssh-keygen -f ~/.ssh/$KEY_NAME -t ecdsa -b 521 -q -N "" &> /dev/null
    } || {
        echo -e "\nKey pairs already exists"
        #ssh-keygen -q -t rsa -N '' -f ~/.ssh/$KEY_NAME <<<y >/dev/null 2>&1
    }

echo -e "\nAdding SSH key to GitHub..."
gh ssh-key add ~/.ssh/$KEY_NAME.pub -t $SSH_KEY_TITLE 2> /dev/null || echo "Key is already in use in GitHub !"

echo -e "\nCreating public repo [$GITHUB_REPO_NAME] on GitHub"
gh repo create $GITHUB_REPO_NAME --public --description $GITHUB_REPO_DESC 2> /dev/null || echo -e "Repository already exsists !"

# Check website folder exsist and non-empty

if [[ -e $PWD/$LOCAL_FOLDER && ! -z "$(ls -A $PWD/$LOCAL_FOLDER)"  ]]
then
    cd $PWD/$LOCAL_FOLDER
    git status &> /dev/null
    if [[ $? -eq 0 ]]
    then
        echo -e "\n***Your local repo has already been pushed to GitHub***"
        echo -e "***Check your changes to deployed website or upload new project in website folder***"
        cd - &> /dev/null
        exit $E_GIT
    else
        echo "Creating local repo, pushing to remote repo.."
        git init &> /dev/null
        git add . &> /dev/null
        git commit -m 'first commit' &> /dev/null
        git branch -M main
        git remote add origin git@github.com:$REPO_OWNER/$GITHUB_REPO_NAME.git
        git push -u origin main &> /dev/null
        
        cd - &> /dev/null #switching back to previous directory
    fi
else
    echo -e "Error: \n$LOCAL_FOLDER is either empty or does not exist!"
    exit $E_FOLDER
fi




