#!/usr/bin/env bash
set -euo pipefail

# make event time
# use like:
# mkevent_time taskdata/029218_SoundTest_2026-07-06_12h49.45.182.log
mkevent_time(){
  perl -slane '
  $ref=$F[0] if m/Keypress: equal/ and not $ref;
  if(/(Grasp|Rest|done_text).*Draw = T/){
	  next if $prev eq $1;
	  $prev=$1;
	  push @events, [$F[0]-$ref, $1];
  } END{
  print "onset\tduration\ttrial_type";
  for my $i (0..$#events){
	  print(join("\t", map({sprintf("%.2f",$_)} ($events[$i]->[0], $events[$i+1]->[0] - $events[$i]->[0])), $events[$i]->[1])) if $events[$i]->[1] =~ m/Grasp|Rest/;
  }
}' "$@"
}
export -f mkevent_time


# copied logs with final line time stamp long enough to have been an actual grasp task run
# cp $(perl -slane 'print "$ARGV" if eof and $F[0]>300' /mnt/usb2/snd_2026/data/*log) /raidmeduser/OngoingResearch/7TDATA/deriv/taskdata/


# pairing presentation computer clock time to MARs dicom reconstruction time
#jq '[(input_filename|gsub(".*ses-|_task.*";"")) +" "+ .AcquisitionTime, input_filename ]|@tsv' -r bids/sub-*/ses-*/func/*task-grasp*_bold.json|sort
#ls taskdata/|sed -E 's/.*SoundTest_|.log//g'|sort


cat <<HERE |
2026-07-06_17h18.05.275  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-1_bold.json
2026-07-06_17h26.14.662  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-2_bold.json
2026-07-06_18h30.02.811  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-3_bold.json
2026-07-07_15h03.26.612  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_bold.json
2026-07-07_15h12.15.802  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-2_bold.json
2026-07-07_16h11.05.697  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-3_bold.json
HERE
while read etime bids_name; do
  skip-exist -o ${bids_name/_bold.json/}_events.tsv \
     mkevent_time taskdata/*$etime*.log 
done
