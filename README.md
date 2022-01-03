# ASLproc
Pre-Processing for Volumetric Analysis of Arterial Spin Labeling(ASL) Data
Once you clone this repository, you should have a directory tree like the following:
```
ASL/scripts/
   /data/
```
Then you would copy over your subjects' dataset to the data directroy with the following name conventions: 
```
ASL/scripts
   /data                    
      /mprage_clinical.nii
      /mprage_research.nii
      /asl.nii
```
                                
Note: for this project, you need to install AFNI (https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/index.html), and JEM python module (pip install jem)    

## processing steps:                
```
./ASL_do_01.sh [-lpa] [-lpaZZ] [-noEdge] SUBJ
```
- This script will first axialize clinical mprage with respect to TT_N27 template, place them under reg direcotry as t1.nii.  
- After that, it coregisters the research mprage to t1.nii and ASL data to research mprage.

- **CHECK: compare ${subj}/reg/mprage.nii, reg/t1.nii**

```
./ASL_do_02.sh SUBJ

```
- This script uses the linear transformation from step 1 to register ASL to the clinical t1.
- For some patients, the asl-to-mprage registration fails. In this case, there are several options you can try. The default script uses nmi cost function with the edge option and rigid body option. If this fails, delete the reg folder and retry ASL_do_01 using the following options. Also repeat ASL_do_02.sh
    - ASL_do_01.sh -lpa ${subj}
    - ASL_do_01.sh -lpaZZ ${subj}
    - ASL_do_01.sh -noEdge ${subj}

- **CHECK: compare ${subj}/reg/asl.nii, to t1.nii**


```
STEP3:
- Creates a grey matter(GM)/white matter(WM)/CSF classification.you can use your lab's segmentation pipeline. you just have to make sure that the whole cortex & subcortical GM is included.
- You have to name your segmentatiion file to be y_class.nii in which CSF is labels 2, GM is labeled 3 and WM is labels 4 .
- Place your segmentation file (y_class.nii) under data/${subj}/reg directory
```

```
./ASL_do_04.sh [-ss_a] [-ss_b] SUBJ	 
```
-   This script calculates cbf, then registers both research mprage and cbf datasets to the MNI152 template
-   For some patients, the skull stripping above fails. Delete the ${subj}/reg/alignMNI folder as well as CBF.nii and asl-pos.nii in 
${subj}/reg directory. Solutions I used are below: 
    - A gyrus is cut off (usually top of head); run the following:
        - ASL_do_04.sh -ss_a ${subj}
        - This uses the following skull strip options and dilates the mask by 5: 
            - -blur_fwhm 2 -use_skull
    - After running the above, part of the brain is still being lost in skull stripping:
        - ASL_do_04.sh -ss_b ${subj}
    	- This uses the following skull strip options and dilates the mask by 8: 
            - -blur_fwhm 2 -use_skull


**CHECK: for skull strip, compare ${subj}/reg/alignMNI/cbf_ss_shft.nii, mprage_reg_shft.nii**
**CHECK: for the MNI reg compare ${subj}/reg/alignMNI/cbf_ss_mni.nii and scripts/__files/MNI152_2009_template_SSW.nii.gz**
**CHECK: make sure the CBF values are in the range of 40-80**

```
./ASL_do_05.sh SUBJ

```
-   At this step, you have to make sure to unzip the brainnetome_parcels.zip located under scripts/__files
-   Smooths and median normalizes the cbf data


## Statisitical Analysis

```
-   Begin this step after completing the above steps for all subjects 
-   Users have to make sure to download the Brainnetome_parcels.zip file before attemp to perform any statisitcal analysis.
This folder is located under __files directory

```

```
./ASL_do_region_analysis.sh SUBJ	  
```
-   For stats we resample the “regional” and “focal” parcels to the subjects’ CBF data and then calculate the mean CBF values in these parcels


