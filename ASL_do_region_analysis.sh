#!/bin/bash -i

#====================================================================================================================

# Name: 		ASL_do_region_analysis.sh		

# Author:   	Frederika Rentzeperis
# Date:     	04/23/2021
# Updated:	05/29/2021

# Syntax:   bash ASL_do_region_analysis.sh SUBJ	    

# Arguments:    SUBJ: 		subject code

# Description: generate normalized, resampled regional and focal brainnetome atlases for each subject; compute 3dROIstats
# Requirements: 
# Main outputs: 
# Notes: 		

# TODO

#====================================================================================================================
#INPUT

# set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 SUBJ ++\033[0m"
    exit 1
}

subj=("$@")

if [ ! ${#subj} -gt 0 ]; then
    echo -e "\033[0;35m++ Subject list length is zero; please specify at least one subject to perform batch processing on ++\033[0m"
    display_usage
fi
echo -e "\033[0;35m++ subjects to be processed: ${subj} ++\033[0m"


#----------------------------------------------------------------------------------------------------------------------

#DEFINE FUNCTIONS

function clean_up_and_exit {
    rm -r -f ${temp_dir} 		# remove temporary working directory
	ssh-add -d ~/.ssh/id_rsa 	# remove key from agent
	exit 1 						# exit
}
#----------------------------------------------------------------------------------------------------------------
#VARIABLES

unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*) eig_dir="/Volumes/Shares/EEG/EIG" ;;
    Linux*)  eig_dir="/shares/EEG/EIG" ;;
    *)       echo -e "\033[0;35m++ Unrecognizable system. must be either Linux or Mac OS in order to run ... Exiting ++\033[0m"; exit 1
esac

#EIG Paths
proj_dir="${eig_dir}/Projects"
proc_dir=${proj_dir}/ASL/$subj/proc
regional_dir=${proj_dir}/ASL/regional_analysis

#====================================================================================================================
	
#DATA CHECK

	if [ ! -d "$regional_dir" ]; then
		echo -e "\033[0;35m++ Generating regional analysis folder... ++\033[0m"
		cd ${proj_dir}
		mkdir -p ${regional_dir}		
	else
		echo -e "\033[0;35m++ Regional folder found, checking for subject data... ++\033[0m"
	fi


# look for the normalized cbf data

if [ -d "${proc_dir}/${subj}_standardize_cbf" ]; then
	cd ${proc_dir}/${subj}_standardize_cbf
	if [ -f "${subj}_cbf_divMed-smooth5mm.nii" ]; then
		echo -e "\033[0;35m++ Smoothed and normalized CBF data found for $subj. Continuing... ++\033[0m"
	fi
else
	echo -e "\033[0;35m++ No normalized CBF data for $subj, please run ASL_do_05... ++\033[0m"
	exit 1
fi

#====================================================================================================================

## REGIONAL COMPUTATION
# resample the regional atlas to the subject's smoothed ASL data
3dresample -master ${subj}_cbf_divMed-smooth5mm.nii -inset ${proj_dir}/ASL/brainnetome/BN_Atlas_regional.nii -prefix ${regional_dir}/${subj}_BN_regional.rs.nii

# compute regional stats for the subject
3dROIstats -mask ${regional_dir}/${subj}_BN_regional.rs.nii -nzsigma -nzmean ${subj}_cbf_divMed-smooth5mm.nii > ${regional_dir}/${subj}_regional_stats.1D


## FOCAL COMPUTATION
# resample the focal atlas to the subject's smoothed ASL data
3dresample -master ${subj}_cbf_divMed-smooth5mm.nii -inset ${proj_dir}/ASL/brainnetome/BN_Atlas_focal.nii -prefix ${regional_dir}/${subj}_BN_focal.rs.nii

# compute focal stats for the subject
3dROIstats -mask ${regional_dir}/${subj}_BN_focal.rs.nii -nzsigma -nzmean ${subj}_cbf_divMed-smooth5mm.nii > ${regional_dir}/${subj}_focal_stats.1D


#====================================================================================================================

## COMPUTATIONS FOR ANTERIOR/POSTERIOR LTL
# resample the regional a/p LTL atlas to the subject's smoothed ASL data
3dresample -master ${subj}_cbf_divMed-smooth5mm.nii -inset ${proj_dir}/ASL/brainnetome/BN_Atlas_regional_all-apLTL.nii -prefix ${regional_dir}/${subj}_BN_regional-apLTL.rs.nii

# compute regional a/p LTL stats for the subject
3dROIstats -mask ${regional_dir}/${subj}_BN_regional-apLTL.rs.nii -nzsigma -nzmean ${subj}_cbf_divMed-smooth5mm.nii > ${regional_dir}/${subj}_regional_stats-apLTL.1D


## FOCAL COMPUTATION
# resample the focal a/p LTL atlas to the subject's smoothed ASL data
3dresample -master ${subj}_cbf_divMed-smooth5mm.nii -inset ${proj_dir}/ASL/brainnetome/BN_Atlas_focal_all-apLTL.nii -prefix ${regional_dir}/${subj}_BN_focal-apLTL.rs.nii

# compute focal a/p LTL stats for the subject
3dROIstats -mask ${regional_dir}/${subj}_BN_focal-apLTL.rs.nii -nzsigma -nzmean ${subj}_cbf_divMed-smooth5mm.nii > ${regional_dir}/${subj}_focal_stats-apLTL.1D


