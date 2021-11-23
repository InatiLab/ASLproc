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
scripts_dir=${pwd_dir%/*}
top_scripts_dir=${scripts_dir%/*}
eig_dir=${top_scripts_dir%/*}

#-----------------------------

if [[ $1 == "-p" ]]; then
	top_dir=${eig_dir}/Projects/ASL/$subj/postop
else 
	top_dir=${eig_dir}/Projects/ASL/$subj
fi

wdir=${top_dir}/reg 

#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================

# STEP 1: apply transform

cd ${wdir}

if [ ! -f "asl.nii" ]; then
	3dAllineate \
		-1Dmatrix_apply mprage_2_t1.aff12.1D \
		-base t1.nii \
		-source __al2mprage/asl_al+orig \
		-prefix asl.nii 
fi

#====================================================================================================================
