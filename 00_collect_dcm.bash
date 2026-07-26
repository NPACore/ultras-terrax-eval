# where raw dicom data lives
test -r raw || ln -s /raidmeduser/OngoingResearch/7TDATA/TerraX raw

echo "original files moved. no need for this script"
exit 1

for dcmdir in /raidmeduser/OngoingResearch/7TDATA/TerraX/*/DICOM/_*[0-9]/*/; do
  # /raidmeduser/OngoingResearch/7TDATA/TerraX/20260707HumanEval1/DICOM/_20260707_141922.000000_9/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV1_ND_3_MR/
  #! [[ $dmcdir =~ TerraX/([^/]*)/DICOM/_(20[0-9]+)_([0-9.]+)_([0-9]+)/([^/]*)(__.*)? ]] &&
  ! [[ $dcmdir =~ ([^/]*)/DICOM/_(20[0-9]+)_([0-9.]+)_([0-9]+)/([^/]*)(__.*)? ]] &&
	  echo "ERROR: no id/DICOM/date_time_number/seqname in $dcmdir" && continue
  id=${BASH_REMATCH[1]}
  ymd=${BASH_REMATCH[2]}
  hmss=${BASH_REMATCH[3]}
  seqno=${BASH_REMATCH[4]}
  reproin=${BASH_REMATCH[5]}
  custom=${BASH_REMATCH[6]}
  echo "id=$id '$reproin' n=$seqno ($custom) @ $ymd $hmss"
  newdir=dcm_ln/$id/${reproin}${custom/\//}__${ymd}-${hmss}~$(printf "%03d" $seqno)
  test -d $newdir && continue
  mkdir -p "$(dirname "$newdir")"
  ln -s $dcmdir $newdir 
done
