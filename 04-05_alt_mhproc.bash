#!/usr/bin/env bash
set -euo pipefail

# make sure we have ica-aroma, nibabel, etc
source /opt/ni_tools/python-venv/bin/activate

ppT1(){
   in=$(readlink -f ${1:?input T1w.nii.gz});
   out=${2:?output folder};
   [ ! -s "$in" -o -z "$in" ] && "ERROR: specfied anatomical file '$1' does not exist (as '$in')" && return 1
   dryrun mkdir -p $out/
   skip-exist $out/T1w.nii.gz\
	   3dcopy $in __SKIPFILE

   # side-car not needed and may not exist (mp2rage uni converted to t1w in matlab without json)
   #skip-exist $out/T1w.json \
   # ln -sf ${in/.nii.gz}.json __SKIPFILE

   # trap cd in subshell
   (
    [ -z "${DRYRUN:-}" ] && cd "$out" || echo "# to run in '$out'";
    echo -n "$outdir vs "; pwd
    skip-exist T1w_warpcoef.nii.gz \
	   preprocessMprage -r MNI_1mm -n T1w.nii.gz
   )
}

[ $# -eq 0 ] && echo "USAGE: $0 [all|bids/sub-*/ses-*/func/sub-*_bold.nii.gz]" && exit
[ $1 == "all" ] && bolds=(bids/sub-*/ses-*/func/sub-*_bold.nii.gz) || bolds=("$@")

for f in "${bolds[@]}" ; do
	echo "# $f"
  ! [[ $f =~ sub-([^_/]*)/ses-([^_/]*) ]] && echo "ERROR: no sub*/ses* id in $f" && continue
  subses=$BASH_REMATCH
  ! [[ $f =~ task-([^_/]*).*_run-([^_/]*) ]] && echo "ERROR: no task_run in $f" && continue
  task_run=${BASH_REMATCH[1]}_${BASH_REMATCH[2]}

  # undo link
  f_real=$(readlink -f "$f")
  [ -z "$f_real" -o ! -s "$f_real" ] && echo "ERROR: cannot find '$f' as '$f_real'" && continue
  f=$f_real

  anat=$(find $(dirname "$f")/../anat/ -iname '*T1w.nii.gz' -print -quit)
  [ ! -s $anat ] && echo "ERROR: no anat like '$anat')" && continue

  case $task_run in
     *rest*) args=(-nuisance_regression gs,dgs,csf,dcsf,6motion,d6motion -bandpass_filter 0.009 .08);;
     *grasp*) args=(-nuisance_compute gs,dgs,csf,dcsf,6motion,d6motion -hp_filter 40);;
     *) echo "ERROR: unkonwn task type '$task_run' in '$f'"; continue ;;
  esac
  case $task_run in
	  *hires*) args=("${args[@]}" -template_brain MNI_2mm);;
	  *) args=("${args[@]}" -template_brain MNI_2mm);;
  esac

  # find the intended for
  fmap_json=$(grep "$(basename $f .nii.gz)" -l $(dirname $f)/../fmap/*json|sed 1q)
  fmap="$(readlink -f "${fmap_json/.json}.nii.gz")"
  if [ -z "$fmap"  ]; then
	  echo "WARNING: no fmap for $(basename $f) in $(diranme $f)/../fmap/ ('$fmap_json')"
  else
	  fmap_AP=${fmap/dir-PA/dir-AP}
	  fmap_PA=${fmap/dir-AP/dir-PA}
	  args=("${args[@]}" -se_phasepos "$fmap_PA" -se_phaseneg "$fmap_AP")
  fi

  outdir=$(readlink -f deriv)/hmproc/1.0/$subses/$(basename $f .nii.gz)
  test -d $outdir || dryrun mkdir -p $outdir
  skip-exist $outdir/$task_run.nii.gz  ln -s "$f" __SKIPFILE 
  skip-exist $outdir/$task_run.json cp "${f/.nii.gz/}.json"  __SKIPFILE

  # skip-exist $outdir/../anat/T1w_warpcoef.nii.gz
  ppT1  $anat $outdir/../anat

  ( [ -z "${DRYRUN:-}" ] && cd $outdir || echo "# to run in '$outdir'"
  dryrun preprocessFunctional \
	  -4d $task_run.nii.gz \
	  -wavelet_despike \
	  -ref_vol ${f/_bold.nii.gz}_sbref.nii.gz \
	  -mprage_bet ../anat/T1w_bet.nii.gz -warpcoef ../anat/T1w_warpcoef.nii.gz \
	  "${args[@]}" 
  )
  break
done
