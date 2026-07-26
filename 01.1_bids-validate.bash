docker run -v $(readlink -f bids):$(readlink -f bids):ro --entrypoint=bids-validator nipreps/fmriprep:25.2.5  $(readlink -f bids) --verbose --ignoreSubjectConsistency "$@"
