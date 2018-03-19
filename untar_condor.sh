#!/bin/bash
# script to untar condor pairs from maule and place PRM and LED files in preproc directory
# Elena C Reinisch 20170430
# edit ECR 20170725 add option to copy PRM and LED files from preproc if they weren't transferred with the job

# get list of pair tar files
ls In*.tgz > tarlist
cpwd=`pwd`

while read -r a; do 
  echo $a
  # untar interferogram directory
  tar -xzvf $a
  # get pair and mast/slav names
  pair=`echo $a | awk -F. '{print $1}'`
  mast=`echo $pair | awk -F_ '{print $1}' | awk -Fn '{print $2}'`
  slav=`echo $pair | awk -F_ '{print $2}'`
  # get PRM and LED file names
  mastLED=`find $pair -name *${mast}*LED`
  slavLED=`find $pair -name *${slav}*LED`
  mastPRM=`find $pair -name *${mast}*PRM`
  slavPRM=`find $pair -name *${slav}*PRM`
  # copy PRM and LED files from preproc directory if they aren't in pair directory already
  if [[ -z $mastLED ]]
  then
     preproc_dir=`pwd | awk -F/ '{print $1"/"$2"/"$3"/"$4"/"$5"/preproc/"}'`
     cp $preproc_dir/$mast.LED $pair/
     cp $preproc_dir/$mast.PRM $pair/
     cp $preproc_dir/$slav.LED $pair/
     cp $preproc_dir/$slav.PRM $pair/
     mastLED=`find $pair -name *${mast}*LED`
     slavLED=`find $pair -name *${slav}*LED`
     mastPRM=`find $pair -name *${mast}*PRM`
     slavPRM=`find $pair -name *${slav}*PRM`
  fi
  # make links to preproc files
  ln $mastLED ../preproc/$mast.LED
  ln $mastPRM ../preproc/$mast.PRM
  ln $slavLED ../preproc/$slav.LED
  ln $slavPRM ../preproc/$slav.PRM
done < tarlist

# clean up
rm tarlist
rm In*.tgz

