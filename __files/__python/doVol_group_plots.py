#!python3

#====================================================================================================================

# Name: 		doVol_group_plots.py

# Author:   	Frederika Rentzeperis
# Date:     	4/20/2021
# Updated:      5/29/2021

# Syntax:       python doVol_group_plots.py
# Arguments:    --
# Description: Generates csv with the excluded parcels for each subject
# Requirements: --
# Notes: cd /Volumes/Shares/EEG/EIG/Users/IRTA/frederika/dev/ASL_scripts/__files/__python/ 

#====================================================================================================================

# IMPORT MODULES

## must get nibabel, nilearn (maybe?)
import numpy as np
import os
import matplotlib.pyplot as plt
import csv
import pandas as pd
import seaborn as sns
import scipy.stats
import scikit_posthocs

#==================================================================================================================


#VARIABLES
reg_dir = os.getcwd()

subjects = ['hv11','hv12','hv21','hv22','hv29','hv32','hv34','hv35','hv37','hv38','hv39','hv40','hv51','hv52','p78','p93','p98','p104','p105','p112','p115','p117','p122','p126','p127','p142','p144','p150','p151','p154','p163','p185','p186','p192']
laterality = ['B','B','B','B','B','B','B','B','B','B','B','B','B','B','L','L','L','R','R','R','L','L','L','L','R','L','L','L','R','R','R','L','L','R']


hv = ['hv11','hv12','hv21','hv22','hv29','hv32','hv34','hv35','hv37','hv38','hv39','hv40','hv51','hv52']
lesional = ['p78','p105','p117','p126','p144','p150','p151','p186','p192']
nonlesional = ['p93','p98','p104','p112','p115','p122','p127','p142','p154','p163','p185']


#====================================================================================================================

## LISTS OF THE REGIONAL AND FOCAL PARCEL NAMES ##

# Vector of the Regional Indices
regional_names = ['Frontal','LTL','MTL','Parietal','Insula','Limbic','Occipital','BG','Thalamus']

# Vector of the Focal Indices
focal_names = ['SFG','MFG','IFG','OrG','PrG','PCL','STG','MTG','ITG','FuG','PhG','pSTS','SPL','IPL','Pcun','PoG','INS','CG','MVOcC','LOcC','Amyg','Hipp','BG','Tha']

#====================================================================================================================
## CREATE EMPTY DICTIONARIES FOR THE REGIONS, TO BE POPULATED LATER ##

regions = {}
for i in regional_names:
    regions[i] = []

focal = {}
for i in focal_names:
    focal[i] = []

#====================================================================================================================    
subj_ind = 0
os.chdir("../../../../../Projects/ASL/regional_analysis")

for patient in subjects:    
    ## COLLECT SUBJECT DATA ##
    # Collect the Regional Subject Data
    patient_cbf_regional = np.genfromtxt(patient+"_regional_stats.1D",skip_header = 1,comments=None) #get roi data as vector
    patient_cbf_regional = np.delete(patient_cbf_regional,[0,1]) #remove non-number headers from first two rows
    patient_cbf_regional_rf = np.zeros((int(len(patient_cbf_regional)/3),2))
    patient_cbf_regional_rf[:,0] = list(range(1,int(len(patient_cbf_regional)/3+1))) #assign integer values corresponding to roi
    patient_cbf_regional_rf[:,1] = patient_cbf_regional[1::3] #obtain mean data for each roi
    patient_cbf_regional_rf[patient_cbf_regional_rf[:,1]<0,1] = 0 # clear unreasonable data (x<0)
    
    # Collect the Focal Subject Data
    patient_cbf_focal = np.genfromtxt(patient+"_focal_stats.1D",skip_header = 1,comments=None) #get roi data as vector
    patient_cbf_focal = np.delete(patient_cbf_focal,[0,1]) #remove non-number headers from first two rows
    patient_cbf_focal_rf = np.zeros((int(len(patient_cbf_focal)/3),2))
    patient_cbf_focal_rf[:,0] = list(range(1,int(len(patient_cbf_focal)/3+1))) #assign integer values corresponding to roi
    patient_cbf_focal_rf[:,1] = patient_cbf_focal[1::3] #obtain mean data for each roi
    patient_cbf_focal_rf[patient_cbf_focal_rf[:,1]<0,1] = 0 # clear unreasonable data (x<0)
        
    #====================================================================================================================
    
    ## SEPARATE RIGHT FROM LEFT DATA ##
    
    # Making empty matrices to allocate space for the lata
    patient_regional_l = np.zeros((int(len(patient_cbf_regional_rf)/2),2))
    patient_regional_r = np.zeros((int(len(patient_cbf_regional_rf)/2),2))
    
    patient_focal_l = np.zeros((int(len(patient_cbf_focal_rf)/2),2))
    patient_focal_r = np.zeros((int(len(patient_cbf_focal_rf)/2),2))
    
    # Separating the Regional Subject Data (odd is left, even is right)
    patient_regional_l[:,0] = patient_cbf_regional_rf[patient_cbf_regional_rf[:,0]%2!=0,0]
    patient_regional_l[:,1] = patient_cbf_regional_rf[patient_cbf_regional_rf[:,0]%2!=0,1]
    
    patient_regional_r[:,0] = patient_cbf_regional_rf[patient_cbf_regional_rf[:,0]%2==0,0]
    patient_regional_r[:,1] = patient_cbf_regional_rf[patient_cbf_regional_rf[:,0]%2==0,1]
    
    # Separating the Focal Subject Data (odd is left, even is right)
    patient_focal_l[:,0] = patient_cbf_focal_rf[patient_cbf_focal_rf[:,0]%2!=0,0]
    patient_focal_l[:,1] = patient_cbf_focal_rf[patient_cbf_focal_rf[:,0]%2!=0,1]
    
    patient_focal_r[:,0] = patient_cbf_focal_rf[patient_cbf_focal_rf[:,0]%2==0,0]
    patient_focal_r[:,1] = patient_cbf_focal_rf[patient_cbf_focal_rf[:,0]%2==0,1]
    

    #====================================================================================================================
    
    ## COLLECT THE DATA INTO ARRAYS ##
    
    subj_regional_array = np.zeros((len(patient_regional_l),3))
    
    subj_regional_array[:,0] = patient_regional_l[:,1]
    subj_regional_array[:,1] = patient_regional_r[:,1]
    
    # compute asymmetry index
    subj_regional_array[:,2] = np.absolute(np.divide(100*(patient_regional_l[:,1]-patient_regional_r[:,1]),(patient_regional_l[:,1]+patient_regional_r[:,1])/2))
    
    
    subj_focal_array = np.zeros((len(patient_focal_l),2))
    
    subj_focal_array[:,0] = patient_focal_l[:,1]
    subj_focal_array[:,1] = patient_focal_r[:,1]
    
    #====================================================================================================================

    ## POPULATE THE DICTIONARIES ##
    
    for j in range(0,len(regional_names)):
        regions[regional_names[j]] = regions[regional_names[j]]+[{'subj':patient,'left':subj_regional_array[j,0],'right':subj_regional_array[j,1],'AI':subj_regional_array[j,2],'laterality':laterality[subj_ind]}]
    
    for j in range(0,len(focal_names)):
        focal[focal_names[j]] = focal[focal_names[j]]+[{'subj':patient,'left':subj_focal_array[j,0],'right':subj_focal_array[j,1]}]

    subj_ind = subj_ind+1

# newpath1 = "regional_data"
# if not os.path.exists(newpath1):
#     os.makedirs(newpath1)  
    
# os.chdir(newpath1)
# for j in range(0,len(regional_names)):
#     with open(regional_names[j]+'_regional_data.csv', 'w', encoding='utf8', newline='') as output_file:
#         fc = csv.DictWriter(output_file, fieldnames= regions[regional_names[j]][0].keys())
#         fc.writeheader()
#         fc.writerows(regions[regional_names[j]])
        
# os.chdir("..") 

# newpath2 = "focal_data"
# if not os.path.exists(newpath2):
#     os.makedirs(newpath2)  
    
# os.chdir(newpath2)
# for j in range(0,len(focal_names)):
#     with open(focal_names[j]+'_focal_data.csv', 'w', encoding='utf8', newline='') as output_file:
#         fc = csv.DictWriter(output_file, fieldnames= focal[focal_names[j]][0].keys())
#         fc.writeheader()
#         fc.writerows(focal[focal_names[j]])
        
#====================================================================================================================
      
# ## PLOT THE REGIONAL DATA ##
# plt.scatter(, mean_cbf_divMed_r, s=3, alpha=0.5, label = "right")
# plt.scatter(, mean_cbf_divMed_l, s=3, alpha=0.5, c='grey', label = "left")
# plt.legend(bbox_to_anchor=(1.04,1), loc = "upper left")
# plt.title('Mean ROI CBF Values - divMed ('+lobe+')')
# plt.xlabel('Adjusted ROI index')
# plt.ylabel('Mean ROI/Voxel Median')
# plt.savefig(patient+'_cbf_divMed'+temp_loc+'-smooth5mm.png', bbox_inches="tight")
# plt.show()
LTL_df = pd.DataFrame(regions['LTL'])
MTL_df = pd.DataFrame(regions['MTL'])



# Compute statistics for the Lateral temporal lobe
LTL_hv_mean = np.mean(LTL_df['AI'][LTL_df['subj'].isin(hv)])
LTL_lesional_mean = np.mean(LTL_df['AI'][LTL_df['subj'].isin(lesional)])
LTL_nonlesional_mean = np.mean(LTL_df['AI'][LTL_df['subj'].isin(nonlesional)])

LTL_hv_sem = np.std(LTL_df['AI'][LTL_df['subj'].isin(hv)], ddof=1) / np.sqrt(np.size(LTL_df['AI'][LTL_df['subj'].isin(hv)]))
LTL_lesional_sem = np.std(LTL_df['AI'][LTL_df['subj'].isin(lesional)],ddof=1) / np.sqrt(np.size(LTL_df['AI'][LTL_df['subj'].isin(lesional)]))
LTL_nonlesional_sem = np.std(LTL_df['AI'][LTL_df['subj'].isin(nonlesional)],ddof=1) / np.sqrt(np.size(LTL_df['AI'][LTL_df['subj'].isin(nonlesional)]))

# Compute statistics for the Medial temporal lobe
MTL_hv_mean = np.mean(MTL_df['AI'][MTL_df['subj'].isin(hv)])
MTL_lesional_mean = np.mean(MTL_df['AI'][MTL_df['subj'].isin(lesional)])
MTL_nonlesional_mean = np.mean(MTL_df['AI'][MTL_df['subj'].isin(nonlesional)])

MTL_hv_sem = np.std(MTL_df['AI'][MTL_df['subj'].isin(hv)], ddof=1) / np.sqrt(np.size(MTL_df['AI'][MTL_df['subj'].isin(hv)]))
MTL_lesional_sem = np.std(MTL_df['AI'][MTL_df['subj'].isin(lesional)],ddof=1) / np.sqrt(np.size(MTL_df['AI'][MTL_df['subj'].isin(lesional)]))
MTL_nonlesional_sem = np.std(MTL_df['AI'][MTL_df['subj'].isin(nonlesional)],ddof=1) / np.sqrt(np.size(MTL_df['AI'][MTL_df['subj'].isin(nonlesional)]))


lobes =['LTL','MTL']
x_pos = np.arange(len(lobes))
hv_means = [LTL_hv_mean,MTL_hv_mean]
lesional_means = [LTL_lesional_mean,MTL_lesional_mean]
nonlesional_means = [LTL_nonlesional_mean,MTL_nonlesional_mean]

hv_error = [LTL_hv_sem,MTL_hv_sem]
lesional_error = [LTL_lesional_sem,MTL_lesional_sem]
nonlesional_error = [LTL_nonlesional_sem,MTL_nonlesional_sem]

# Generate the LTL and MTL plots
width = 0.7/3

fig, ax = plt.subplots()
rects1 = ax.bar(x_pos - width, hv_means, width, label='Volunteer',yerr=hv_error,capsize=10,color = "steelblue",linewidth=1,edgecolor='black')
rects2 = ax.bar(x_pos, lesional_means, width, label='Lesional',yerr = lesional_error,capsize=10,color = "sienna",linewidth=1,edgecolor='black')
rects3 = ax.bar(x_pos + width, nonlesional_means, width, label='Non-Lesional',yerr = nonlesional_error,capsize=10, color = "khaki",linewidth=1,edgecolor='black')
ax.set_ylabel('Absolute Value of Asymmetry Index',fontsize=13)
ax.set_xticks(x_pos)
ax.set_xticklabels(lobes,fontsize=12)
ax.set_yticks(np.linspace(0, 16, 5))
plt.setp(ax.get_yticklabels(), fontsize=12)
ax.legend(loc='upper center', bbox_to_anchor=(0.5, 1.05),
          ncol=3, fancybox=True, shadow=True,fontsize=11)
plt.ylim(0,16)
fig.tight_layout()
plt.savefig('vol-AI-LTL-MTL.png')
plt.show()


#====================================================================================================================

## CHECK STATISTICAL SIGNIFICANCE ##
# First do Kruskal Wallis
scipy.stats.kruskal(LTL_df['AI'][LTL_df['subj'].isin(hv)], LTL_df['AI'][LTL_df['subj'].isin(lesional)], LTL_df['AI'][LTL_df['subj'].isin(nonlesional)])
scipy.stats.kruskal(MTL_df['AI'][MTL_df['subj'].isin(hv)], MTL_df['AI'][MTL_df['subj'].isin(lesional)], MTL_df['AI'][MTL_df['subj'].isin(nonlesional)])

# Then since LTL and MTL are significant, carry out pairwise Mann–Whitney U tests
scikit_posthocs.posthoc_dunn([LTL_df['AI'][LTL_df['subj'].isin(hv)], LTL_df['AI'][LTL_df['subj'].isin(lesional)]],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([LTL_df['AI'][LTL_df['subj'].isin(hv)], LTL_df['AI'][LTL_df['subj'].isin(nonlesional)]],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([LTL_df['AI'][LTL_df['subj'].isin(lesional)], LTL_df['AI'][LTL_df['subj'].isin(nonlesional)]],p_adjust='bonferroni')

scikit_posthocs.posthoc_dunn([MTL_df['AI'][MTL_df['subj'].isin(hv)], MTL_df['AI'][MTL_df['subj'].isin(lesional)]],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([MTL_df['AI'][MTL_df['subj'].isin(hv)], MTL_df['AI'][MTL_df['subj'].isin(nonlesional)]],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([MTL_df['AI'][MTL_df['subj'].isin(lesional)], MTL_df['AI'][MTL_df['subj'].isin(nonlesional)]],p_adjust='bonferroni')

#====================================================================================================================

## DIVIDED BY MEDIAN PLOTTING LTL ##
LTL_ipsi_lesional_r = LTL_df['right'][LTL_df['laterality']=='R'][LTL_df['subj'].isin(lesional)]
LTL_ipsi_lesional_l = LTL_df['left'][LTL_df['laterality']=='L'][LTL_df['subj'].isin(lesional)]
LTL_contra_lesional_r = LTL_df['left'][LTL_df['laterality']=='R'][LTL_df['subj'].isin(lesional)]
LTL_contra_lesional_l = LTL_df['right'][LTL_df['laterality']=='L'][LTL_df['subj'].isin(lesional)]
LTL_ipsi_lesional = pd.concat([LTL_ipsi_lesional_r,LTL_ipsi_lesional_l])
LTL_contra_lesional = pd.concat([LTL_contra_lesional_r,LTL_contra_lesional_l])
LTL_ipsi_divmed_les_mean = np.mean(LTL_ipsi_lesional)
LTL_contra_divmed_les_mean = np.mean(LTL_contra_lesional)
LTL_ipsi_divmed_les_sem = np.std(LTL_ipsi_lesional,ddof=1)/ np.sqrt(np.size(LTL_ipsi_lesional))
LTL_contra_divmed_les_sem = np.std(LTL_contra_lesional,ddof=1)/np.sqrt(np.size(LTL_contra_lesional))

LTL_ipsi_nonlesional_r = LTL_df['right'][LTL_df['laterality']=='R'][LTL_df['subj'].isin(nonlesional)]
LTL_ipsi_nonlesional_l = LTL_df['left'][LTL_df['laterality']=='L'][LTL_df['subj'].isin(nonlesional)]
LTL_contra_nonlesional_r = LTL_df['left'][LTL_df['laterality']=='R'][LTL_df['subj'].isin(nonlesional)]
LTL_contra_nonlesional_l = LTL_df['right'][LTL_df['laterality']=='L'][LTL_df['subj'].isin(nonlesional)]
LTL_ipsi_nonlesional = pd.concat([LTL_ipsi_nonlesional_r,LTL_ipsi_nonlesional_l])
LTL_contra_nonlesional = pd.concat([LTL_contra_nonlesional_r,LTL_contra_nonlesional_l])
LTL_ipsi_divmed_non_mean = np.mean(LTL_ipsi_nonlesional)
LTL_contra_divmed_non_mean = np.mean(LTL_contra_nonlesional)
LTL_ipsi_divmed_non_sem = np.std(LTL_ipsi_nonlesional,ddof=1)/ np.sqrt(np.size(LTL_ipsi_nonlesional))
LTL_contra_divmed_non_sem = np.std(LTL_contra_nonlesional,ddof=1)/np.sqrt(np.size(LTL_contra_nonlesional))

LTL_hv_ipsi_contra_l = LTL_df['left'][LTL_df['subj'].isin(hv)]
LTL_hv_ipsi_contra_r = LTL_df['right'][LTL_df['subj'].isin(hv)]
LTL_hv_ipsi_contra = pd.concat([LTL_hv_ipsi_contra_r,LTL_hv_ipsi_contra_l])
LTL_hv_divmed_mean = np.mean(LTL_hv_ipsi_contra)
LTL_hv_divmed_sem = np.std(LTL_hv_ipsi_contra,ddof=1)/np.sqrt(np.size(LTL_hv_ipsi_contra))


## DIVIDED BY MEDIAN PLOTTING MTL ##
MTL_ipsi_lesional_r = MTL_df['right'][MTL_df['laterality']=='R'][MTL_df['subj'].isin(lesional)]
MTL_ipsi_lesional_l = MTL_df['left'][MTL_df['laterality']=='L'][MTL_df['subj'].isin(lesional)]
MTL_contra_lesional_r = MTL_df['left'][MTL_df['laterality']=='R'][MTL_df['subj'].isin(lesional)]
MTL_contra_lesional_l = MTL_df['right'][MTL_df['laterality']=='L'][MTL_df['subj'].isin(lesional)]
MTL_ipsi_lesional = pd.concat([MTL_ipsi_lesional_r,MTL_ipsi_lesional_l])
MTL_contra_lesional = pd.concat([MTL_contra_lesional_r,MTL_contra_lesional_l])
MTL_ipsi_divmed_les_mean = np.mean(MTL_ipsi_lesional)
MTL_contra_divmed_les_mean = np.mean(MTL_contra_lesional)
MTL_ipsi_divmed_les_sem = np.std(MTL_ipsi_lesional,ddof=1)/ np.sqrt(np.size(MTL_ipsi_lesional))
MTL_contra_divmed_les_sem = np.std(MTL_contra_lesional,ddof=1)/np.sqrt(np.size(MTL_contra_lesional))

MTL_ipsi_nonlesional_r = MTL_df['right'][MTL_df['laterality']=='R'][MTL_df['subj'].isin(nonlesional)]
MTL_ipsi_nonlesional_l = MTL_df['left'][MTL_df['laterality']=='L'][MTL_df['subj'].isin(nonlesional)]
MTL_contra_nonlesional_r = MTL_df['left'][MTL_df['laterality']=='R'][MTL_df['subj'].isin(nonlesional)]
MTL_contra_nonlesional_l = MTL_df['right'][MTL_df['laterality']=='L'][MTL_df['subj'].isin(nonlesional)]
MTL_ipsi_nonlesional = pd.concat([MTL_ipsi_nonlesional_r,MTL_ipsi_nonlesional_l])
MTL_contra_nonlesional = pd.concat([MTL_contra_nonlesional_r,MTL_contra_nonlesional_l])
MTL_ipsi_divmed_non_mean = np.mean(MTL_ipsi_nonlesional)
MTL_contra_divmed_non_mean = np.mean(MTL_contra_nonlesional)
MTL_ipsi_divmed_non_sem = np.std(MTL_ipsi_nonlesional,ddof=1)/ np.sqrt(np.size(MTL_ipsi_nonlesional))
MTL_contra_divmed_non_sem = np.std(MTL_contra_nonlesional,ddof=1)/np.sqrt(np.size(MTL_contra_nonlesional))

MTL_hv_ipsi_contra_l = MTL_df['left'][MTL_df['subj'].isin(hv)]
MTL_hv_ipsi_contra_r = MTL_df['right'][MTL_df['subj'].isin(hv)]
MTL_hv_ipsi_contra = pd.concat([MTL_hv_ipsi_contra_r,MTL_hv_ipsi_contra_l])
MTL_hv_divmed_mean = np.mean(MTL_hv_ipsi_contra)
MTL_hv_divmed_sem = np.std(MTL_hv_ipsi_contra,ddof=1)/np.sqrt(np.size(MTL_hv_ipsi_contra))

## GENERATE THE FIGURE ##
width = 0.7/5

fig, ax = plt.subplots()
rects1 = ax.bar(x_pos - 2*width, [LTL_hv_divmed_mean,MTL_hv_divmed_mean], width, label='HV',linewidth=1,yerr=[LTL_hv_divmed_sem,MTL_hv_divmed_sem],capsize=10,edgecolor='black',color = "steelblue")
rects2 = ax.bar(x_pos-width, [LTL_ipsi_divmed_les_mean,MTL_ipsi_divmed_les_mean], width, label='LI',linewidth=1,yerr=[LTL_ipsi_divmed_les_sem,MTL_ipsi_divmed_les_sem],capsize=10,edgecolor='black',color = "sienna")
rects3 = ax.bar(x_pos, [LTL_contra_divmed_les_mean,MTL_contra_divmed_les_mean], width, label='LC',linewidth=1,yerr=[LTL_contra_divmed_les_sem,MTL_contra_divmed_les_sem],capsize=10,edgecolor='black',color = "teal")
rects4 = ax.bar(x_pos + width, [LTL_ipsi_divmed_non_mean,MTL_ipsi_divmed_non_mean], width, label='NI',linewidth=1,yerr=[LTL_ipsi_divmed_non_sem,MTL_ipsi_divmed_non_sem],capsize=10,edgecolor='black',color = "khaki")
rects5 = ax.bar(x_pos + 2*width, [LTL_contra_divmed_non_mean,MTL_contra_divmed_non_mean], width, label='NC', linewidth=1,yerr=[LTL_contra_divmed_non_sem,MTL_contra_divmed_non_sem],capsize=10,edgecolor='black',color = "grey")
ax.set_ylabel('Normalized CBF',fontsize=13)
ax.set_xticks(x_pos)
ax.set_xticklabels(lobes,fontsize=12)
ax.set_yticks(np.linspace(0.7, 1.2, 6))
plt.setp(ax.get_yticklabels(), fontsize=12)
ax.legend(loc='upper center', bbox_to_anchor=(0.5, 1.05),
          ncol=5, fancybox=True, shadow=True,fontsize=11)
plt.ylim(0.7,1.3)
fig.tight_layout()
plt.savefig('vol-divMed-LTL-MTL.png')
plt.show()


scipy.stats.kruskal(LTL_hv_ipsi_contra,LTL_ipsi_lesional,LTL_contra_lesional,LTL_ipsi_nonlesional,LTL_contra_nonlesional)
scikit_posthocs.posthoc_dunn([LTL_hv_ipsi_contra,LTL_ipsi_lesional],p_adjust='bonferroni') #sig
scikit_posthocs.posthoc_dunn([LTL_hv_ipsi_contra,LTL_contra_lesional],p_adjust='bonferroni') #sig
scikit_posthocs.posthoc_dunn([LTL_hv_ipsi_contra,LTL_ipsi_nonlesional],p_adjust='bonferroni') #sig
scikit_posthocs.posthoc_dunn([LTL_hv_ipsi_contra,LTL_contra_nonlesional],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([LTL_ipsi_lesional,LTL_contra_lesional],p_adjust='bonferroni') #sig
scikit_posthocs.posthoc_dunn([LTL_ipsi_lesional,LTL_ipsi_nonlesional],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([LTL_ipsi_lesional,LTL_contra_nonlesional],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([LTL_contra_lesional,LTL_ipsi_nonlesional],p_adjust='bonferroni') # sig
scikit_posthocs.posthoc_dunn([LTL_contra_lesional,LTL_contra_nonlesional],p_adjust='bonferroni') # sig
scikit_posthocs.posthoc_dunn([LTL_ipsi_nonlesional,LTL_contra_nonlesional],p_adjust='bonferroni')

scipy.stats.kruskal(MTL_hv_ipsi_contra,MTL_ipsi_lesional,MTL_contra_lesional,MTL_ipsi_nonlesional,MTL_contra_nonlesional)
scikit_posthocs.posthoc_dunn([MTL_hv_ipsi_contra,MTL_ipsi_lesional],p_adjust='bonferroni') # sig
scikit_posthocs.posthoc_dunn([MTL_hv_ipsi_contra,MTL_contra_lesional],p_adjust='bonferroni') 
scikit_posthocs.posthoc_dunn([MTL_hv_ipsi_contra,MTL_ipsi_nonlesional],p_adjust='bonferroni') # sig
scikit_posthocs.posthoc_dunn([MTL_hv_ipsi_contra,MTL_contra_nonlesional],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([MTL_ipsi_lesional,MTL_contra_lesional],p_adjust='bonferroni') # sig
scikit_posthocs.posthoc_dunn([MTL_ipsi_lesional,MTL_ipsi_nonlesional],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([MTL_ipsi_lesional,MTL_contra_nonlesional],p_adjust='bonferroni')
scikit_posthocs.posthoc_dunn([MTL_contra_lesional,MTL_ipsi_nonlesional],p_adjust='bonferroni') # sig
scikit_posthocs.posthoc_dunn([MTL_contra_lesional,MTL_contra_nonlesional],p_adjust='bonferroni')# sig
scikit_posthocs.posthoc_dunn([MTL_ipsi_nonlesional,MTL_contra_nonlesional],p_adjust='bonferroni')

#====================================================================================================================

## the following is if you are trying to get the scatter plot ##

# LTL_df['subj'][LTL_df['subj'].isin(hv)] = 'hv'
# LTL_df['subj'][LTL_df['subj'].isin(lesional)] = 'lesional'
# LTL_df['subj'][LTL_df['subj'].isin(nonlesional)] = 'nonlesional'

# plt.figure(1)
# sns.stripplot(LTL_df['subj'],LTL_df['AI'], jitter = 0.2)
# plt.xlabel('Subject')
# plt.ylabel('Asymmetry Index')
# plt.title('Lateral Temporal Lobe - Asymmetry Index')
# plt.show()


os.chdir("..")






