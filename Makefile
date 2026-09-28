.PHONY: all
.SUFFIXES:
.SECONDARY:

dcmdb.tsv: $(wildcard raw/*/DICOM/*/)
	./00_mkdb.bash

.make/bids.ls: dcmdb.tsv | .make/
	./01.0_tobids_lncdtools.bash
	mkstat $@ 'bids/sub-*/ses-*/*/*.nii.gz'

.make/t1w.ls: .make/bids.ls
	./02_unit1_to_t1w.bash
	mkstat $@ 'bids/sub-*/ses-*/anat/*T1w.nii.gz'

.make/fs.ls: .make/tw1.ls
	./03_fs.bash all
	mkstat $@ 'deriv/fs/8.2.0/*/scripts/recon-all.done'

# TODO: fmriprep wrapper needs an 'all' option
.make/fp.ls: .make/fs.ls
	./04_fmriprep.bash
	mkstat $@ 'deriv/fp/25.2.5/*.html'

# template rule for all folders. but really just for .make/
%/:
	mkdir -p $@

HumanEvalTerraX.ipynb: /raidmeduser/OngoingResearch/7TDATA/TerraX/HumanEvalTerraX.ipynb
	cp $< $@
HumanEvalTerraX.py: HumanEvalTerraX.ipynb
	bash -c 'source /opt/ni_tools/venv/bin/activate && jupytext -o $@ --to py $< '
