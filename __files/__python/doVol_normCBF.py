#!python3

#====================================================================================================================

# Name: 		doVol_normCBF.py

# Author:   	Frederika Rentzeperis
# Date:     	8/20/2020
# Updated:      5/27/2021

# Syntax:       python doVol_normCBF.py SUBJ
# Arguments:    --
# Description:  Normalize cbf data (div by median)
# Requirements: --
# Notes:  		

#====================================================================================================================

# IMPORT MODULES

import numpy as np
import os
import nibabel as nb
import sys

#==================================================================================================================


#VARIABLES
#subj = input(f'Enter desired subject number: ')
if len(sys.argv) != 2:
    print("you must input patient number. repeat from python step")
    exit()

subj = str(sys.argv[1])


reg_dir = os.getcwd()
print(reg_dir)

# obtain the image
nii_img = nb.load('cbf_mni-smooth5mm.nii') # get the cbf nifti
arr_img = nii_img.get_fdata() # turn nifti into numpy array

# get median of brain voxels
gm_data = np.loadtxt(subj+'_cbf_values-smooth5mm.1D')
gm_med = np.median(gm_data)


newpath = subj+'_standardize_cbf'
if not os.path.exists(newpath):
    os.makedirs(newpath)
    
os.chdir(newpath)
    
# divide data by population median
med_arr = np.divide(arr_img,gm_med)
med_img = nb.Nifti1Image(med_arr,nii_img.affine, header = nii_img.header)
nb.save(med_img, subj+'_cbf_divMed-smooth5mm.nii')





