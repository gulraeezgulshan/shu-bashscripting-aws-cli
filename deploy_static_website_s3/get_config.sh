#!/bin/bash

E_FILEMISSING=201
E_NOPARAM=202

[[ -z $1 ]] && {
    echo "ERROR: No parameter provided for get_config.sh !"
    exit $E_NOPARAM
} 

# | tr '"' in end

[[ -e config.conf ]] && cat config.conf | grep -w $1 | awk -F '=' '{print $2}' || {
    echo -e "\n\033[0;31mERROR: Configuration file [config.conf] is missing! \033[0m"
    exit $E_FILEMISSING
}