#!python3

#====================================================================================================================

# Name: 		doVol_calcCBF.py

# Author:   	Frederika Rentzeperis
# Date:     	4/29/21
# Updated:      

# Syntax:       python3 doVol_calcCBF.py 
# Arguments:    --
# Description:  Calculate CBF image based on input from Dr. Talagala
# Requirements: --
# Notes:  		Called in ASL_do_02.sh

#====================================================================================================================

# IMPORT MODULES

import numpy as np
import nibabel
import sys
import os
from pathlib import Path
from jem.signal_stats import global_scale
from jem.filters import _pinv

#====================================================================================================================

# VARIABLES

alpha = 0.8*0.75 #eff labeling efficiency incl background suppression
T1a = 1.6 #blood T1 at 3T (s)
T1tis = 1.2 #GM T1 to rescale partially saturated M0 (s)
labdur = 1.5 #labeling duration (s)
postlabdly = 1.525 #post labeling delay (s)
sattime = 2.0 #TR for M0 image (s)
nexpw = 4.0 #num excitations for PW images
sfpw = 32.0 #scale factor for PW images
l = 0.9 #ml/g

#---------------------------------------------------------------------------------------------------------------------

# FUNCTIONS

def saveNifti(data, ref_im, output):
	if type(data) == list:
		data = np.stack(data, axis=-1)

	out_im = type(ref_im)(data, affine=None, header=ref_im.header)
	out_im.set_data_dtype(np.float32)
	out_im.to_filename(output)

#====================================================================================================================
# BEGIN SCRIPT
#====================================================================================================================

# STEP 1: load in data

asl = nibabel.load('asl-pos.nii')

data = asl.get_fdata().astype(np.float32)
nvox = data.shape[0]*data.shape[1]*data.shape[2]
X = data.reshape([nvox,-1])
dS = X[:,0]
S0 = X[:,1]

#====================================================================================================================

# STEP 2: calculate CBF

scalefact = 6000*l*np.exp(postlabdly/T1a)*(1-np.exp(-sattime/T1tis))/(2*alpha*T1a*(1-np.exp(-labdur/T1a))*nexpw*sfpw)

_, _, sigma = global_scale(S0)
S0_inv = _pinv(S0, sigma)
CBF = scalefact*dS*S0_inv
#====================================================================================================================

# STEP 3: save out

CBF = CBF.reshape([data.shape[0], data.shape[1], data.shape[2]])
saveNifti(CBF, asl, 'CBF.nii')

#====================================================================================================================
