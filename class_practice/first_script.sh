#!/bin/bash

#echo "My first script"

# || && !
# cmd1 || cmd2
# cmd1 && cmd2

# cmd1 || cmd2
#which nginx || echo "Nginx not found, please install it first !" && echo "NGINX is installed"


# which nginx

# if [[ $? -eq 0 ]]
# then
#     echo "NGINX is installed"
# else
#     echo "Nginx not found, please install it first !"
# fi




##{} => block of commands

E_NONSUDO=101

[[ $UID -eq 0 ]] || {
    echo "You are not sudo user..."
    exit $E_NONSUDO
}


nginx -v || {
    echo "Installing NGNIX..."
    apt install nginx -y
}
 && {
     echo "Starting NGINX service..."
     systemctl start nginx
     system enable nginx
 }



