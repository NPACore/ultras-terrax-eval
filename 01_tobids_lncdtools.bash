# dcmdirtab -d 'raw/*/DICOM/*/' > dcmdb.tsv

dcmtab_bids \
	'bold=grasp;ndcm=300,pname=func-bold_task-rest_acq-HR_run-1;acq=highres'\
	'bold=rest;ndcm=300,pname=func-bold_task-rest_acq-HR_run-1;acq=highres'\
       	'bold=rest;ndcm=500,pname=func-bold_task-rest;acq=fast' \
       	'anat/UNIT1;dname=anat-UNIT1.*UNI-DEN_ND' \
        'anat/MP2RAGE;dname=anat*_INV1_304;inv=1' \
        'anat/MP2RAGE;dname=anat*_INV2_304;inv=2' \
       	< dcmdb.tsv

