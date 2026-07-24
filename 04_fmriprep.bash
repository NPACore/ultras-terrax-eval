#!/usr/bin/env bash
BIDS=$(readlink -f bids/)
FP_VER=25.2.5
FP_DIR=$(readlink -f deriv)/fp/$FP_VER
SUBJECTS_DIR=$(readlink -f deriv)/fs/8.2.0
FS_LICENSE=$(cd $(dirname $0);pwd)/fs.lic
BIDSDB=$(readlink -f bids)/db

# ./04_fmriprep.bash --participant-label sub-Phant1
# ./04_fmriprep.bash --derivatives /raidmeduser/OngoingResearch/7TDATA/deriv/fp/25.2.5 --participant-label sub-Eval1 --task grasp -v --debug fieldmaps

# TODO: --fs-no-resume and make FS ro?

mkdir -p "$FP_DIR"
dryrun docker run \
       	-v $BIDS:$BIDS:ro \
	-v "$BIDSDB:$BIDSDB" \
	-v "$FS_LICENSE:$FS_LICENSE:ro" \
	-v "$SUBJECTS_DIR:$SUBJECTS_DIR" \
	-v "$FP_DIR:$FP_DIR" \
	--rm \
	\
	nipreps/fmriprep:25.2.5 \
	--notrack \
	--fs-license-file $FS_LICENSE \
	--fs-subjects-dir "$SUBJECTS_DIR" \
	--bids-database-dir "$BIDSDB" \
	"$@" \
	--skip-bids-validation \
	"$BIDS" "$FP_DIR" participant
