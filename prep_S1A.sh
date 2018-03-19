#!/bin/bash
# script to copy and rename S1A data for HTCondor workflow
# run in raw directory one level below track directory
# Elena C Reinisch 20170725

if [[ $# -eq 0 ]]
then
  echo "script to copy and rename S1A data for HTCondor workflow"
  echo "prep_S1A.sh [track] [site]"
  echo "prep_S1A.sh T144 brady"
  exit 1
fi

# get list of S1A data directories
ls -d S1A* > dirlist.tmp

# make preproc directory if doesn't already exist
mkdir -p ../preproc
cpwd=`pwd`
trk=$1
site=$2

# get orbit files and save to pair directory
sentinel_orb.sh dirlist.tmp

#paste dirlist.tmp newEOF.lst > preproc_porotomo.lst
cp new_raw.lst  preproc_porotomo.lst

# put data in condor format 
preS1A_htc.sh $trk $site preproc_porotomo.lst

scp preproc_porotomo.lst $t31/insar/S1A/${trk}/raw/

# remove temporary list files
rm dirlist.tmp 
