#!/usr/bin/env bash
dcmdirtab \
	-s '(?<=Human)[^/]*' \
	-b '202[0-9]{5}' \
       	-d 'raw/*/DICOM/*/' \
       	-d 'raw/20260721HumanEval2/DICOM/20260707HumanEval1_20260707HumanEval1_19930707/*' \
	| grep -v ^NONE \
	> dcmdb.tsv
