#!/bin/bash

#====================================================================================================================

# Name: 		ASL_do_03.sh 

# Author:   	shervin Abdollahi & Frederika Rentzeperis
# Date:     	11/03/2020
# Updated:      05/25/2021

# Syntax:       ./ASL_do_03.sh  SUBJ
# Arguments:    SUBJ: subject ID 
# Description:  seperates the segmentation method among internal patients and external patients              

# Requirements: 1) You will need python installed and an environment set up to run python2 called p2.7
#				2) AFNI
# Notes:        
#====================================================================================================================
# INPUT

#set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 [-h|--help] SUBJ ++\033[0m"
    exit 1
}
# set defaults
alt=false; fsl=false; postop=false; 

#parse option
while [ -n "$1" ];do
    #check case, if valid option found, toggle its respective variable on 
    case "$1" in
        -h|--help)   display_usage ;;   #display help
		*)           break ;;        #prevent any further shifting by breaking
    esac
    shift      
done
subj="$1"

pwd_dir=`pwd`
scripts_dir=${pwd_dir%/*}
top_scripts_dir=${scripts_dir%/*}
eig_dir=${top_scripts_dir%/*}
top_dir=${eig_dir}/Projects

################################# DATA CHECK ###################################################
if [[ -d "${top_dir}/MRI/${subj}/features" ]]; then
	echo -e "\033[0;35m++ features have been computed for subject ${subj}. please rename features directory  ++\033[0m"   
fi

if [[ -d "${top_dir}/MRI/${subj}/clf" ]]; then
        echo -e "\033[0;35m++ classification  has been computed for subject ${subj}. please rename clf  directory  ++\033[0m"
        exit 1
fi
#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================

# run multifeature classifier
if [ ! -d "${top_dir}/MRI/${subj}/features" ]; then
    
    bash ${pwd_dir}/Do_calc_features.sh ${subj}
fi

if [ ! -d "${top_dir}/MRI/${subj}/clf" ]; then

    bash ${pwd_dir}/Do_classifier_predict_MRI.sh ${subj}
fi


    





