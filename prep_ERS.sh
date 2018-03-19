#!/bin/bash
# script to copy and rename ERS data for HTCondor workflow
# run in raw directory one level below track directory
# Elena C Reinisch 20170616

# get list of ERS data directories
ls -d ER0* > dirlist.tmp

# make preproc directory if doesn't already exist
mkdir -p ../preproc
cpwd=`pwd`
trk=`echo $cpwd | awk -F/raw '{print $1}' | awk -F/ '{print $(NF)}'`
> preproc_porotomo.lst

while read -r a; do
  datadir=$a
  # get calendar date of scene
  scene_date=`echo $datadir  | awk -F_ '{print $5}' | awk -FT '{print $1}'`
  if [[ `ls ../preproc/*${scene_date}* | wc -l` -eq 0 ]]
  then
     # make a link to each necessary data file in preproc, renamed to epoch date
     cp $datadir/DAT_01.001 ${scene_date}.dat
     cp $datadir/LEA_01.001 ${scene_date}.ldr

    # determine if ERS1 or ERS2
    if [[ `echo $datadir  | awk -F_ '{print $1}'` == "ER01" ]]
    then
      sat=ERS1
    elif [[ `echo $datadir  | awk -F_ '{print $1}'` == "ER02" ]]
    then
      sat=ERS2
    else
       echo "sat unknown."
       exit 1
    fi

     # copy data to /t31/insar/ALOS/[trk]/raw on porotomo to run preprocessing scripts
     scp ${scene_date}.dat ${scene_date}.ldr $t31/insar/${sat}/${trk}/raw/
     echo ${scene_date}  >> preproc_porotomo.lst
 
 # make tar file and remove extra files
  tar -czvf ${scene_date}.tgz ${scene_date}.dat ${scene_date}.ldr
  mv ${scene_date}.tgz ${scene_date}.dat ${scene_date}.ldr ../preproc/
  fi
done < dirlist.tmp
scp preproc_porotomo.lst $t31/insar/${sat}/${trk}/raw/

# remove temporary list files
rm dirlist.tmp 
