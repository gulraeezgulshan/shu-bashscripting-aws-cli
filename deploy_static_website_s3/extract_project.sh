#!/bin/bash

E_SRC=600
LOCAL_FOLDER=$(source get_config.sh LOCAL_FOLDER)

which unzip &> /dev/null || apt install unzip -y

[[ -d src ]] && {

    if [[ $(ls src | wc -l) -eq 1 ]]
    then
        [[ $(ls -A src | awk -F '.' '{print "."$2}') == ".zip" ]] && {
            [[ -d $LOCAL_FOLDER ]] && rm -R $LOCAL_FOLDER
            unzip -o -qq src/* -d $LOCAL_FOLDER/
            mv $LOCAL_FOLDER/*/* $LOCAL_FOLDER/.
            find $LOCAL_FOLDER -type d -empty -delete
        } || {
            "ERROR: file is not .zip extension !"
        }
    else
        echo "ERROR: src folder is either empty or includes more than one zip file !"
        exit $E_SRC
    fi
    
} || {
    echo "ERROR: src directory does not exsists !"
    exit $E_SRC
} 