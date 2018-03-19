#!/bin/bash
# MAKE SURE TO RUN SOURCE /data/stali/setup.sh AND ARE IN BASH SHELL
# compiles ALOS raw data and submits gmtsar preprocess command to get SLC and PRM files.  Outputs in calendar date naming scheme.
# Only for pair list purposes (not for HTCondor workflow)
# 20170606 Elena C Reinisch

if [[ $# -eq 0 ]]
then
  echo "compiles ALOS raw data and submits gmtsar preprocess command to get SLC and PRM files.  Outputs in calendar date naming scheme in ../preproc"
  echo "run in raw directory. Only for pair list purposes (not for HTCondor workflow)"
  echo "raw2prmslc_ALOS.sh preproc_porotomo.lst"
  exit 1
fi

mkdir -p ../preproc
track=`pwd | awk -FALOS\/ '{print $2}' | awk -F\/raw '{print $1}'`

# form processed files for ALOS1
while read -r img led; do
 scp $maule:/s21/insar/ALOS/$track/preproc/$img .
 scp $maule:/s21/insar/ALOS/$track/preproc/$led .
 scene_date=`echo $img | awk -F- '{print $3}'`
 ALOS_pre_process_SLC $img $led
 mv *.PRM ../preproc/${scene_date}.PRM
 mv *.SLC ../preproc/${scene_date}.SLC 
done < $1

