#!/bin/bash -i

#====================================================================================================================

# Name: 		Do_calc_features.sh

# Author:   	shervin Abdollahi
# Date:     	10/20/2020
# Updated:      

# Syntax:       ./Do_calc_features.sh -P SUBJ
# Arguments:    SUBJ: subject ID
# Description:  Creates JEM original  features.
# Requirements: 1) AFNI
#				2) Python - jem environment 
# Notes:     

#====================================================================================================================

# INPUT

#set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 [-h|--help] [-p|--postop] SUBJ ++\033[0m"
    exit 1
}
# set defaults
postop=false;  

#parse option
while [ -n "$1" ];do
    #check case, if valid option found, toggle its respective variable on 
    case "$1" in
        -h|--help)   display_usage ;;   #display help
        -p|--postop) postop=true ;;     #post-op
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

#-----------------------------
#postop flag		
if [[ ${postop} == 'true' ]]; then
	
	postop_subdir='/postop'
	my_t1='t1_postop.nii'
	my_t2='t2_postop.nii'
	my_fl='fl_postop.nii'
else
	
	postop_subdir=''
	my_t1='t1.nii'
	my_t2='t2.nii'
	my_fl='fl.nii'
fi

#defining working directory
wdir="${eig_dir}/Projects/MRI/${subj}/features${postop_subdir}"
rdir="${eig_dir}/Projects/MRI/$subj/reg"

#--------------------------------------------------------------------------------------------------------------------

# REQUIREMENT CHECK

conda_dir=`conda info --base`
if [ ! -d "${conda_dir}/envs/jem" ]; then
	if [ ! -d "$HOME/.conda/envs/jem" ]; then
		echo -e "\033[0;35m++ Conda environment jem does not exist. Please run download jem from github, then run 'conda create -n jem python=3.7' in the package directory. Exiting... ++\033[0m"
		exit 1
	fi
fi

#---------------------------------------------------------------------------------------------------------------------

# DATA CHECK

if [ -f "${rdir}/${my_t1}" ] && [ -f "${rdir}/${my_t2}" ]; then

	if [ ! -d "$wdir" ]; then
		mkdir -p ${wdir}
	fi
	cd ${wdir}

else
	echo -e "\033[0;35m++ Subject $subj has not been registered. Please run ./registration.sh. Exiting... ++\033[0m"
	exit 1
fi

#====================================================================================================================
#	 BEGIN SCRIPT
#====================================================================================================================

# STEP 1: bandpass

source activate jem

for img in 't1' 't2' 'fl'; do
	my_out="${img}_features.nii"
	if [[ ${postop} == "true" ]]; then
		my_inp="${img}_postop.nii"
	else
		my_inp="${img}.nii"
	fi
	if [ -f "${rdir}/$my_inp" ] && [ ! -f "$my_out" ]; then
		echo -e "\033[0;35m++ Calculating original features for $img... ++\033[0m"
		compute_features --num_scales 3 --output $my_out $rdir/$my_inp 			
	fi
done

conda deactivate

#====================================================================================================================
