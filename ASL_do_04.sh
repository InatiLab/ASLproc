#!/bin/bash -i

#====================================================================================================================

# Name: 		ASL_do_04.sh		

# Author:   	Frederika Rentzeperis
# Date:     	04/06/2021
# Updated:      05/25/2021

# Syntax:   ./ASL_do_04.sh [-ss_a] [-ss_b] SUBJ	    

# Arguments:    SUBJ:subject code

# Description: this script calculates cbf, then registers both research mprage and cbf datasets to the MNI152 template
# Requirements: 
# Main outputs: 
# Notes: 		

# TODO

#====================================================================================================================
#INPUT

if [ "$#" -eq 1 ] && [[ $1 != "-ss_a" ]] && [[ $1 != "-ss_b" ]]; then
	subj=$1
elif [ "$#" -eq 2 ] && [[ $1 == "-ss_a" ]]; then
	subj=$2
elif [ "$#" -eq 2 ] && [[ $1 == "-ss_b" ]]; then
	subj=$2
fi

# set usage
function display_usage {
    echo -e "\033[0;35m++ usage: $0 [-ss_a|skullstrip_a] [-ss_b|skullstrip_b] SUBJ ++\033[0m"
    exit 1
}

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
scripts_dir="${eig_dir}/Scripts_and_Parameters/scripts"
proj_dir="${eig_dir}/Projects"
top_dir=${eig_dir}/Projects/ASL/$subj

if [[ -d ${eig_dir}/Projects/MRI/$subj ]]; then
	ref_img=${eig_dir}/Projects/MRI/$subj/reg/t1.nii
elif [[ -d ${eig_dir}/Projects/MRI/__alternateMRIs/$subj ]]; then
	ref_img=${eig_dir}/Projects/MRI/__alternateMRIs/$subj/reg/t1.nii
fi

subj_asl_dir=${proj_dir}/ASL/${subj}
echo ${subj_asl_dir}
subj_orig_dir=${subj_asl_dir}/orig
wdir=${subj_asl_dir}/reg
proj_mri_dir=${eig_dir}/Projects/MRI
	
#====================================================================================================================
	
#DATA CHECK

	if [ -d "$subj_orig_dir" ]; then
		echo -e "\033[0;35m++ Working on $subj... ++\033[0m"
		cd ${subj_asl_dir}
		if [ ! -d "$wdir" ]; then
			mkdir -p ${wdir}
		fi
		if [ ! -d "$wdir/alignMNI" ]; then
			mkdir -p ${wdir}/alignMNI 
		fi
		
	else
		echo -e "\033[0;35m++ Subject $subj does not have orig folder. Please check /Projects/ASL_katie/${subj} or run raw_func_to_nifti. Exiting... ++\033[0m"
		exit 1
	fi


# look for grey matter/white matter classification data

if [[ -f "${proj_mri_dir}/${subj}/clf/y_class.nii" ]]; then
	echo -e "\033[0;35m++ Classification data for $subj exists in regular MRIs directory. ++\033[0m"
	subj_mri_dir=${proj_mri_dir}/$subj
	pre_clf_dir=${subj_mri_dir}/clf


elif [[ -f "${proj_mri_dir}/__alternateMRIs/$subj/fsl/y_class.nii" ]]; then
	echo -e "\033[0;35m++ Classification data for $subj exists in alternate MRIs directory. ++\033[0m"
	subj_mri_dir=${proj_mri_dir}/__alternateMRIs/$subj
	pre_clf_dir=${subj_mri_dir}/surf

else
	echo -e "\033[0;35m++ $subj is missing clf classifiers for preop scan. Please run run Do_00*, Do_01*, Do_02* . Exiting...  ++\033[0m"
	exit 1
fi

#====================================================================================================================


#STEP 1: pick scans

	cd ${wdir}
	if [ -f "mprage.nii" ] && [ -f "asl.nii" ]; then
		echo -e "\033[0;35m++ Continuing... ++\033[0m"
		cp mprage.nii ${wdir}/alignMNI/mprage_reg.nii
		cp asl.nii ${wdir}/alignMNI/asl_reg.nii
	else
		echo -e "\033[0;35m++ MPRAGE/ASL not selected. Please select an image. Exiting... ++\033[0m"
		exit 1
	fi
#====================================================================================================================

# STEP 2: calculate CBF

# remove zeros from ASL data
# set negative cbf values to zero
	3dcalc -expr 'posval(a)' -a asl.nii -prefix asl-pos.nii 

# generate CBF from the positive ASL data
if [ ! -f "CBF.nii" ]; then
	source activate jem
	python3 ${pwd_dir}/__files/__python/doVol_calcCBF.py
	conda deactivate
fi

3dcopy CBF.nii alignMNI/cbf.nii

#====================================================================================================================

#STEP 3: use AFNI skull strip algorithm to create brain mask

cd ${wdir}/alignMNI

if [ ! -f cbf.nii ]; then
	echo -e "\033[0;35m++ Python script failed to execute, no cbf data. Rerun script. Exiting... ++\033[0m"
	exit 1
fi
if [ $1 == "-ss_a" ]; then
	echo -e "\033[0;35m++ Carrying out first alternative skull strip method (fwhm2, dilate 5). ++\033[0m"
	if [ "${pre_clf_dir}" = "${subj_mri_dir}/clf" ]; then
		if [ ! -f mprage.msk.d.nii ]; then
			if [ ! -f mprage_reg.ss.nii ]; then
				echo -e "\033[0;35m++ Skull stripping T1-registered mprage scan via afni ++\033[0m"
				3dSkullStrip -overwrite					\
					-prefix mprage_reg.ss-fwhm.nii 			\
					-input mprage_reg.nii				\
					-blur_fwhm 2 					\
					-use_skull
			fi

			3dAutomask -overwrite 						\
				-prefix mprage.msk.nii 					\
				mprage_reg.ss-fwhm.nii

			3dmask_tool 							\
				-input mprage.msk.nii 					\
				-prefix mprage.msk.d.nii 				\
				-dilate_input 5
		else
			echo -e "\033[0;35m++ Preop skull strip afni mask has already been created ++\033[0m"
		fi
	fi

elif [ $1 == "-ss_b" ]; then
	echo -e "\033[0;35m++ Carrying out second alternative skull strip method (fwhm2, dilate 8). ++\033[0m"
	if [ "${pre_clf_dir}" = "${subj_mri_dir}/clf" ]; then
		if [ ! -f mprage.msk.d.nii ]; then
			if [ ! -f mprage_reg.ss.nii ]; then
				echo -e "\033[0;35m++ Skull stripping T1-registered mprage scan via afni ++\033[0m"
				3dSkullStrip -overwrite					\
					-prefix mprage_reg.ss-fwhm.nii 			\
					-input mprage_reg.nii				\
					-blur_fwhm 2 					\
					-use_skull
			fi

			3dAutomask -overwrite 						\
				-prefix mprage.msk.nii 					\
				mprage_reg.ss-fwhm.nii

			3dmask_tool 							\
				-input mprage.msk.nii 					\
				-prefix mprage.msk.d.nii 				\
				-dilate_input 8
		else
			echo -e "\033[0;35m++ Preop skull strip afni mask has already been created ++\033[0m"
		fi
	fi
else
	echo -e "\033[0;35m++ Skull Stripping. ++\033[0m"
	if [ "${pre_clf_dir}" = "${subj_mri_dir}/clf" ]; then
		if [ ! -f mprage.msk.d.nii ]; then
			if [ ! -f mprage_reg.ss.nii ]; then
				echo -e "\033[0;35m++ Skull stripping T1-registered mprage scan via afni ++\033[0m"
				3dSkullStrip -overwrite					\
					-prefix mprage_reg.ss.nii			\
					-ld 33					\
					-niter 777				\
					-shrink_fac_bot_lim 0.777 		\
					-exp_frac 0.0666 			\
					-input mprage_reg.nii
			fi

			3dAutomask -overwrite 						\
				-prefix mprage.msk.nii 				\
				mprage_reg.ss.nii

			3dmask_tool 							\
				-input mprage.msk.nii 				\
				-prefix mprage.msk.d.nii 				\
				-dilate_input 5
		else
			echo -e "\033[0;35m++ Preop skull strip afni mask has already been created ++\033[0m"
		fi
	fi	
fi

#====================================================================================================================

# STEP 4: skull strip y_class files

if [ ! -f brain.msk.nii ]; then
	echo -e "\033[0;35m++ Creating preop brain mask ++\033[0m"

	if [ "${pre_clf_dir}" = "${subj_mri_dir}/clf" ]; then
		3dcalc \
				-a ${pre_clf_dir}/y_class.nii \
				-b mprage.msk.d.nii \
				-exp 'amongst(a,3,4)*b' \
				-prefix brain.msk.nii

	elif [ "${pre_clf_dir}" = "${subj_mri_dir}/surf" ]; then

		3dcalc -a ${pre_clf_dir}/aseg_rank_Alnd_Exp.nii -expr 'step(a)' -prefix aseg.msk.nii

		3dresample -master mprage_reg.nii -input aseg.msk.nii -prefix brain.msk.nii
	fi
else
	echo -e "\033[0;35m++ Skull stripped preop brain mask already exists ++\033[0m"
fi

#====================================================================================================================

# STEP 5: Align center & warp mprage to MNI152 space

echo -e "\033[0;35m++ lets align mprage & asl centers to MNI152 template center ++\033[0m"
@Align_Centers \
	-base  MNI152_2009_template_SSW.nii.gz 			\
	-dset  mprage_reg.nii 					\
	-child cbf.nii brain.msk.nii			   

echo -e "\033[0;35m++ then skull-strip and warp anatomical scan to the MNI space  ++\033[0m"


# the following essentially follows all the steps of SSwarper

if [ ! -f brain.msk.rs.nii ]; then
	3dresample -master mprage_reg_shft.nii -input brain.msk_shft.nii -prefix brain.msk.rs.nii

	3dcalc -a mprage_reg_shft.nii -b brain.msk.rs.nii -expr 'a*b' -prefix mprage_msk_shft.nii

	3dUnifize -prefix mprage_msk_shft_U.nii -input mprage_msk_shft.nii

	3dAllineate -prefix mprage_allineate.nii -base /usr/local/afni/MNI152_2009_template_SSW.nii.gz -source mprage_msk_shft.nii -twopass -cost lpa -1Dmatrix_save mprage_allineate.aff12.1D -autoweight -fineblur 3 -cmass
	
	3dQwarp -prefix mprage_mni.nii -blur 0 3 -base /usr/local/afni/MNI152_2009_template_SSW.nii.gz -source mprage_allineate.nii	

else
	echo -e "\033[0;35m++ Skull stripped preop brain mask already exists ++\033[0m"
fi


#====================================================================================================================

#putting the cbf and the brain mask in the same grid
3dresample -master cbf_shft.nii -input brain.msk_shft.nii -prefix cbf.brain.msk.rs.nii

#intersecting the brain.msk.nii binary mask with cbf_shft.nii
3dcalc -expr 'a*b' -a cbf_shft.nii -b cbf.brain.msk.rs.nii -prefix cbf_ss_shft.nii


#====================================================================================================================

#STEP 7: Applying 3dNwarpApply to shifted & skullstripped cbf dataset

3dNwarpApply \
    -nwarp 'mprage_mni_WARP.nii mprage_allineate.aff12.1D' 	\
    -master mprage_mni.nii						\
    -source cbf_ss_shft.nii						\
    -prefix cbf_ss_mni.nii						\
    -interp NN								\
    -overwrite      



