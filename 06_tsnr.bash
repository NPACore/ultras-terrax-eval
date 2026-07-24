#!/usr/bin/env bash
set -euo pipefail
for f in deriv/fp/25.2.5/sub-*/ses-*/func/sub-*_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz \
         deriv/xcpd/26.1.1/sub-*/ses-*/func/sub-*_desc-denoisedSmoothed_bold.nii.gz; do
   ! [[ $f =~ sub-[^_/-]*/ses-[^_/-]* ]] && echo "missing sub-*/ses-* in $f" && continue
   subsesdir=${BASH_REMATCH}
   tsnr=deriv/tsnr/$subsesdir/$(basename $f)
   dryrun mkdir -p $subsesdir

   # xcpd is bandpassed. pull in mean from fmriprep. this is probably less than ideal.
   # we would want to include the smoothed mean instead
   MEAN_FROM=
   if [[ $f =~ denoised ]]; then
     MEAN_FROM=deriv/fp/25.2.5/$subsesdir/func/$(basename ${f/_desc*/_desc-preproc_bold.nii.gz})
   fi
   export MEAN_FROM

   skip-exist $tsnr tsnr $f  __SKIPFILE
done

# fix up labeling for afni viewing
for f in deriv/tsnr/sub-*/ses*/*denoisedSmoothed*; do
	dryrun 3drefit -space MNI -view tlrc $f
done
