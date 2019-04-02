#!/bin/bash
# script to copy and rename ENVI data for HTCondor workflow
# run in raw directory one level below track directory
# Elena C Reinisch 20170616

# get list of ALOS data directories
ls -d ASA_IM* > dirlist.tmp

# make preproc directory if doesn't already exist
mkdir -p ../preproc
cpwd=`pwd`
trk=`echo $cpwd | awk -F/raw '{print $1}' | awk -F/ '{print $(NF)}'`
> preproc_porotomo.lst

while read -r a; do
  datadir=$a
  # get calendar date of scene
  if [[ "$datadir" == *"CNPDE"* ]]; then
  scene_date=`echo $a | awk -FCNPDE '{print $2}' | awk -F_ '{print $1}'`
  else
  scene_date=`echo $a | awk -FCNPDK '{print $2}' | awk -F_ '{print $1}'`
  fi
  if [[ `ls ../preproc/*${scene_date}* | wc -l` -eq 0 ]]
  then
     # replace data ID with scene date in link version for HTCondor
     cp  $datadir ${scene_date}.baq 

     # copy data to /t31/insar/ALOS/[trk]/raw on porotomo to run preprocessing scripts
     scp ${scene_date}.baq $t31/insar/ENVI/${trk}/raw/
     echo ${scene_date}.baq  >> preproc_porotomo.lst

     # make tar file and remove extra files
     tar -czvf ${scene_date}.tgz ${scene_date}.baq 
     mv ${scene_date}.tgz ${scene_date}.baq ../preproc/
  fi
done < dirlist.tmp
scp preproc_porotomo.lst $t31/insar/ENVI/${trk}/raw/

# remove temporary list files
rm dirlist.tmp
