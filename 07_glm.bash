#!/usr/bin/env bash
set -euo pipefail
export AFNI_USE_ERROR_FILE=NO # don't save 3dDeconvolve.err (would be overwritten b/c we don't change dir out of script)


# extract motion and signal regessors from fmriprep output. 
mkreg_fmriprep(){
  mlr --itsv --ho --otsv cut -r -f '(rot|trans)_[xyz](|_derivative1),glboal_signal' ${1:?fmriprep confound file required}| sed s:n/a:0:g
}
# MH pipeline already has this
mkreg_mhproc(){ cat "${1:?mh nuissance high/bandpassed file}"; }
# export so skip-exist can see functions
export -f mkreg_fmriprep mkreg_mhproc

run_decon(){
  f=${1:?input preprocessed file}
  ! test -r "$f" && echo "ERROR: can't read task bold file '$f'" && continue
  ! [[ $f =~ sub-[^/_-]+/ses-[^/_-]+ ]] && echo "no sub*/ses* in $f" && continue
  subses=$BASH_REMATCH

  # what kind of processing pipeline?
  case $f in 
   *fp/25.2.5*)
      GLMDIR=deriv/glm/3ddeconvolve-fp-25.2.5/
      task=$(basename $f .nii.gz) # includes sub-ses, task, run, acq
      confound=${f/_space-MNI*/}_desc-confounds_timeseries.tsv
      events=bids/$subses/func/$(basename ${f/_space-MNI*/}_events.tsv)
      reg_extract_cmd=mkreg_fmriprep
      goforit="-GOFORIT 0"
      ;;
    *proc/1.0*)
      GLMDIR=deriv/glm/3ddeconvolve-mh-1.0/
      task=$(basename "$(dirname "$f")" _bold) # includes sub-ses, task, run, acq
      confound=$(dirname "$f")/.nuisance_regressors
      events=bids/$subses/func/${task}_events.tsv
      reg_extract_cmd=mkreg_mhproc
      goforit="-GOFORIT 6" # colinear or empty regressors. bad inversion
      ;;
   *xcpd*)
      echo "ERROR: xcpd not implmented yet"; continue;;
   *)
     echo "ERROR: unknown pipeline not mh 1.0 or fmriprep 25.2.5"; continue;;
  esac

  ! test -r $confound  && echo "ERROR: confounds MIA '$confound'" && continue
  ! test -r $events  && echo "ERROR: events MIA '$events'" && continue

  run_out=$GLMDIR/ #$task
  dryrun mkdir -p $run_out
  skip-exist -o $run_out/${task}_grasp.1D perl -sane 'print "$F[0]:$F[1] " if /Grasp/' $events
  skip-exist -o $run_out/${task}_nuissance.mat $reg_extract_cmd $confound
  
  skip-exist $run_out/${task}_amblock.nii.gz  \
     3dDeconvolve \
	  -input $f \
          -ortvec $run_out/${task}_nuissance.mat nuis \
	  -num_stimts 1 \
	  -polort 3 \
	  -stim_times_AM1 1 $run_out/${task}_grasp.1D 'dmBLOCK' -stim_label 1 grasp \
	  -jobs 20 \
	  -prefix __SKIPFILE \
	  -x1D $run_out/${task}_amblock.mat \
	  -tout -rout\
	  $goforit
}


[[ $# -eq 0 || $* =~ ^-+h ]] &&
	echo "USAGE: $0 [all|deriv/fp/25.2.5/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz]" &&
	exit 

[ $1 == "all" ] && FILES=(deriv/fp/25.2.5/sub-*/ses-*/func/sub-*_task-grasp*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz) || FILES=("$@")
for f in ${FILES[@]}; do
	run_decon $f
done
