#!/bin/bash -i

#====================================================================================================================

# Name: 		ASL_do_05.sh		

# Author:   	Frederika Rentzeperis
# Date:     	03/15/2021
# Updated:      05/27/2021

# Syntax:   ./ASL_do_05.sh [-h|--help] SUBJ 	    

# Arguments:    SUBJ: 		subject code

# Description: 	this script normalizes cbf data with median 
# Requirements: 
# Main outputs: 
# Notes: 		

# TODO

#====================================================================================================================
#INPUT

# set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 [-h|--help] SUBJ  ++\033[0m"
    exit 1
}


#parse options
while [ -n "$1" ];do
 	# check case; if valid option found, toggle its respective variable on   
	case "$1" in
        -h|--help)   display_usage ;; #display help
        *)           break ;;  #prevent any further shifting by breaking 
    esac
    shift #shift to the next argument
done

subj=$1
#----------------------------------------------------------------------------------------------------------------------

#DEFINE FUNCTIONS

function clean_up_and_exit {
    rm -r -f ${temp_dir} 		# remove temporary working directory
	ssh-add -d ~/.ssh/id_rsa 	# remove key from agent
	exit 1 						# exit
}
#----------------------------------------------------------------------------------------------------------------
# VARIABLES

scripts_dir=`pwd`
files_dir=${scripts_dir}/__files
top_dir=${scripts_dir%/*}
subj_data_dir=${top_dir}/data/${subj}
orig_dir=${subj_data_dir}/orig
wdir=${subj_data_dir}/reg
proc_dir=${subj_data_dir}/proc

#++++++++++++++++++++++++++++++++++ DATA CHECK +++++++++++++++++++++++++++++++++++++++++++++++++


if [ -d "$wdir/alignMNI" ]; then
	echo -e "\033[0;35m++ Working on $subj... ++\033[0m"
	cd ${subj_data_dir}
	if [ ! -d "$proc_dir" ]; then
		mkdir -p ${proc_dir}
	fi
else
	echo -e "\033[0;35m++ Subject $subj does not MNI-registered data. Please run ASL_do_align_MNI.sh. Exiting... ++\033[0m"
	exit 1
fi

cd ${proc_dir}
3dcopy ${wdir}/alignMNI/cbf_ss_mni.nii cbf_mni.nii

if [ -f "cbf_mni.nii" ]; then
	echo -e "\033[0;35m++ Working on $subj... ++\033[0m"
else
	echo -e "\033[0;35m++ Subject $subj does not have cbf mni data. Please run ASL_do_tlrc_regCBF.sh Exiting... ++\033[0m"
	exit 1
fi


#====================================================================================================================

#STEP 1: Blur and Normalize Data
# blur method, FWHM
3dBlurToFWHM -FWHM 5 -mask cbf_mni.nii -prefix cbf_mni-smooth5mm.nii -input cbf_mni.nii

3dmaskdump -mask cbf_mni-smooth5mm.nii -noijk cbf_mni-smooth5mm.nii > ${subj}_cbf_values-smooth5mm.1D 
3dresample -master cbf_mni-smooth5mm.nii -inset ${files_dir}/brainnetome/BN_Atlas_246_1mm.nii.gz -prefix BN_atlas_cbf-smooth5mm.rs


## Compute median and z-score normalizations (stores result in subj_standardize_cbf)
python3 ${files_dir}/__python/doVol_normCBF.py ${subj}

cd ${proc_dir}/${subj}_standardize_cbf

3dresample -master ${subj}_cbf_divMed-smooth5mm.nii -inset ${files_dir}/brainnetome/BN_Atlas_246_1mm.nii.gz -prefix BN_atlas_cbf_divMed-smooth5mm.rs
3dresample -master ${proc_dir}/cbf_mni-smooth5mm.nii -inset ${files_dir}/brainnetome/BN_Atlas_246_1mm.nii.gz -prefix BN_atlas_cbf-smooth5mm.rs

3dROIstats -mask BN_atlas_cbf_divMed-smooth5mm.rs+tlrc. -nzsigma -nzmean ${subj}_cbf_divMed-smooth5mm.nii > ${subj}_divMed_cbf_ROI_stats-smooth5mm.1D
3dROIstats -mask BN_atlas_cbf-smooth5mm.rs+tlrc. -nzsigma -nzmean ${proc_dir}/cbf_mni-smooth5mm.nii > ${subj}_cbf_ROI_stats-smooth5mm.1D

3dmaskdump -mask ${subj}_cbf_divMed-smooth5mm.nii -noijk ${subj}_cbf_divMed-smooth5mm.nii > ${subj}_divMed_cbf_voxels-smooth5mm.1D
3dmaskdump -mask ${proc_dir}/cbf_mni-smooth5mm.nii -noijk ${proc_dir}/cbf_mni-smooth5mm.nii > ${subj}_cbf_voxels-smooth5mm.1D

3dAFNItoNIFTI BN_atlas_cbf-smooth5mm.rs+tlrc BN_atlas_cbf-smooth5mm.rs
3dAFNItoNIFTI BN_atlas_cbf_divMed-smooth5mm.rs+tlrc BN_atlas_cbf_divMed-smooth5mm.rs





