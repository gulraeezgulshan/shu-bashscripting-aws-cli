#!/bin/bash

ROOT_UID=0     
E_NOTROOT=100  

read -rp "Install or Upgrade NGINN? (y/n) " INSTALL

if [[ $INSTALL =~ ^([yY][eE][sS]|[yY])$ ]]; then

    if [ "$UID" -ne "$ROOT_UID" ]
    then
        echo "Must be root to run this script."
        exit $E_NOTROOT
    fi  

	which nginx &> /dev/null || {
		echo "Installing nginx"
		apt install nginx 
        echo;
        echo "Installed NGINX !"

	} && {
		echo "Updating nginx"
		apt install nginx --upgrade
	}

	echo "Completed."
fi