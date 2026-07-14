#!/usr/bin/env bash
dcmdirtab \
	-s '(?<=Human)[^/]*' \
	-b '202[0-9]{5}' \
       	-d 'raw/*/DICOM/*/' \
	> dcmdb.tsv
