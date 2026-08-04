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
# WF Human Phantom 1
2026-07-06_17h18.05.275  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-1_bold.json
2026-07-06_17h26.14.662  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-2_bold.json
2026-07-06_17h35.46.813  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-highres_run-1_bold.json
2026-07-06_18h30.02.811  bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-3_bold.json

# Eval 1
2026-07-07_15h03.26.612  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_bold.json
2026-07-07_15h12.15.802  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-2_bold.json
2026-07-07_15h20.33.533  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-highres_run-1_bold.json
2026-07-07_16h11.05.697  bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-3_bold.json

# Eval 2
2026-07-21_14h45.54      bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-fast_run-1_bold.json
2026-07-21_14h53.39      bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-fast_run-2_bold.json
2026-07-21_15h01.16      bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-highres_run-1_bold.json
2026-07-21_15h49.40      bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-fast_run-3_bold.json

# Session 3 - with highres grasp (NB highres=run-1 in MR but run-3 in task name)
Grasp_sub-Eval3_run-1_acq-lowres_tr-1.3*2026-08-01_12h46 bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-fast_run-1_bold.json
Grasp_sub-Eval3_run-2_acq-lowres_tr-1.3*2026-08-01_12h54 bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-fast_run-2_bold.json
Grasp_sub-Eval3_run-4_acq-lowres_tr-1.3*2026-08-01_13h52  bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-fast_run-3_bold.json
Grasp_sub-Eval3_run-3_acq-highres_tr-2*2026-08-01_13h03 bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-highres_run-1_bold.json
HERE
while read etime bids_name; do
  [[ -z "$etime" || $etime =~ ^# ]] && continue
  skip-exist -o ${bids_name/_bold.json/}_events.tsv \
     mkevent_time taskdata/*$etime*.log 
done


exit 1
# perl -slane 'print "$& $ARGV" if eof and $F[0]>300 and $ARGV =~ /2026-0[0-9-]+_\d+h[0-9.]+/' taskdata/*log|sort -n
# 2026-07-06_17h18.05.275. taskdata/552323_SoundTest_2026-07-06_17h18.05.275.log
# 2026-07-06_17h26.14.662. taskdata/703097_SoundTest_2026-07-06_17h26.14.662.log
# 2026-07-06_17h35.46.813. taskdata/543403_SoundTest_2026-07-06_17h35.46.813.log
# 2026-07-06_18h30.02.811. taskdata/494738_SoundTest_2026-07-06_18h30.02.811.log
#
# 2026-07-07_13h49.43.204. taskdata/218913_SoundTest_2026-07-07_13h49.43.204.log
# 2026-07-07_15h03.26.612. taskdata/sub-01_SoundTest_2026-07-07_15h03.26.612.log
# 2026-07-07_15h12.15.802. taskdata/sub-01_SoundTest_2026-07-07_15h12.15.802.log
# 2026-07-07_15h20.33.533. taskdata/sub-01_SoundTest_2026-07-07_15h20.33.533.log
# 2026-07-07_16h11.05.697. taskdata/sub-01_SoundTest_2026-07-07_16h11.05.697.log
#
# 2026-07-21_14h45.54.759. taskdata/532915_SoundTest_2026-07-21_14h45.54.759.log
# 2026-07-21_14h53.39.149. taskdata/449916_SoundTest_2026-07-21_14h53.39.149.log
# 2026-07-21_15h01.16.170. taskdata/171706_SoundTest_2026-07-21_15h01.16.170.log
# 2026-07-21_15h49.40.251. taskdata/181622_SoundTest_2026-07-21_15h49.40.251.log
#
# 2026-08-01_12h46.14.756. taskdata/Grasp_sub-Eval3_run-1_acq-lowres_tr-1.3_nblock-10_reps-15_date-2026-08-01_12h46.14.756.log
# 2026-08-01_12h54.54.501. taskdata/Grasp_sub-Eval3_run-2_acq-lowres_tr-1.3_nblock-10_reps-15_date-2026-08-01_12h54.54.501.log
# 2026-08-01_13h03.15.812. taskdata/Grasp_sub-Eval3_run-3_acq-highres_tr-2_nblock-10_reps-10_date-2026-08-01_13h03.15.812.log
# 2026-08-01_13h52.56.733. taskdata/Grasp_sub-Eval3_run-4_acq-lowres_tr-1.3_nblock-10_reps-15_date-2026-08-01_13h52.56.733.log

#
#  jq '[(input_filename|gsub(".*ses-|_task.*";"")) +" "+ .AcquisitionTime, input_filename ]|@tsv' -r bids/sub-*/ses-*/func/*task-grasp*_bold.json|sort
# 20260706 17:16:48.767500        bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-1_bold.json
# 20260706 17:24:45.215000        bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-2_bold.json
# 20260706 17:34:44.662500        bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-highres_run-1_bold.json
# 20260706 18:29:31.782500        bids/sub-Phant1/ses-20260706/func/sub-Phant1_ses-20260706_task-grasp_acq-fast_run-3_bold.json
#
# 20260707 15:02:50.335000        bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_bold.json
# 20260707 15:11:5.772500 bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-2_bold.json
# 20260707 15:19:53.330000        bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-highres_run-1_bold.json
# 20260707 16:10:8.267500 bids/sub-Eval1/ses-20260707/func/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-3_bold.json
#
# 20260721 14:44:1.437500 bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-fast_run-1_bold.json
# 20260721 14:51:47.540000        bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-fast_run-2_bold.json
# 20260721 15:00:6.402500 bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-highres_run-1_bold.json
# 20260721 15:47:57.650000        bids/sub-Eval2/ses-20260721/func/sub-Eval2_ses-20260721_task-grasp_acq-fast_run-3_bold.json
#
# 20260801 12:44:30.367500        bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-fast_run-1_bold.json
# 20260801 12:52:53.492500        bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-fast_run-2_bold.json
# 20260801 13:01:44.047500        bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-highres_run-1_bold.json
# 20260801 13:51:9.595000 bids/sub-Eval3/ses-20260801/func/sub-Eval3_ses-20260801_task-grasp_acq-fast_run-3_bold.json

