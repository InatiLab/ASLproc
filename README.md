# ASLproc
Pre-Processing for Volumetric Analysis of Arterial Spin Labeling(ASL) Data

## processing steps:
```
./ASL_do_01.sh [-lpa] [-lpaZZ] [-noEdge] SUBJ
```
-   This script registers research mprage to clinical t1 and registers ASL data to mprage
-   For some patients, the asl-to-mprage registration fails. In this case, there are several options you can try. The default script uses nmi cost function with the edge option and rigid body option. If this fails, delete the reg folder and retry 1 and 2, using the following options for this step:
    - ASL_do_01.sh -lpa ${subj}
    - ASL_do_01.sh -lpaZZ ${subj}
    - ASL_do_01.sh -noEdge ${subj}

```
./ASL_do_02.sh SUBJ
```
-   This script uses the linear transformation from step 1 to register ASL to the clinical t1

```
./ASL_do_02.sh SUBJ
```
-   Creates a grey matter/white matter/csf/other classification 

```
./ASL_do_04.sh [-ss_a] [-ss_b] SUBJ	 
```
-   This script calculates cbf, then registers both research mprage and cbf datasets to the MNI152 template
-   For some patients, the skull stripping above fails. Delete the ${subj}/reg/alignMNI folder as well as CBF.nii and asl-pos.nii in ${subj}/reg. Solutions I used are below: 
•	A gyrus is cut off (usually top of head); run the following:
o	ASL_do_04.sh -ss_a ${subj}
o	This uses the following skull strip options and dilates the mask by 5: 
•	-blur_fwhm 2 -use_skull
•	After running the above, part of the brain is still being lost in skull stripping:
o	ASL_do_04.sh -ss_b ${subj}
o	This uses the following skull strip options and dilates the mask by 8: 
•	-blur_fwhm 2 -use_skull

```
./ASL_do_05.sh SUBJ 
```
-   Smooths and median normalizes the cbf data


```
./ASL_do_surf_analysis.sh [-h|--help] [-l|--list SUBJ_LIST] [SUBJ [SUBJ ...]]
```
-   Carries out the surface analysis
-   To be specific, it samples the newly calculated CBF data to the surface, takes the average CBF value between the nodes of the smooth wm and dial surfaces, and applies brainnetome atlas

## Statisitical Analysis

```
./BN_do_define_regions.sh
```
-   Run this once before the pipeline, it is not subject-specific
-   it creates the regional and focal brainnetome atlases

```
./ASL_do_region_analysis.sh SUBJ	  
```
-   For stats we resample the “regional” and “focal” parcels to the subjects’ CBF data and then calculate the mean CBF values in these parcels

