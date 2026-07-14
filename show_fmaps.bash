jq -r '[.AcquisitionTime, (.ShimSetting|@csv), input_filename]|@tsv' bids/sub-*/ses-*/fmap/sub-*{_dir-AP*epi,_echo-1*mag}*json bids/sub-*/ses-*/func/*_bold.json|sort | while read acqtime shim file; do
  vox=$( AFNI_NIFTI_TYPE_WARN=NO 3dinfo -ad3 ${file/.json/.nii.gz}|sed -E 's/\s/,/g')
  tr=$(AFNI_NIFTI_TYPE_WARN=NO 3dinfo -tr ${file/.json/.nii.gz})
  printf "%s\t%s\t%s\t%s\t%s\n" $acqtime $shim $tr $vox ${file/*\//}
done | column -t

