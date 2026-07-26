#!/usr/bin/env bash
# dcmdb.tsv input from 00_mkdb.bash
dcmtab_bids \
	\
       	`#'anat/UNIT1;dname=anat-UNIT1.*UNI-DEN_ND'` \
        `#'anat/MP2RAGE;dname=anat.*_INV1_ND;inv=1'` \
        `#'anat/MP2RAGE;dname=anat.*_INV2_ND;inv=2'` \
	`# 20260725 - Eval2 does not have ND versions` \
       	'anat/UNIT1;dname=anat-UNIT1.*UNI-DEN' \
        'anat/MP2RAGE;dname=anat.*_INV1;inv=1' \
        'anat/MP2RAGE;dname=anat.*_INV2;inv=2' \
	\
	\
	'epi;ndcm=2,pname=fmap-epi_acq-task_dir-AP;dir=AP;acq=task;fixrun=1'\
	'epi;ndcm=2,pname=fmap-epi_acq-task_dir-PA;dir=PA;acq=task;fixrun=1'\
	\
	'epi;ndcm=2,pname=fmap-epi_acq-task_run-2_dir-AP;dir=AP;acq=task;fixrun=2'\
	'epi;ndcm=2,pname=fmap-epi_acq-task_run-2_dir-PA;dir=PA;acq=task;fixrun=2'\
	\
	'magnitude1;ndcm=3,dname=fmap__bolero_b0_field_map_chm;acq=chm' \
	'phasediff;ndcm=1,dname=fmap__bolero_b0_field_map_chm;acq=chm' \
	'magnitude1;ndcm=3,dname=fmap__bolero_b0_field_map_jp;acq=jp' \
	'phasediff;ndcm=1,dname=fmap__bolero_b0_field_map_jp;acq=jp' \
	\
	\
       	'bold=rest;ndcm=500,pname=func-bold_task-rest;acq=fast' \
       	'sbref=rest;ndcm=1,pname=func-bold_task-rest;acq=fast' \
	'bold=rest;ndcm=300,pname=func-bold_task-rest_acq-HR_run-1;acq=highres'\
	'sbref=rest;ndcm=1,pname=func-bold_task-rest_acq-HR_run-1;acq=highres'\
	\
       	'bold=grasp;ndcm=300,pname=func-bold_task-grasp_run-1;acq=fast;fixrun=1' \
       	'sbref=grasp;ndcm=1,pname=func-bold_task-grasp_run-1;acq=fast;fixrun=1' \
	\
       	'bold=grasp;ndcm=300,pname=func-bold_task-grasp_run-2;acq=fast;fixrun=2' \
       	'sbref=grasp;ndcm=1,pname=func-bold_task-grasp_run-2;acq=fast;fixrun=2' \
	\
       	'bold=grasp;ndcm=300,pname=func-bold_task-grasp_run-3;acq=fast;fixrun=3' \
       	'sbref=grasp;ndcm=1,pname=func-bold_task-grasp_run-3;acq=fast;fixrun=3' \
	\
	\
	'bold=gresp;ndcm=300,pname=func-bold_task-grasp_acq-HR_run-1;acq=highres'\
       	< dcmdb.tsv |
  parallel --colsep '\t' \
   mknii bids/"{1}" "{2}"

# IntendedFor instead of B0FieldIdentifier and B0FieldSource only b/c we have script for the former
# there's a long break between run-2 and run-3 of grasp. so new fieldmap
add-intended-for -fmap '*_acq-task_dir-AP_run-1_epi.json' \
   -for '*task-grasp*run-1_bold.nii.gz' \
   -for '*task-grasp*run-2_bold.nii.gz' \
   -for '*rest*acq-fast*_bold.nii.gz' \
   bids/sub-*/ses-*/
add-intended-for -fmap '*_acq-task_dir-PA_run-1_epi.json' \
   -for '*task-grasp*run-1_bold.nii.gz' \
   -for '*task-grasp*run-2_bold.nii.gz' \
   -for '*rest*acq-fast*_bold.nii.gz' \
   bids/sub-*/ses-*/

add-intended-for -fmap '*_acq-task_dir-AP_run-2_epi.json' \
  -for '*task-grasp*run-3_bold.nii.gz' \
  bids/sub-*/ses-*/
add-intended-for -fmap '*_acq-task_dir-PA_run-2_epi.json' \
  -for '*task-grasp*run-3_bold.nii.gz' \
  bids/sub-*/ses-*/

# 20260724 - fix missing session
rg -l 'IntendedFor.*"func' bids/*/*/fmap/*json| while read f; do  [[ $f =~ ses-[^/_-]* ]] || continue; ses=$BASH_REMATCH; sed -i  "/IntendedFor/ s:\"func/:\"$ses/func/:g" $f; done
