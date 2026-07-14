#uv tool run heudiconv -c none -f reproin -o bids  -d 'dcm_ln/{subject}/*/*'   -s 20260706HumanPhant1
ls -d raw/20260706HumanPhant1/DICOM/*/ | grep -Pv 'scout|Phoenix|PosDisp'| xargs uv tool run heudiconv -c none -f reproin -o bids  --files
