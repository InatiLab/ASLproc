#!/bin/bash -i

#====================================================================================================================

# Name: 		ASL_do_02.sh

# Author:   	Katie Snyder
# Date:     	5/1/19
# Updated:      5/28/21

# Syntax:       ./ASL_do_02.sh SUBJ
# Arguments:    SUBJ: subject ID
# Description:  Asks to check registration between MPRAGE and ASL. If correct, then apply MPRAGE -> T1 alignment to ASL.
# Requirements: 1) AFNI
# Notes: 		This script is interactive.

#====================================================================================================================

# INPUT

if [ "$#" -eq 2 ] & [[ $1 == "-p" ]]; then
	subj=$2
elif [ "$#" -eq 1 ] & [[ $1 != "-p" ]]; then
	subj=$1
else
	echo -e "\033[0;35m++ usage: $0 [-p] SUBJ_ID  ++\033[0m"
	exit 1
fi

#---------------------------------------------------------------------------------------------------------------------
# VARIABLES

pwd_dir=`pwd`
top_dir=${pwd_dir%/*}
data_dir=${top_dir}/data
orig_dir=${data_dir}/$subj/orig
wdir=${data_dir}/${subj}/reg

#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================

# STEP 1: First check the registeration between clincal and research mprage, if correction then apply transorfamtion matrix to ASL data
cd ${wdir} 
afni t1.nii mprage.nii
sleep 5
echo -e "\033[0;35m++ Are registrations correct? Enter Y if correct and N if not. ++\033[0m"
read ynresponse

if [ "$ynresponse" == "Y" ]; then
	echo -e "\033[0;35m++ Registration correct. Continuing to align ASL to mprage... ++\033[0m"
	
	if [ ! -f "asl.nii" ]; then
	3dAllineate \
		-1Dmatrix_apply mprage_2_t1.aff12.1D \
		-base t1.nii \
		-source __al2mprage/asl_al+orig \
		-prefix asl.nii 
	fi
else
	echo -e "\033[0;35m++ Registration not correct. Please delete reg directory and rerun ASL_do_01.sh. Exiting... ++\033[0m"
	exit 1
fi

#====================================================================================================================
# STEP 2: Check the registeration between ASL and T1 

echo -e "\033[0;35m++ Now lets check the alginment between t1 and asl data. ++\033[0m"
afni t1.nii asl.nii
sleep 5
echo -e "\033[0;35m++ Are registrations correct? Enter Y if correct and N if not. ++\033[0m"
read ynresponse

if [ "$ynresponse" == "Y" ]; then
	echo -e "\033[0;35m++ Registration correct. Moving one to the next step... ++\033[0m"

else
	echo -e "\033[0;35m++ Registration not correct. Please delete reg directory and rerun ASL_do_01.sh. with different edge & rigid body options. Exiting... ++\033[0m"
	exit 1
fi	

#==========================================================================================================================