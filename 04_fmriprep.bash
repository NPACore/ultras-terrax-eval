#!/usr/bin/env bash
BIDS=$(readlink -f bids/)
FPOUT=$(readlink -f deriv)/fp/25.2.5
SUBJECTS_DIR=$(readlink -f deriv)/fs/8.2.0
FS_LICENSE=$(cd $(dirname $0);pwd)/fs.lic

mkdir -p "$FPOUT"
dryrun docker run \
       	-v $BIDS:$BIDS:ro \
	-v "$FS_LICENSE:$FS_LICENSE:ro" \
	-v "$SUBJECTS_DIR:$SUBJECTS_DIR:ro" \
	-v "$FPOUT:$FPOUT" \
	\
	nipreps/fmriprep:25.2.5 \
	--fs-license-file $FS_LICENSE \
	--fs-subjects-dir "$SUBJECTS_DIR" \
	"$@" \
	--skip-bids-validation \
	"$BIDS" "$FPOUT" participant
