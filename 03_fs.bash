#!/usr/bin/env bash
set -euo pipefail
FS_VER=${FS_VER:-8.2.0}
SUBJECTS_DIR_BASE=${SUBJECTS_DIR_BASE:-$(readlink -f deriv)/fs/$FS_VER}
FS_LICENSE=$(cd $(dirname $0);pwd)/fs.lic
container=freesurfer/freesurfer:$FS_VER
# should we use mp2rage instead of unicort?
# only meaningful when using 'all'
BIDS_T1_SUFFIX=${BIDS_T1_SUFFIX:-_UNIT1} # 20260824 swtich to unit1 for not bias corrected

fs_docker(){
  local f=${1?-input anatomicla image}; shift
  dryrun mkdir -p "$SUBJECTS_DIR"
  dryrun docker run \
       -v $FS_LICENSE:$FS_LICENSE:ro \
       -v "$SUBJECTS_DIR:$SUBJECTS_DIR:rw" \
       `# matlab compiled runtime. only valid fod FS_VER=7.4.1 (?) needed for 02.2_fs-hcseg.bash`\
       `#-v "/opt/ni_tools/freesurfer$FS_VER/MCRv97/:/usr/local/freesurfer/MCRv97:ro"` \
       -v "$f:$f:ro" \
       --env FS_ALLOW_DEEP=1 \
       --env SUBJECTS_DIR="$SUBJECTS_DIR" \
       --env FS_LICENSE="$FS_LICENSE" \
       --rm \
       "$container" \
       "$@"

}

# run specific set of T1ws through FS or run on 'all'
[[ $# -eq 0 || $* =~ ^-h ]] && echo "USAGE: $0 [all|bids/sub-*/ses-*/anat/*_T1w.nii.gz]" && exit
[[ $1 == "all" ]] && t1_to_run=(bids/sub-*/ses-*/anat/*$BIDS_T1_SUFFIX.nii.gz) || t1_to_run=("$@")

for f in ${t1_to_run[@]}; do
  ! test -r $f && echo "ERROR: no file like '$f'" && continue
  ! [[ $f =~ sub-([^_/]*).ses-([^_/]*) ]] && echo "no id in $f" && continue


   sub=${BASH_REMATCH[1]} 
   ses=${BASH_REMATCH[2]}
   sub_ses=sub-${sub}_ses-$ses

   # shim failed. bad file
   [[ $sub_ses == sub-Phant2_ses-20260706 ]] && echo "# Skipping $sub_ses" && continue


   # 20260824
   export SUBJECTS_DIR=$SUBJECTS_DIR_BASE
   # using UNTI1? change subjdir. also show 3dNotes.
   # only want to do this on files that are distrtion corrected on the scanner
   # 20260912 DISABLED
   if false && [[ $f =~ UNIT1 ]]; then
     export SUBJECTS_DIR=$SUBJECTS_DIR_BASE-unit1 &&
     3dNotes $f
   fi

   expect_out="$SUBJECTS_DIR/${sub_ses}/mri/aseg.mgz"
   test -r "$expect_out" && echo "SKIP: have $_ for $f" && continue
   pgrep_search="${PGREPSEARCH:-docker.*recon-all.*${sub_ses}}"
   if pgrep -af "$pgrep_search"; then
	   echo "SKIP: $sub_ses ($f) already running ($pgrep_search)" 
	   continue
   else
	   echo "# $(tput setaf 2)RUN$(tput sgr0) $sub_ses. no existing process like '$_'"
   fi

  #NB. ignoring session!
  f="$(readlink -f $f)"
  fs_docker "$f" recon-all -hires -all -i "$f" -s "$sub_ses" &
  waitforjobs
done
wait
