#!/usr/bin/env bash
# see ../03_fs_cmp_mkinputs.bash for fs/compare/sub* files
export MAXJOBS=30
cd "$(dirname $0)"
for f in /raidmeduser/OngoingResearch/7TDATA/deriv/fs/compare/sub-*/N[ND]x*.nii.gz; do
 [[ $f =~ border_enhance ]] && continue
 id=$(basename $(dirname "$f"))
 b=$(basename "$f" .nii.gz)
 echo  "# $id $b [$(date +%F-%H:%M)]"
 dryrun fast -b -B -o $PWD/${id}_${b}_ $f &
 waitforjobs -c auto
done

echo "$(date) finished disbatching. waiting for all to finish"
wait
