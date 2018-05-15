#!/bin/bash
# script to untar condor pairs from maule and place PRM and LED files in preproc directory
# Elena C Reinisch 20170430
# edit ECR 20170725 add option to copy PRM and LED files from preproc if they weren't transferred with the job
# edit ECR 20180404 correct metadata files to make soft links in preproc dir; check that links don't exist before trying to make them
# edit ECR 20180418 fix pathnames to LED and PRM files
# edit ECR 20180511 fix symlink for slav LED and PRM files
# edit ECR 20180515 fix symlink for LED and PRM files to establish link from within preproc dir

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
  preproc_dir=`pwd | awk -F/ '{print $1"/"$2"/"$3"/"$4"/"$5"/preproc"}'`
  if [[ -z $mastLED ]]
  then
     cp $preproc_dir/*$mast*.LED $pair/
     mastLED=`find $pair -name *${mast}*LED`
  fi
  if [[ -z $mastPRM ]]
  then
     cp $preproc_dir/*$mast*.PRM $pair/
     mastPRM=`find $pair -name *${mast}*PRM`
  fi
  if [[ -z $slavLED ]]
  then
     cp $preproc_dir/*$slav*.LED $pair/
     slavLED=`find $pair -name *${slav}*LED`
  fi
  if [[ -z $slavPRM ]]
  then
     cp $preproc_dir/*$slav*.PRM $pair/
     slavPRM=`find $pair -name *${slav}*PRM`
  fi

  # make links to preproc files
  if [[ ! -e ../preproc/${mast}.LED && ! -L ../preproc/$mast.LED ]]; then
    mastLEDname=`echo $mastLED | awk -F/ '{print $2}'`
    mastPRMname=`echo $mastPRM | awk -F/ '{print $2}'`
    cd ../preproc
    ln -s ../intf/$mastLED $mast.LED
    ln -s ../intf/$mastPRM $mast.PRM
    cd ../intf
  fi
  if [[ ! -e ../preproc/${slav}.LED && ! -L ../preproc/$slav.LED ]]; then 
    slavLEDname=`echo $slavLED | awk -F/ '{print $2}'`
    slavPRMname=`echo $slavPRM | awk -F/ '{print $2}'`
    cd ../preproc
    ln -s ../intf/$slavLED $slav.LED
    ln -s ../intf/$slavPRM $slav.PRM
    cd ../intf
  fi
done < tarlist

# clean up
rm tarlist
rm In*.tgz

