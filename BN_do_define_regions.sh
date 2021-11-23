#!/bin/bash -i

#====================================================================================================================

# Name: 		BN_do_define_regions.sh		

# Author:   	Frederika Rentzeperis
# Date:     	04/28/2021
# Updated:	05/29/2021

# Syntax:   bash BN_do_define_regions.sh
# Arguments:    SUBJ: 		subject code

# Description: Creates the regional and focal brainnetome atlases
# Requirements: 
# Main outputs: 
# Notes: 		

# TODO

#====================================================================================================================

## MAKE NUMERICAL NIFTI FOR THE BRAINNETOME ATLAS (MULT BY 1) ##

pwd_dir=`pwd`
scripts_dir=${pwd_dir%/*}
top_scripts_dir=${scripts_dir%/*}
eig_dir=${top_scripts_dir%/*}

asl_dir=${eig_dir}/Projects/ASL
brainnetome_dir=${asl_dir}/brainnetome
files_dir=${pwd_dir}/__files

if [ ! -d "${asl_dir}/brainnetome" ]; then
	cd ${asl_dir}/
	mkdir -p ${brainnetome_dir}
else
	echo -e "\033[0;35m++ Brainnetome directory already exists, please delete... ++\033[0m"
	exit 1
fi

cp ${files_dir}/BN_Atlas_246_1mm.nii.gz ${brainnetome_dir}/BN_Atlas_246_1mm.nii.gz

cd ${brainnetome_dir}
3dcalc -a BN_Atlas_246_1mm.nii.gz -expr '1*a' -prefix BN_Atlas_numeric.nii


#====================================================================================================================

## GENERATE ALL THE REGIONAL NIFTI FILES ##

3dcalc -a BN_Atlas_numeric.nii -expr '1*amongst(a,1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,67)' -prefix bn_lh_region_frontal.nii
3dcalc -a BN_Atlas_numeric.nii -expr '3*amongst(a,69,71,73,75,77,79,81,83,85,87,89,91,93,95,97,99,101,103,105,107,121,123)' -prefix bn_lh_region_ltl.nii
3dcalc -a BN_Atlas_numeric.nii -expr '5*amongst(a,211,213,215,217,109,111,113,115,117,119)' -prefix bn_lh_region_mtl.nii
3dcalc -a BN_Atlas_numeric.nii -expr '7*amongst(a,125,127,129,131,133,135,137,139,141,143,145,147,149,151,153,155,157,159,161)' -prefix bn_lh_region_parietal.nii
3dcalc -a BN_Atlas_numeric.nii -expr '9*amongst(a,163,165,167,169,171,173)' -prefix bn_lh_region_insula.nii
3dcalc -a BN_Atlas_numeric.nii -expr '11*amongst(a,175,177,179,181,183,185,187)' -prefix bn_lh_region_limbic.nii
3dcalc -a BN_Atlas_numeric.nii -expr '13*amongst(a,189,191,193,195,197,199,201,203,205,207,209)' -prefix bn_lh_region_occipital.nii
3dcalc -a BN_Atlas_numeric.nii -expr '15*amongst(a,219,221,223,225,227,229)' -prefix bn_lh_region_bg.nii
3dcalc -a BN_Atlas_numeric.nii -expr '17*amongst(a,231,233,235,237,239,241,243,245)' -prefix bn_lh_region_thalamus.nii
3dcalc -a BN_Atlas_numeric.nii -expr '2*amongst(a,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62,64,66,68)' -prefix bn_rh_region_frontal.nii
3dcalc -a BN_Atlas_numeric.nii -expr '4*amongst(a,70,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102,104,106,108,122,124)' -prefix bn_rh_region_ltl.nii
3dcalc -a BN_Atlas_numeric.nii -expr '6*amongst(a,212,214,216,218,110,112,114,116,118,120)' -prefix bn_rh_region_mtl.nii
3dcalc -a BN_Atlas_numeric.nii -expr '8*amongst(a,126,128,130,132,134,136,138,140,142,144,146,148,150,152,154,156,158,160,162)' -prefix bn_rh_region_parietal.nii
3dcalc -a BN_Atlas_numeric.nii -expr '10*amongst(a,164,166,168,170,172,174)' -prefix bn_rh_region_insula.nii
3dcalc -a BN_Atlas_numeric.nii -expr '12*amongst(a,176,178,180,182,184,186,188)' -prefix bn_rh_region_limbic.nii
3dcalc -a BN_Atlas_numeric.nii -expr '14*amongst(a,190,192,194,196,198,200,202,204,206,208,210)' -prefix bn_rh_region_occipital.nii
3dcalc -a BN_Atlas_numeric.nii -expr '16*amongst(a,220,222,224,226,228,230)' -prefix bn_rh_region_bg.nii
3dcalc -a BN_Atlas_numeric.nii -expr '18*amongst(a,232,234,236,238,240,242,244,246)' -prefix bn_rh_region_thalamus.nii

# anterior and posterior LTL
3dcalc -a BN_Atlas_numeric.nii -expr '3*amongst(a,69, 73, 77, 79, 83, 87, 89, 93, 95, 103)' -prefix bn_lh_regional_anterior_LTL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '19*amongst(a,71, 75, 81, 85, 91, 97, 99, 101, 105, 107, 121, 123)' -prefix bn_lh_regional_posterior_LTL.nii

3dcalc -a BN_Atlas_numeric.nii -expr '4*amongst(a,70, 74, 78, 80, 84, 88, 90, 94, 96, 104)' -prefix bn_rh_regional_anterior_LTL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '20*amongst(a,72, 76, 82, 86, 92, 98, 100, 102, 106, 108, 122, 124)' -prefix bn_rh_regional_posterior_LTL.nii

## MERGE THE REGIONS INTO ONE ATLAS ##

3dcalc -a bn_lh_region_frontal.nii -b bn_lh_region_ltl.nii -c bn_lh_region_mtl.nii -d bn_lh_region_parietal.nii -e bn_lh_region_insula.nii -f bn_lh_region_limbic.nii -g bn_lh_region_occipital.nii -h bn_lh_region_bg.nii -i bn_lh_region_thalamus.nii -j bn_rh_region_frontal.nii -k bn_rh_region_ltl.nii -l bn_rh_region_mtl.nii -m bn_rh_region_parietal.nii -n bn_rh_region_insula.nii -o bn_rh_region_limbic.nii -p bn_rh_region_occipital.nii -q bn_rh_region_bg.nii -r bn_rh_region_thalamus.nii -expr 'a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+r' -prefix BN_Atlas_regional.nii

3dcalc -a bn_lh_region_frontal.nii -b bn_lh_regional_anterior_LTL.nii -c bn_lh_region_mtl.nii -d bn_lh_region_parietal.nii -e bn_lh_region_insula.nii -f bn_lh_region_limbic.nii -g bn_lh_region_occipital.nii -h bn_lh_region_bg.nii -i bn_lh_region_thalamus.nii -j bn_rh_region_frontal.nii -k bn_rh_regional_anterior_LTL.nii -l bn_rh_region_mtl.nii -m bn_rh_region_parietal.nii -n bn_rh_region_insula.nii -o bn_rh_region_limbic.nii -p bn_rh_region_occipital.nii -q bn_rh_region_bg.nii -r bn_rh_region_thalamus.nii -s bn_lh_regional_posterior_LTL.nii -t bn_rh_regional_posterior_LTL.nii -expr 'a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+r+s+t' -prefix BN_Atlas_regional_all-apLTL.nii


#====================================================================================================================

## GENERATE ALL THE FOCAL NIFTI FILES ##

3dcalc -a BN_Atlas_numeric.nii -expr '1*amongst(a,1, 3, 5, 7, 9, 11, 13)' -prefix bn_lh_focal_SFG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '3*amongst(a,15, 17, 19, 21, 23, 25, 27)' -prefix bn_lh_focal_MFG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '5*amongst(a,29, 31, 33, 35, 37, 39)' -prefix bn_lh_focal_IFG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '7*amongst(a,41, 43, 45, 47, 49, 51)' -prefix bn_lh_focal_OrG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '9*amongst(a,53, 55, 57, 59, 61, 63)' -prefix bn_lh_focal_PrG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '11*amongst(a,65, 67)' -prefix bn_lh_focal_PCL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '13*amongst(a,69, 71, 73, 75, 77, 79)' -prefix bn_lh_focal_STG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '15*amongst(a,81, 83, 85, 87)' -prefix bn_lh_focal_MTG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '17*amongst(a,89, 91, 93, 95, 97, 99, 101)' -prefix bn_lh_focal_ITG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '19*amongst(a,103, 105, 107)' -prefix bn_lh_focal_FuG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '21*amongst(a,109, 111, 113, 115, 117, 119)' -prefix bn_lh_focal_PhG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '23*amongst(a,121, 123)' -prefix bn_lh_focal_pSTS.nii
3dcalc -a BN_Atlas_numeric.nii -expr '25*amongst(a,125, 127, 129, 131, 133)' -prefix bn_lh_focal_SPL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '27*amongst(a,135, 137, 139, 141, 143, 145)' -prefix bn_lh_focal_IPL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '29*amongst(a,147, 149, 151, 153)' -prefix bn_lh_focal_Pcun.nii
3dcalc -a BN_Atlas_numeric.nii -expr '31*amongst(a,155, 157, 159, 161)' -prefix bn_lh_focal_PoG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '33*amongst(a,163, 165, 167, 169, 171, 173)' -prefix bn_lh_focal_INS.nii
3dcalc -a BN_Atlas_numeric.nii -expr '35*amongst(a,175, 177, 179, 181, 183, 185, 187)' -prefix bn_lh_focal_CG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '37*amongst(a,189, 191, 193, 195, 197)' -prefix bn_lh_focal_MVOcC.nii
3dcalc -a BN_Atlas_numeric.nii -expr '39*amongst(a,199, 201, 203, 205, 207, 209)' -prefix bn_lh_focal_LOcC.nii
3dcalc -a BN_Atlas_numeric.nii -expr '41*amongst(a,211, 213)' -prefix bn_lh_focal_Amyg.nii
3dcalc -a BN_Atlas_numeric.nii -expr '43*amongst(a,215, 217)' -prefix bn_lh_focal_Hipp.nii
3dcalc -a BN_Atlas_numeric.nii -expr '45*amongst(a,219, 221, 223, 225, 227, 229)' -prefix bn_lh_focal_BG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '47*amongst(a,231, 233, 235, 237, 239, 241, 243, 245)' -prefix bn_lh_focal_Tha.nii

3dcalc -a BN_Atlas_numeric.nii -expr '2*amongst(a,2, 4, 6, 8, 10, 12, 14)' -prefix bn_rh_focal_SFG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '4*amongst(a,16, 18, 20, 22, 24, 26, 28)' -prefix bn_rh_focal_MFG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '6*amongst(a,30, 32, 34, 36, 38, 40)' -prefix bn_rh_focal_IFG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '8*amongst(a,42, 44, 46, 48, 50, 52)' -prefix bn_rh_focal_OrG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '10*amongst(a,54, 56, 58, 60, 62, 64)' -prefix bn_rh_focal_PrG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '12*amongst(a,66, 68)' -prefix bn_rh_focal_PCL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '14*amongst(a,70, 72, 74, 76, 78, 80)' -prefix bn_rh_focal_STG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '16*amongst(a,82, 84, 86, 88)' -prefix bn_rh_focal_MTG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '18*amongst(a,90, 92, 94, 96, 98, 100, 102)' -prefix bn_rh_focal_ITG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '20*amongst(a,104, 106, 108)' -prefix bn_rh_focal_FuG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '22*amongst(a,110, 112, 114, 116, 118, 120)' -prefix bn_rh_focal_PhG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '24*amongst(a,122, 124)' -prefix bn_rh_focal_pSTS.nii
3dcalc -a BN_Atlas_numeric.nii -expr '26*amongst(a,126, 128, 130, 132, 134)' -prefix bn_rh_focal_SPL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '28*amongst(a,136, 138, 140, 142, 144, 146)' -prefix bn_rh_focal_IPL.nii
3dcalc -a BN_Atlas_numeric.nii -expr '30*amongst(a,148, 150, 152, 154)' -prefix bn_rh_focal_Pcun.nii
3dcalc -a BN_Atlas_numeric.nii -expr '32*amongst(a,156, 158, 160, 162)' -prefix bn_rh_focal_PoG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '34*amongst(a,164, 166, 168, 170, 172, 174)' -prefix bn_rh_focal_INS.nii
3dcalc -a BN_Atlas_numeric.nii -expr '36*amongst(a,176, 178, 180, 182, 184, 186, 188)' -prefix bn_rh_focal_CG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '38*amongst(a,190, 192, 194, 196, 198)' -prefix bn_rh_focal_MVOcC.nii
3dcalc -a BN_Atlas_numeric.nii -expr '40*amongst(a,200, 202, 204, 206, 208, 210)' -prefix bn_rh_focal_LOcC.nii
3dcalc -a BN_Atlas_numeric.nii -expr '42*amongst(a,212, 214)' -prefix bn_rh_focal_Amyg.nii
3dcalc -a BN_Atlas_numeric.nii -expr '44*amongst(a,216, 218)' -prefix bn_rh_focal_Hipp.nii
3dcalc -a BN_Atlas_numeric.nii -expr '46*amongst(a,220, 222, 224, 226, 228, 230)' -prefix bn_rh_focal_BG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '48*amongst(a,232, 234, 236, 238, 240, 242, 244, 246)' -prefix bn_rh_focal_Tha.nii

# anterior and posterior LTL
3dcalc -a BN_Atlas_numeric.nii -expr '13*amongst(a,69, 73, 77, 79)' -prefix bn_lh_focal_anterior_STG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '49*amongst(a,71, 75)' -prefix bn_lh_focal_posterior_STG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '15*amongst(a,83, 87)' -prefix bn_lh_focal_anterior_MTG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '51*amongst(a,81, 85)' -prefix bn_lh_focal_posterior_MTG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '17*amongst(a,89, 93, 95)' -prefix bn_lh_focal_anterior_ITG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '53*amongst(a,91, 97, 99, 101)' -prefix bn_lh_focal_posterior_ITG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '19*amongst(a,103)' -prefix bn_lh_focal_anterior_FuG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '55*amongst(a,105, 107)' -prefix bn_lh_focal_posterior_FuG.nii

3dcalc -a BN_Atlas_numeric.nii -expr '14*amongst(a,70, 74, 78, 80)' -prefix bn_rh_focal_anterior_STG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '50*amongst(a,72, 76)' -prefix bn_rh_focal_posterior_STG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '16*amongst(a,84, 88)' -prefix bn_rh_focal_anterior_MTG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '52*amongst(a,82, 86)' -prefix bn_rh_focal_posterior_MTG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '18*amongst(a, 90, 94, 96)' -prefix bn_rh_focal_anterior_ITG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '54*amongst(a, 92, 98, 100, 102)' -prefix bn_rh_focal_posterior_ITG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '20*amongst(a,104)' -prefix bn_rh_focal_anterior_FuG.nii
3dcalc -a BN_Atlas_numeric.nii -expr '56*amongst(a,106, 108)' -prefix bn_rh_focal_posterior_FuG.nii


## MERGE THE FOCAL PARCELS INTO RIGHT AND LEFT HAND ATLASES ##
3dcalc -a bn_lh_focal_SFG.nii -b bn_lh_focal_MFG.nii -c bn_lh_focal_IFG.nii -d bn_lh_focal_OrG.nii -e bn_lh_focal_PrG.nii -f bn_lh_focal_PCL.nii -g bn_lh_focal_STG.nii -h bn_lh_focal_MTG.nii -i bn_lh_focal_ITG.nii -j bn_lh_focal_FuG.nii -k bn_lh_focal_PhG.nii -l bn_lh_focal_pSTS.nii -m bn_lh_focal_SPL.nii -n bn_lh_focal_IPL.nii -o bn_lh_focal_Pcun.nii -p bn_lh_focal_PoG.nii -q bn_lh_focal_INS.nii -r bn_lh_focal_CG.nii -s bn_lh_focal_MVOcC.nii -t bn_lh_focal_LOcC.nii -u bn_lh_focal_Amyg.nii -v bn_lh_focal_Hipp.nii -w bn_lh_focal_BG.nii -x bn_lh_focal_Tha.nii -expr 'a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+r+s+t+u+v+w+x' -prefix BN_Atlas_lh_focal.nii

3dcalc -a bn_lh_focal_SFG.nii -b bn_lh_focal_MFG.nii -c bn_lh_focal_IFG.nii -d bn_lh_focal_OrG.nii -e bn_lh_focal_PrG.nii -f bn_lh_focal_PCL.nii -k bn_lh_focal_PhG.nii -m bn_lh_focal_SPL.nii -n bn_lh_focal_IPL.nii -o bn_lh_focal_Pcun.nii -p bn_lh_focal_PoG.nii -q bn_lh_focal_INS.nii -r bn_lh_focal_CG.nii -s bn_lh_focal_MVOcC.nii -t bn_lh_focal_LOcC.nii -u bn_lh_focal_Amyg.nii -v bn_lh_focal_Hipp.nii -w bn_lh_focal_BG.nii -x bn_lh_focal_Tha.nii -expr 'a+b+c+d+e+f+k+m+n+o+p+q+r+s+t+u+v+w+x' -prefix BN_Atlas_lh_focal_noLTL.nii

3dcalc -a bn_lh_focal_anterior_STG.nii -b bn_lh_focal_posterior_STG.nii -c bn_lh_focal_anterior_MTG.nii -d bn_lh_focal_posterior_MTG.nii -e bn_lh_focal_anterior_ITG.nii -f bn_lh_focal_posterior_ITG.nii -g bn_lh_focal_anterior_FuG.nii -h bn_lh_focal_posterior_FuG.nii -i bn_lh_focal_pSTS.nii -expr 'a+b+c+d+e+f+g+h+i' -prefix BN_Atlas_lh_focal_LTL.nii

3dcalc -a BN_Atlas_lh_focal_noLTL.nii -b BN_Atlas_lh_focal_LTL.nii -expr 'a+b' -prefix BN_Atlas_lh_focal_all-apLTL.nii


3dcalc -a bn_rh_focal_SFG.nii -b bn_rh_focal_MFG.nii -c bn_rh_focal_IFG.nii -d bn_rh_focal_OrG.nii -e bn_rh_focal_PrG.nii -f bn_rh_focal_PCL.nii -g bn_rh_focal_STG.nii -h bn_rh_focal_MTG.nii -i bn_rh_focal_ITG.nii -j bn_rh_focal_FuG.nii -k bn_rh_focal_PhG.nii -l bn_rh_focal_pSTS.nii -m bn_rh_focal_SPL.nii -n bn_rh_focal_IPL.nii -o bn_rh_focal_Pcun.nii -p bn_rh_focal_PoG.nii -q bn_rh_focal_INS.nii -r bn_rh_focal_CG.nii -s bn_rh_focal_MVOcC.nii -t bn_rh_focal_LOcC.nii -u bn_rh_focal_Amyg.nii -v bn_rh_focal_Hipp.nii -w bn_rh_focal_BG.nii -x bn_rh_focal_Tha.nii -expr 'a+b+c+d+e+f+g+h+i+j+k+l+m+n+o+p+q+r+s+t+u+v+w+x' -prefix BN_Atlas_rh_focal.nii

3dcalc -a bn_rh_focal_SFG.nii -b bn_rh_focal_MFG.nii -c bn_rh_focal_IFG.nii -d bn_rh_focal_OrG.nii -e bn_rh_focal_PrG.nii -f bn_rh_focal_PCL.nii -k bn_rh_focal_PhG.nii -m bn_rh_focal_SPL.nii -n bn_rh_focal_IPL.nii -o bn_rh_focal_Pcun.nii -p bn_rh_focal_PoG.nii -q bn_rh_focal_INS.nii -r bn_rh_focal_CG.nii -s bn_rh_focal_MVOcC.nii -t bn_rh_focal_LOcC.nii -u bn_rh_focal_Amyg.nii -v bn_rh_focal_Hipp.nii -w bn_rh_focal_BG.nii -x bn_rh_focal_Tha.nii -expr 'a+b+c+d+e+f+k+m+n+o+p+q+r+s+t+u+v+w+x' -prefix BN_Atlas_rh_focal_noLTL.nii

3dcalc -a bn_rh_focal_anterior_STG.nii -b bn_rh_focal_posterior_STG.nii -c bn_rh_focal_anterior_MTG.nii -d bn_rh_focal_posterior_MTG.nii -e bn_rh_focal_anterior_ITG.nii -f bn_rh_focal_posterior_ITG.nii -g bn_rh_focal_anterior_FuG.nii -h bn_rh_focal_posterior_FuG.nii -i bn_rh_focal_pSTS.nii -expr 'a+b+c+d+e+f+g+h+i' -prefix BN_Atlas_rh_focal_LTL.nii

3dcalc -a BN_Atlas_rh_focal_noLTL.nii -b BN_Atlas_rh_focal_LTL.nii -expr 'a+b' -prefix BN_Atlas_rh_focal_all-apLTL.nii


## COMBINE THE LEFT AND RIGHT FOCAL ATLASES ##
3dcalc -a BN_Atlas_lh_focal.nii -b BN_Atlas_rh_focal.nii -expr 'a+b' -prefix BN_Atlas_focal.nii
3dcalc -a BN_Atlas_lh_focal_all-apLTL.nii -b BN_Atlas_rh_focal_all-apLTL.nii -expr 'a+b' -prefix BN_Atlas_focal_all-apLTL.nii

