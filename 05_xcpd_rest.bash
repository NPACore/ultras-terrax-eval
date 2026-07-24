#!/usr/bin/env bash
#./05_xcpd_rest.bash  -t rest --input-type fmriprep --file-format nifti --participant-label Phant1
set -euo pipefail

XCPD_VER=26.1.1
FP_DIR=$(readlink -f deriv)/fp/25.2.5
XCPD_DIR=$(readlink -f deriv)/xcpd/$XCPD_VER # deriv/xcpd/26.1.1 as of 2026-07-14
SUBJECTS_DIR=$(readlink -f deriv)/fs/8.2.0
FS_LICENSE=$(cd $(dirname $0);pwd)/fs.lic

mkdir -p "$XCPD_DIR"
dryrun docker run \
	-v "$FP_DIR:$FP_DIR" \
	-v "$XCPD_DIR:$XCPD_DIR" \
	-v "$FS_LICENSE:$FS_LICENSE:ro" \
	--rm \
	\
	pennlinc/xcp_d:$XCPD_VER \
	--fs-license-file $FS_LICENSE \
	"$@" \
	--mode linc \
	"$FP_DIR" "$XCPD_DIR" participant
