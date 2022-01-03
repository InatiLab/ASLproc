#!/bin/bash -i

#====================================================================================================================

# Name: 		ASL_do_01.sh

# Author:   	Frederika Rentzeperis (Adapted from Katie Snyder)
# Date:     	4/6/21
# Updated:      5/29/21

# Syntax:       ./ASL_do_01.sh [-lpa] [-lpaZZ] [-noEdge] SUBJ
# Arguments:    SUBJ: subject ID
# Description:  Axialize clinical mprage with respect to TT_N27 template, then aligned research mprage to axialized clinical mprage (t1.nii) 
#				followed by aligning ASL to research MPRAGE.
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

scripts_dir=`pwd`
top_dir=${scripts_dir%/*}
data_dir=${top_dir}/data
orig_dir=${data_dir}/${subj}/orig
wdir=${data_dir}/${subj}/reg

#---------------------------------------------------------------------------------------------------------------------

# DATA CHECK

if [[ -f "${orig_dir}/mprage_research.nii" ]] && [[ -f "${orig_dir}/mprage_clinical.nii" ]] && [[ -f "${orig_dir}/asl.nii" ]]; then
	echo -e "\033[0;35m++ Working on $subj... ++\033[0m"
	if [ ! -d "$wdir" ]; then
		mkdir -p $wdir
	fi
	if [ ! -d "${wdir}/t1w_align" ]; then
		mkdir -p ${wdir}/t1w_align
	fi
else
	echo -e "\033[0;35m++ Subject $subj does not have the required files. Please copy the necessary files to the data directory.  Exiting... ++\033[0m"
	exit 1
fi


#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================

# STEP 1: Axialize clinical mprage with respect to TT_N27 template

if [ -a "${wdir}/t1w_align/t1w_FINAL.nii.gz" ]; then

    echo -e "\033[0;35m++ Axialized T1 already exists. ++\033[0m"
else
    fat_proc_axialize_anat                          \
        -inset   ${orig_dir}/mprage_clinical.nii        \
        -refset  ${scripts_dir}/__files/TT_N27.nii          \
        -prefix  ${wdir}/t1w_align/t1w_FINAL                          \
        -mode_t1w         							\
		-extra_al_inps "-nomask"					\
		-focus_by_ss							
                            
fi

cd ${wdir}

if [ ! -f "t1.nii" ]; then
	3dcalc \
		-a t1w_align/t1w_FINAL.nii.gz \
		-prefix t1.nii \
		-datum short \
		-expr 'a'
fi

#====================================================================================================================

# STEP 2: coregister research mprage to the axialized T1 as well as ASL to coregister research mprage

if [ ! -f "mprage.nii" ]; then
	my_1D="mprage_2_t1"
	3dAllineate \
		-base t1.nii	\
		-master t1.nii \
		-1Dmatrix_save mprage_2_t1 \
		-input ${orig_dir}/mprage_research.nii \
		-cost nmi \
		-prefix mprage.nii
fi


if [ ! -d "__al2mprage" ]; then
	mkdir -p __al2mprage
fi
cd __al2mprage

cp -r ${orig_dir}/asl.nii  ./asl.nii
cp -r ${orig_dir}/mprage_research.nii  ./mprage.nii

	
# Below is the choice between the various options for the ASL-to-mprage alignment
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

#====================================================================================================================
