#!/bin/bash -i

#====================================================================================================================

# Name: 	ASL_do_06.sh		

# Author:   	Frederika Rentzeperis
# Date:     	05/10/21
# Updated:      5/29/21

# Syntax:   ./ASL_do_surf_analysis.sh [-h|--help] [-l|--list SUBJ_LIST] [SUBJ [SUBJ ...]]	    

# Arguments:    SUBJ: 		subject code

# Description:  samples the newly calculated CBF data to the surface, takes the average CBF value between the nodes of the smooth wm and dial surfaces, and applies brainnetome atlas
# Requirements: 
# Main outputs: 
# Notes: 		

# TODO

#====================================================================================================================
#INPUT

# set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 [-h|--help] [-l|--list SUBJ_LIST] [SUBJ [SUBJ ...]] ++\033[0m"
    exit 1
}

# set defaults
subj_list=false

#parse options
while [ -n "$1" ];do
 	# check case; if valid option found, toggle its respective variable on   
	case "$1" in
        -h|--help)   display_usage ;; #display help
        -l|--list)   subj_list=$2; shift ;; #subject_list
        *)           break ;;  #prevent any further shifting by breaking 
    esac
    shift #shift to the next argument
done

# check if subj_list argument was given; if not, get positional arguments
if [ ${subj_list} != "false" ]; then
    if [ ! -f ${subj_list} ]; then
        echo -e "\033[0;35m++ ${subj_list} subject list does not exist  ++\033[0m" 
        exit 1
    else
        subj_arr=($(cat ${subj_list}))
    fi
else
    subj_arr=("$@")
fi

if [ ! ${#subj_arr} -gt 0 ]; then
    echo -e "\033[0;35m++ Subject list length is zero; please specify at least one subject to perform batch processing on ++\033[0m"
    display_usage
fi
echo -e "\033[0;35m++ subjects to be processed: ${subj_arr[@]} ++\033[0m"
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
    *)       echo -e "\033[0;35m++ Unrecognizable system. must be either Linux or Mac OS inorder to run ... Exiting ++\033[0m"; exit 1
esac

#EIG Paths
pwd_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
proj_dir="${eig_dir}/Projects"

top_dir=${eig_dir}/Projects/ASL/$subj
if [[ -d "${eig_dir}/Projects/MRI/${subj_arr[@]}" ]]; then
	proj_mri_dir=${eig_dir}/Projects/MRI/
else
	proj_mri_dir=${eig_dir}/Projects/MRI/__alternateMRIs
fi

for subj in ${subj_arr[@]}; do
	subj_asl_dir=${proj_dir}/ASL/$subj
	wdir=${subj_asl_dir}/reg	
			
#++++++++++++++++++++++++++++++++++ DATA CHECK +++++++++++++++++++++++++++++++++++++++++++++++++


if [ -d "${proj_mri_dir}/$subj/surf/xhemi" ]; then
	if [ -f "${wdir}/CBF.nii" ]; then
		echo -e "\033[0;35m++ Processing subject $subj... ++\033[0m"
		if [ ! -d "${wdir}/alignSurf" ]; then
			mkdir ${wdir}/alignSurf
		fi
	else
		echo -e "\033[0;35m++ Subject $subj missing t1-aligned CBF data. Please run ASL_do_align_MNI.sh to calculate CBF. Exiting... ++\033[0m"
		exit 1
	fi
else
	echo -e "\033[0;35m++ Surface data missing from ${proj_mri_dir}/$subj/surf/xhemi. Please run MRI_do_04.sh. Exiting... ++\033[0m"
	exit 1
fi


# Generate the counts of voxels per parcel for brainnetome so I can scale for parcel size in surface analysis
cd ${proj_dir}/ASL
if [ ! -f "BN_parcel_size.1D" ]; then
	echo -e "\033[0;35m++ Counting total voxels per brainnetome parcel ++\033[0m"
	3dROIstats -mask ${pwd_dir}/__files/BN_Atlas_246_1mm.nii.gz -nomeanout -nzvoxels ${pwd_dir}/__files/BN_Atlas_246_1mm.nii.gz > BN_parcel_size.1D
fi

#====================================================================================================================

#STEP 1: Normalize Data by dividing by the median voxel value from within brain mask

cd ${wdir}
# blur the CBF dataset with 5mm gaussian kernel inside the brain mask
if [ ! -f "CBF-smooth5mm.nii" ]; then
	3dBlurToFWHM -FWHM 5 -prefix CBF-smooth5mm.nii -input CBF.nii
fi

# divide the CBF dataset by its median value (from the volume analysis)
python3 ${pwd_dir}/__files/__python/doSurf_normCBF.py ${subj}

#====================================================================================================================

#STEP 2: Project onto surface

cd ${proj_mri_dir}/$subj/surf/xhemi/orig

if [ ! -d "white" ]; then
	mkdir -p white
fi

#-----------------------

for hemi in 'lh' 'rh'; do
	spec="${hemi}.spec"
	my_surf_A="${hemi}.white.gii"
	my_surf_B="${hemi}.pial.gii"
	my_out="${hemi}.CBF-avg.1D.dset"
	my_out_norm="${hemi}.CBF-avg.norm.1D.dset"
	if [ ! -f "white/$my_out" ]; then
		3dVol2Surf \
			-overwrite \
			-spec $spec \
			-surf_A $my_surf_A \
			-surf_B $my_surf_B \
			-sv SurfVol_Alnd_Exp+orig \
			-grid_parent ${wdir}/CBF-smooth5mm.nii \
			-map_func nzave \
			-outcols_results \
			-out_1D white/$my_out
	fi

	if [ ! -f "white/$my_out_norm" ]; then
		3dVol2Surf \
			-overwrite \
			-spec $spec \
			-surf_A $my_surf \
			-surf_B $my_surf_B \
			-sv SurfVol_Alnd_Exp+orig \
			-grid_parent ${wdir}/CBF_surf_norm.nii \
			-map_func nzave \
			-outcols_results \
			-out_1D white/$my_out_norm
	fi

done

#-------------------------------------------------

cd ${proj_mri_dir}/$subj/surf/xhemi

for ld in '20' '60' '141'; do 
	std_dir="std${ld}"
	for my_dir in 'orig' 'lhreg' 'rhreg'; do
		cd ${proj_mri_dir}/$subj/surf/xhemi/${std_dir}/${my_dir}
		if [ ! -d "white" ]; then
			mkdir -p white
		fi

		for hemi in 'lh' 'rh'; do
			spec="std.${ld}.${hemi}.spec"
			my_surf_A="std.${ld}.${hemi}.white.gii"
			my_surf_B="std.${ld}.${hemi}.pial.gii"
			my_out="std.${ld}.${hemi}.CBF-avg.1D.dset"
			my_out_norm="std.${ld}.${hemi}.CBF-avg.norm.1D.dset"
			if [ ! -f "white/$my_out" ]; then
				3dVol2Surf \
					-overwrite \
					-spec $spec \
					-surf_A $my_surf_A \
					-surf_B $my_surf_B \
					-sv SurfVol_Alnd_Exp+orig \
					-grid_parent ${wdir}/CBF-smooth5mm.nii \
					-map_func nzave \
					-outcols_results \
					-out_1D white/$my_out
			fi

			if [ ! -f "white/$my_out_norm" ]; then
				3dVol2Surf \
					-overwrite \
					-spec $spec \
					-surf_A $my_surf_A \
					-surf_B $my_surf_B \
					-sv SurfVol_Alnd_Exp+orig \
					-grid_parent ${wdir}/CBF_surf_norm.nii \
					-map_func nzave \
					-outcols_results \
					-out_1D white/$my_out_norm
			fi
		done
	done
done


#====================================================================================================================

# STEP 3: Convert the Subcortical Brainnetome to nifti, extract ROI stats

mri_convert --in_type mgz --out_type nii ${eig_dir}/Projects/Freesurfer/stable-v6.0.0/Linux/subjects/${subj}/mri/BN_Atlas_subcortex.mgz ${wdir}/alignSurf/BN_Atlas_subcortex.nii

cd ${wdir}/alignSurf
3dresample -master ${wdir}/CBF_surf_norm.nii -input BN_Atlas_subcortex.nii -prefix BN_subcortex_cbf-norm.rs.nii
3dresample -master ${wdir}/CBF-smooth5mm.nii -input BN_Atlas_subcortex.nii -prefix BN_subcortex_cbf.rs.nii

3dROIstats -mask BN_subcortex_cbf-norm.rs.nii ${wdir}/CBF_surf_norm.nii > CBF_norm_subcortex.1D
3dROIstats -mask BN_subcortex_cbf.rs.nii ${wdir}/CBF-smooth5mm.nii > CBF_subcortex.1D

#====================================================================================================================

# STEP 4: Apply Brainnetome atlas

# for now I am just doing this in std60 but you could use orig or a diff standard mesh
cd ${proj_mri_dir}/$subj/surf/xhemi/std60/orig/

# copy the 1D files for brainnetome, the cbf data, and the normalized cbf data to my folder
cp general/std.60.lh.BN_Atlas.annot.1D.dset ${wdir}/alignSurf/std.60.lh.BN_Atlas.annot.csv
cp general/std.60.rh.BN_Atlas.annot.1D.dset ${wdir}/alignSurf/std.60.rh.BN_Atlas.annot.csv

cp white/std.60.lh.CBF-avg.1D.dset ${wdir}/alignSurf/std.60.lh.CBF-avg.csv
cp white/std.60.rh.CBF-avg.1D.dset ${wdir}/alignSurf/std.60.rh.CBF-avg.csv

cp white/std.60.lh.CBF-avg.norm.1D.dset ${wdir}/alignSurf/std.60.lh.CBF-avg.norm.csv
cp white/std.60.rh.CBF-avg.norm.1D.dset ${wdir}/alignSurf/std.60.rh.CBF-avg.norm.csv

done





