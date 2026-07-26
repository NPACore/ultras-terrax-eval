#!/usr/bin/env bash
# use /opt/ni_tools/mp2rage-den-unicort/mp2rage_unicort to make T1w files out of the UNI DEN MP2RAGE
# NB. bids/.bidsignore includes '*DEN-10*' to avoid the intermediate but still useful 
#     like 'bids/sub-Phant2/ses-20260706/anat/{,c[1-5],m}sub-Phant2_ses-20260706_DEN-10.nii'
export PATH=$PATH:/opt/ni_tools/mp2rage-den-unicort/

export BIDS=$(readlink -f bids/)
mp2rage_unicort
