#!/bin/bash
# script to copy and rename S1A data for HTCondor workflow
# run in raw directory one level below track directory
# Elena C Reinisch 20170725
# update ECR 20180322 process only new directories to save time and avoid re-processing

if [[ $# -eq 0 ]]
then
  echo "script to copy and rename S1A data for HTCondor workflow"
  echo "prep_S1A.sh [track] [site]"
  echo "prep_S1A.sh T144 brady"
  exit 1
fi

# get list of S1A data directories that need EOF files (presumably newly downloaded data)
#ls -d S1A* > dirlist.tmp
ls -d *SAFE > allSAFEdir.tmp
ls *SAFE/*.EOF | awk -F/ '{print $1}' > SAFEdirEOF.tmp
comm -13 <(sort SAFEdirEOF.tmp) <(sort allSAFEdir.tmp) > dirlist.tmp

# make preproc directory if doesn't already exist
mkdir -p ../preproc
cpwd=`pwd`
trk=$1
site=$2

# get orbit files and save to pair directory
sentinel_orb.sh dirlist.tmp

#paste dirlist.tmp newEOF.lst > preproc_porotomo.lst
cp new_raw.lst preproc_porotomo.lst

# put data in condor format 
preS1A_htc.sh $trk $site preproc_porotomo.lst

# copy to geology computer (/mnt/t31 is on porotomo.geology.wisc.edu)
# not needed 
#scp preproc_porotomo.lst $t31/insar/S1A/${trk}/raw/

# remove temporary list files
rm dirlist.tmp SAFEdirEOF.tmp allSAFEdir.tmp
