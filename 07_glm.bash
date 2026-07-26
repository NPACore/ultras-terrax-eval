#!/usr/bin/env bash
set -euo pipefail
export AFNI_USE_ERROR_FILE=NO # don't save 3dDeconvolve.err (would be overwritten b/c we don't change dir out of script)

GLMDIR=deriv/glm/3ddeconvolve
for f in deriv/fp/25.2.5/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz; do
  ! [[ $f =~ sub-[^/_-]+/ses-[^/_-]+ ]] && echo "no sub*/ses* in $f" && continue
  subses=$BASH_REMATCH
  confound=${f/_space-MNI*/}_desc-confounds_timeseries.tsv
  events=bids/$subses/func/$(basename ${f/_space-MNI*/}_events.tsv)
  ! test -r $confound  && echo "ERROR: confounds MIA '$confound'" && continue
  ! test -r $events  && echo "ERROR: events MIA '$events'" && continue
  run_out=$GLMDIR/$(basename $f .nii.gz)
  dryrun mkdir -p $run_out
  skip-exist -o $run_out/grasp.1D perl -sane 'print "$F[0]:$F[1] " if /Grasp/' $events
  skip-exist -o $run_out/nuissance.mat bash -c "mlr --itsv --ho --otsv cut -r -f '(rot|trans)_[xyz](|_derivative1),glboal_signal' $confound| sed s:n/a:0:g"
  
  skip-exist $run_out/grasp_bucket.nii.gz  \
     3dDeconvolve \
	  -ortvec $run_out/nuissance.mat nuis \
	  -num_stimts 1 \
	  -polort 3 \
	  -stim_times_AM1 1 $run_out/grasp.1D 'dmBLOCK' -stim_label 1 grasp \
	  -input $f \
	  -jobs 20 \
	  -prefix __SKIPFILE \
	  -x1D $run_out/grasp.mat \
	  -tout -rout

done
