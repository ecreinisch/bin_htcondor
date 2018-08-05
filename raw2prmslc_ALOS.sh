#!/bin/bash
# MAKE SURE TO RUN SOURCE /data/stali/setup.sh AND ARE IN BASH SHELL
# compiles ALOS raw data and submits gmtsar preprocess command to get SLC and PRM files.  Outputs in calendar date naming scheme.
# Only for pair list purposes (not for HTCondor workflow)
# 20170606 Elena C Reinisch
# update ECR 20180803 update to run on maule server

if [[ $# -eq 0 ]]
then
  echo "compiles ALOS raw data and submits gmtsar preprocess command to get SLC and PRM files.  Outputs in calendar date naming scheme in ../preproc"
  echo "run in raw directory. Only for pair list purposes (not for HTCondor workflow)"
  echo "raw2prmslc_ALOS.sh preproc_porotomo.lst"
  exit 1
fi


# determine host machine
servername=$(echo $HOSTNAME | awk -F. '{print $1}')
if [[ ${servername} == "ice" ]]; then
   echo "Currently on ice server. Please log in to porotomo and re-source your setup.sh script before proceeding."
   exit 1
elif [[ ${servername} != "porotomo" && ${servername} != "maule" ]]; then
   echo "Unrecognized host server name.  Please make sure you are on maule or porotomo."
   exit 1
fi

mkdir -p ../preproc
track=`pwd | awk -FALOS\/ '{print $2}' | awk -F\/raw '{print $1}'`

# form processed files for ALOS1
while read -r img led; do
 if [[ ${servername} == "porotomo" ]]; then
   scp $maule:/s21/insar/ALOS/$track/preproc/$img .
   scp $maule:/s21/insar/ALOS/$track/preproc/$led .
 else
   cp /s21/insar/ALOS/$track/preproc/$img .
   cp /s21/insar/ALOS/$track/preproc/$led .
 fi
 scene_date=`echo $img | awk -F- '{print $3}'`
 ALOS_pre_process_SLC $img $led
 mv *.PRM ../preproc/${scene_date}.PRM
 mv *.SLC ../preproc/${scene_date}.SLC 
done < $1

