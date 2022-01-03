#!python3

#====================================================================================================================

# Name: 		doVol_normParcel.py

# Author:   	Frederika Rentzeperis
# Date:     	2/12/2021
# Updated:      5/29/2021

# Syntax:       python doVol_normParcel.py
# Arguments:    --
# Description:  make AI and div med parcellations
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
subj = input(f'Enter desired subject number: ')

reg_dir = os.getcwd()
os.chdir("../../../../../Projects/ASL/"+subj+"/proc/"+subj+"_standardize_cbf")
                     
roi_data_cbf = np.genfromtxt(subj+"_cbf_ROI_stats-smooth5mm.1D",skip_header = 1,comments=None) #get roi data as vector
roi_data_cbf = np.delete(roi_data_cbf,[0,1]) #remove non-number headers from first two rows
roi_data_divMed = np.genfromtxt(subj+"_divMed_cbf_ROI_stats-smooth5mm.1D",skip_header = 1,comments=None) #get roi data as vector
roi_data_divMed = np.delete(roi_data_divMed,[0,1]) #remove non-number headers from first two rows

roi_cbf_rf = np.zeros((int(len(roi_data_cbf)/3),3)) #make zero array to input the mean and stdv data
roi_divMed_rf = np.zeros((int(len(roi_data_divMed)/3),3)) #make zero array to input the mean and stdv data

roi_cbf_rf[:,0] = list(range(1,int(len(roi_data_cbf)/3+1))) #assign integer values corresponding to roi
roi_cbf_rf[:,1] = roi_data_cbf[1::3] #obtain mean data for each roi
roi_cbf_rf[:,2] = roi_data_cbf[2::3] #obtain stdv data for each roi
roi_divMed_rf[:,0] = list(range(1,int(len(roi_data_divMed)/3+1))) #assign integer values corresponding to roi
roi_divMed_rf[:,1] = roi_data_divMed[1::3] #obtain mean data for each roi
roi_divMed_rf[:,2] = roi_data_divMed[2::3] #obtain stdv data for each roi

## COMPUTE ASYMMETRY INDEX FROM CBF DATA
ind_ai = roi_cbf_rf[:,0]
mean_y_ai = roi_cbf_rf[:,1]

mean_r_ai = np.zeros(int(len(mean_y_ai)/2))
mean_l_ai= np.zeros(int(len(mean_y_ai)/2))

old_r_ind = np.zeros(int(len(mean_y_ai)/2))
old_l_ind = np.zeros(int(len(mean_y_ai)/2))

for roi in range(0,int(len(mean_y_ai))):
    if ind_ai[roi]%2 == 0:
        r_ind_ai = (roi-1)/2
        mean_r_ai[int(r_ind_ai)] = mean_y_ai[roi]
        old_r_ind[int(r_ind_ai)] = ind_ai[roi] # for making the niftii
    elif ind_ai[roi]%2 != 0:
        l_ind_ai = roi/2
        mean_l_ai[int(l_ind_ai)] = mean_y_ai[roi]
        old_l_ind[int(l_ind_ai)] = ind_ai[roi] # for making the niftii
                
short_ind_ai = roi_cbf_rf[range(0,int(len(mean_y_ai)/2)),0]

# AI = 100 * [left - left] / [(left + right)/2]
ai_num = np.multiply([sum(items) for items in zip(mean_l_ai, -1 * mean_r_ai)],100)
ai_den = np.multiply([sum(items) for items in zip(mean_l_ai, mean_r_ai)],0.5)
ai_r = np.divide(ai_num,ai_den)

ai_l = np.multiply(ai_r,-1)

# restore the original ROI indices to the ai, concatenate the lists
ai_r_rf = np.zeros((int(len(mean_y_ai)/2),2))
ai_r_rf[:,0] = old_r_ind
ai_r_rf[:,1] = ai_r

ai_l_rf = np.zeros((int(len(mean_y_ai)/2),2))
ai_l_rf[:,0] = old_l_ind
ai_l_rf[:,1] = ai_l

ai = np.vstack((ai_r_rf,ai_l_rf))

# create a dictionary of the mean and stdv values to roi index
ai_dict = dict(zip(ai[:,0],ai[:,1]))
ai_dict[0] = 0
ai_dict_vec = np.vectorize(ai_dict.get, otypes=[np.float])
mean_dict_divMed = dict(zip(roi_divMed_rf[:,0],roi_divMed_rf[:,1]))
mean_dict_divMed[0] = 0
mean_dict_divMed_vec = np.vectorize(mean_dict_divMed.get, otypes=[np.float])

# obtain the image
nii_img_cbf = nb.load('BN_atlas_cbf-smooth5mm.rs.nii') # get the nifti
nii_img_divMed = nb.load('BN_atlas_cbf_divMed-smooth5mm.rs.nii') # get the nifti

arr_img_cbf = nii_img_cbf.get_fdata() # turn nifti into numpy array
arr_img_divMed = nii_img_divMed.get_fdata() # turn nifti into numpy array

newpath = subj+"_standardize_analysis"
if not os.path.exists(newpath):
    os.makedirs(newpath)
    
os.chdir(newpath)

ai_arr = ai_dict_vec(arr_img_cbf)
ai_img = nb.Nifti1Image(ai_arr,nii_img_cbf.affine, header = nii_img_cbf.header)
nb.save(ai_img, subj+'_BN_ai-smooth5mm.nii')    

mean_arr_divMed = mean_dict_divMed_vec(arr_img_divMed)
mean_img_divMed = nb.Nifti1Image(mean_arr_divMed,nii_img_divMed.affine, header = nii_img_divMed.header)
nb.save(mean_img_divMed, subj+'_BN_divMed-smooth5mm.nii')
