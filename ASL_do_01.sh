#!/bin/bash -i

#====================================================================================================================

# Name: 		ASL_do_01.sh

# Author:   	Frederika Rentzeperis (Adapted from Katie Snyder)
# Date:     	4/6/21
# Updated:      5/29/21

# Syntax:       ./ASL_do_01.sh [-lpa] [-lpaZZ] [-noEdge] SUBJ
# Arguments:    SUBJ: subject ID
# Description:  Asks to choose MPRAGE and ASL images. Then, aligned ASL to MPRAGE and MPRAGE to clinical T1.
# Requirements: 1) AFNI
#				2) You will need python installed and an environment set up to run python2 called p2.7
# Notes

#====================================================================================================================

# INPUT

if [ "$#" -eq 1 ] && [[ $1 != "-lpa" ]] && [[ $1 != "-lpaZZ" ]] && [[ $1 != "-noEdge" ]]; then
	subj=$1
elif [ "$#" -eq 2 ] && [[ $1 == "-lpa" ]]; then
	subj=$2
elif [ "$#" -eq 2 ] && [[ $1 == "-lpaZZ" ]]; then
	subj=$2
elif [ "$#" -eq 2 ] && [[ $1 == "-noEdge" ]]; then
	subj=$2
else
	echo -e "\033[0;35m++ usage: $0 [-lpa] [-lpaZZ] [-noEdge] SUBJ_ID  ++\033[0m"
	exit 1
fi

#---------------------------------------------------------------------------------------------------------------------

# VARIABLES

pwd_dir=`pwd`
scripts_dir=${pwd_dir%/*}
top_scripts_dir=${scripts_dir%/*}
eig_dir=${top_scripts_dir%/*}

#-----------------------------


top_dir=${eig_dir}/Projects/ASL/$subj
if [[ -d ${eig_dir}/Projects/MRI/$subj ]]; then
	ref_img=${eig_dir}/Projects/MRI/$subj/reg/t1.nii
elif [[ -d ${eig_dir}/Projects/MRI/__alternateMRIs/$subj ]]; then
	ref_img=${eig_dir}/Projects/MRI/__alternateMRIs/$subj/reg/t1.nii
fi

orig_dir=${top_dir}/orig
wdir=${top_dir}/reg

#---------------------------------------------------------------------------------------------------------------------

# DATA CHECK

if [ -f "${ref_img}" ]; then
	if [ -d "${orig_dir}" ]; then
		echo -e "\033[0;35m++ Working on $subj... ++\033[0m"
		cd $orig_dir
		if [ ! -d "$wdir" ]; then
			mkdir -p $wdir
		fi
		if [ ! -f "$wdir/t1.nii" ]; then
			cp -r ${ref_img} $wdir/t1.nii
		fi
	else
		echo -e "\033[0;35m++ Subject $subj does not have ASL data. Please run raw_func_to_nifti. Exiting... ++\033[0m"
		exit 1
	fi
else
	echo -e "\033[0;35m++ Subject $subj does not have aligned clinical T1. Please run registration.sh. Exiting... ++\033[0m"
	exit 1
fi

#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================

# STEP 1: pick scans and register

if [ -f "mprage.nii" ]; then
	echo -e "\033[0;35m++ mprage already selected. Please delete to reselect. ++\033[0m"
else
	echo -e "\033[0;35m++ Options: ++\033[0m"
	for img in *_20*.nii; do
		if [ -f "$img" ]; then
			ni=`3dinfo -ni $img`
			nj=`3dinfo -nj $img`
			nk=`3dinfo -nk $img`
			echo "$img"
			echo "	dimensions = $ni x $nj x $nk"
		fi
	done
	echo -e "\033[0;35m++ Please choose mprage. Enter Y to choose. ++\033[0m"
	for img in mprage_2*.nii; do
		if [ -f "$img" ]; then
			echo "$img"
			read ynresponse
			if [ "$ynresponse" == "Y" ]; then
				3dcopy $img mprage.nii
				img_noext=${img//.nii}
				temp=${img_noext%%'20'*}
				date_time=${img_noext//${temp}}
				stime=${img_noext##*'_'}
				sdate=${date_time%%'_'*}
				echo "$sdate $stime" >> mprage_info.txt
			fi
		fi
	done
fi

#-------------------------

if [ -f "asl.nii" ]; then
	echo -e "\033[0;35m++ ASL already selected. Please delete to reselect. ++\033[0m"
else
	echo -e "\033[0;35m++ ASL Options: ++\033[0m"
	for img in *.nii; do
		if [ -f "$img" ]; then
			ni=`3dinfo -ni $img`
			nj=`3dinfo -nj $img`
			nk=`3dinfo -nk $img`
			echo "$img"
			echo "	dimensions = $ni x $nj x $nk"
		fi
	done
	echo -e "\033[0;35m++ Please choose ASL. Enter Y to choose. ++\033[0m"
	for img in asl_*.nii; do
		if [ -f "$img" ]; then
			echo "$img"
			read ynresponse
			if [ "$ynresponse" == "Y" ]; then
				3dcopy $img asl.nii
				img_noext=${img//.nii}
				temp=${img_noext%%'20'*}
				date_time=${img_noext//${temp}}
				stime=${img_noext##*'_'}
				sdate=${date_time%%'_'*}
				echo "$sdate $stime" >> asl_info.txt
				my_cbf="cbf_${sdate}_${stime}.nii"
				if [ -f "$my_cbf" ]; then
					3dcopy $my_cbf cbf.nii
				fi
			fi
		fi
	done
fi

#-------------------------

if [ -f "mprage.nii" ] && [ -f "asl.nii" ]; then
	echo -e "\033[0;35m++ Continuing... ++\033[0m"
else
	echo -e "\033[0;35m++ MPRAGE/ASL not selected. Please select an image. Exiting... ++\033[0m"
	exit 1
fi

#====================================================================================================================

# STEP 2: register

cd ${wdir}

if [ -f "${orig_dir}/mprage.nii" ] || [ -f "${orig_dir}/asl.nii" ]; then
	if [ ! -f "mprage.nii" ]; then
		my_1D="mprage_2_t1"
		3dAllineate \
			-base t1.nii	\
			-master t1.nii \
			-1Dmatrix_save mprage_2_t1 \
			-input ${orig_dir}/mprage.nii \
			-cost nmi \
			-prefix mprage.nii
	fi

	if [ ! -d "__al2mprage" ]; then
		mkdir -p __al2mprage
	fi
	cd __al2mprage
	for img in 'asl.nii' 'mprage.nii'; do
		if [ ! -f "$img" ]; then
			cp -r ${orig_dir}/$img .
		fi
	done
	
# below is the choice between the various options for the ASL-to-mprage alignment
	if [ $1 == "-lpa" ]; then
		if [ ! -f "asl_al+orig.HEAD" ]; then
			echo -e "\033[0;35m++ Aligning ASL with edge option and lpa cost function. ++\033[0m"
			source activate p2.7
			align_epi_anat.py \
				-anat mprage.nii \
				-epi asl.nii \
				-epi_base 1 \
				-epi2anat \
				-big_move \
				-rigid_body \
				-partial_coverage \
				-cost lpa \
				-edge \
				-suffix _al
			conda deactivate
		fi

	elif [ $1 == "-lpaZZ" ]; then
		echo -e "\033[0;35m++ Aligning ASL with edge option and lpa+ZZ cost function. ++\033[0m"
		if [ ! -f "asl_al+orig.HEAD" ]; then
			source activate p2.7
			align_epi_anat.py \
				-anat mprage.nii \
				-epi asl.nii \
				-epi_base 1 \
				-epi2anat \
				-big_move \
				-rigid_body \
				-partial_coverage \
				-cost lpa+ZZ \
				-edge \
				-suffix _al
			conda deactivate
		fi

	elif [ $1 == "-noEdge" ]; then
		echo -e "\033[0;35m++ Aligning ASL without edge option and nmi cost function. ++\033[0m"
		if [ ! -f "asl_al+orig.HEAD" ]; then
			source activate p2.7
			align_epi_anat.py \
				-anat mprage.nii \
				-epi asl.nii \
				-epi_base 1 \
				-epi2anat \
				-big_move \
				-rigid_body \
				-partial_coverage \
				-cost nmi \
				-suffix _al
			conda deactivate
		fi

	else
		echo -e "\033[0;35m++ Aligning ASL with edge option and nmi cost function. ++\033[0m"
		if [ ! -f "asl_al+orig.HEAD" ]; then
			source activate p2.7
			align_epi_anat.py \
				-anat mprage.nii \
				-epi asl.nii \
				-epi_base 1 \
				-epi2anat \
				-big_move \
				-rigid_body \
				-partial_coverage \
				-cost nmi \
				-edge \
				-suffix _al
			conda deactivate
		fi
	fi
else
	echo -e "\033[0;35m++ MPRAGE/ASL not selected. Please run this script again and choose MPRAGE/ASL. ++\033[0m"
fi

#====================================================================================================================
