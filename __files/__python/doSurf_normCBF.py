#!python3

#====================================================================================================================

# Name: 		doSurf_normCBF.py

# Author:   	Frederika Rentzeperis
# Date:     	8/20/2020
# Updated:      5/29/2021

# Syntax:       python doSurf_normCBF.py
# Arguments:    --
# Description:  Compute divide by median normalization from cbf data
# Requirements: --
# Notes:  		

#====================================================================================================================

# IMPORT MODULES

## must get nibabel, nilearn (maybe?)
import numpy as np
import matplotlib.pyplot as plt
import os
import nibabel as nb
# import nilearn as nl
import sys
# import pathlib as Path
#==================================================================================================================


#VARIABLES
#subj = input(f'Enter desired subject number: ')
if len(sys.argv) != 2:
    print("you must input patient number. repeat from python step")
    exit()

subj = str(sys.argv[1])


reg_dir = os.getcwd()

# obtain the image
cbf_img = nb.load('CBF-smooth5mm.nii') # get the cbf nifti

arr_cbf_img = cbf_img.get_fdata() # turn nifti into numpy array

# get median of brain masked cbf
os.chdir("../proc/")
msk_data = np.loadtxt(subj+'_cbf_values-smooth5mm.1D')
cbf_med = np.median(msk_data)

os.chdir("../reg")
    
## NORMALIZE DATA (divide by median)
# Divide data by population median
med_arr = np.divide(arr_cbf_img,cbf_med)
med_img = nb.Nifti1Image(med_arr,cbf_img.affine, header = cbf_img.header)
nb.save(med_img, 'CBF_surf_norm.nii')



