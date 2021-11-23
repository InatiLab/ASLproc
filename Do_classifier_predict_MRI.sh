#!/bin/bash -i

#====================================================================================================================

# Name: 		Do_classifier_predict_MRI.sh

# Author:   	Katie Snyder, shervin Abdollahi
# Date:     	5/1/19
# Updated:      5/25/2021

# Syntax:       ./Do_classifier_predict_MRI.sh SUBJ
# Arguments:    SUBJ: subject ID
# Description:  Predicts tissue classes using trained classifier.
# Requirements: 1) AFNI
#				2) Python
# Notes:     	--

#====================================================================================================================

# INPUT

#set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 [-h|--help] SUBJ ++\033[0m"
    exit 1
}

#parse option
while [ -n "$1" ];do
    #check case, if valid option found, toggle its respective variable on 
    case "$1" in
        -h|--help)   display_usage ;;   #display help
        *)           break ;;               #prevent any further shifting by breaking
    esac
    shift       #shift to next argument
done

subj="$1"
   

#---------------------------------------------------------------------------------------------------------------------

# VARIABLES

pwd_dir=`pwd`
scripts_dir=${pwd_dir%/*}
top_scripts_dir=${scripts_dir%/*}
eig_dir=${top_scripts_dir%/*}

my_t1='t1.nii'


MRI_dir="${eig_dir}/Projects/MRI"
reg_dir="${MRI_dir}/${subj}/reg"
feat_dir="${MRI_dir}/${subj}/features"
wdir="${MRI_dir}/${subj}/clf"
py_dir=${pwd_dir}/__files/__python

#--------------------------------------------------------------------------------------------------------------------

# REQUIREMENT CHECK

python_dir=`which python3`
if [ "${python_dir}" == '' ]; then
	echo -e "\033[0;35m++ python3 not found on path. Please make sure that its installed. Exiting... ++\033[0m"
	exit 1
fi

#--------------------------------------------------------------------------------------------------------------------

# DATA CHECK

if [ -f "${feat_dir}/t1_features.nii" ] && [ -f "${feat_dir}/t2_features.nii" ] && [ -f "${feat_dir}/fl_features.nii" ]; then
	echo -e "\033[0;35m++ Working on subject $subj... ++\033[0m"
	if [ ! -d "$wdir" ]; then
		mkdir -p $wdir
	fi
	cd $wdir
else
	echo -e "\033[0;35m++ Subject $subj missing bandpass features. Please run MRI_do_bandpass.sh. Exiting... ++\033[0m"
	exit 1
fi

#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================
# STEP 1: copy over T1

if [ ! -f "t1.nii" ]; then
	cp -r ${reg_dir}/$my_t1 t1.nii
fi 

#====================================================================================================================

# STEP 2: run classifier

if [ ! -f "y_class.nii" ] || [ ! -f "y_proba.nii" ]; then
	echo -e "\033[0;35m++ Predicting tissue classes... ++\033[0m"
	python3 ${py_dir}/doVol_predict_rsxn_MRI.py $eig_dir
fi

#====================================================================================================================

# STEP 3: refit output

for dset in 'y_class.nii' 'y_proba.nii'; do
	my_space=`3dinfo -space $dset`
	my_view=`3dinfo -av_space $dset`
	if [ "${my_space}" != 'ORIG' ] || [ "${my_view}" != '+orig' ]; then
		3drefit -space ORIG -view orig $dset
	fi
done

#====================================================================================================================
