#!/usr/bin/env bash
set -euo pipefail
SUBJECTS_DIR=$(readlink -f deriv)/fs/8.2.0
FS_LICENSE=$(cd $(dirname $0);pwd)/fs.lic
container=freesurfer/freesurfer:8.2.0

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
       --rm "$container" \
       "$@"

}


for f in bids/sub-*/ses-*/anat/*_T1w.nii.gz; do
  ! test -r $f && echo "ERROR: no file like '$f'" && continue
  ! [[ $f =~ sub-([^_/]*).ses-([^_/]*) ]] && echo "no id in $f" && continue

   sub=${BASH_REMATCH[1]} 
   ses=${BASH_REMATCH[2]}
   sub_ses=sub-${sub}_ses-$ses

   # shim failed. bad file
   [[ $sub_ses == sub-Phant2_ses-20260706 ]] && echo "# Skipping $sub_ses" && continue

   expect_out="$SUBJECTS_DIR/${sub_ses}/mri/aseg.mgz"
   test -r "$expect_out" && echo "SKIP: have $_ for $f" && continue
   pgrep -af "docker.*recon-all.*${sub_ses}" && echo "SKIP: $sub_ses ($f) already running" && continue

  #NB. ignoring session!
  f="$(readlink -f $f)"
  fs_docker "$f" recon-all -hires -all -i "$f" -s "$sub_ses" &
  waitforjobs
done
wait
