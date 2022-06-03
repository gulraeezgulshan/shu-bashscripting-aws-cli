#!/bin/bash

ROOT_UID=0
E_ROOT=100

if [ "$UID" -ne "$ROOT_UID" ]
    then

        echo -e "\033[0;31mERROR 100: Please switch to root user! \033[0m"
        exit $E_NOTROOT
fi 