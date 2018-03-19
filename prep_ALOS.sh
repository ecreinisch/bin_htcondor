#!/bin/bash
# script to copy and rename ALOS data for HTCondor workflow
# run in raw directory one level below track directory
# Elena C Reinisch 20170603

# get list of ALOS data directories
ls -d ALPSRP* > dirlist.tmp

# make preproc directory if doesn't already exist
mkdir -p ../preproc
cpwd=`pwd`
trk=`echo $cpwd | awk -F/raw '{print $1}' | awk -F/ '{print $(NF)}'`
> preproc_porotomo.lst

while read -r a; do
  datadir=$a
  # get calendar date of scene
  scene_date=`grep Img_SceneStartDateTime ${datadir}/*.workreport | awk -F\" '{print $2}' | awk '{print $1}'`
  if [[ `ls ../preproc/*${scene_date}* | wc -l` -eq 0 ]]
  then
  ls $datadir/IMG* $datadir/LED* > files.tmp
 # make a link to each necessary data file in preproc, renamed to epoch date
  while read -r b; do
     datafile=$b
     # get data ID in original data file name
     dirid=`echo $datadir | awk -F- '{print $1}'`
     frame=`echo $dirid | awk -F\- '{print $1}' | awk '{print substr($1, 12, 4)}'`
     # replace data ID with scene date in link version for HTCondor
     ln -s  $cpwd/$datafile ../preproc/`echo $datafile | awk -F/ '{print $2}' | sed "s/${dirid}/${scene_date}/"`

     # copy data to /t31/insar/ALOS/[trk]/raw on porotomo to run preprocessing scripts
     scp $cpwd/$datafile $t31/insar/ALOS/${trk}/raw/`echo $datafile | awk -F/ '{print $2}' | sed "s/${dirid}/${scene_date}/"`
  done < files.tmp
  echo `ls ../preproc/IMG-HH*${scene_date}* | awk -F/ '{print $(NF)}'` `ls ../preproc/LED*${scene_date}* | awk -F/ '{print $(NF)}'` >> preproc_porotomo.lst
  # make tar file and remove extra files
  cd $datadir
  tar -czvf ${scene_date}_${frame}.tgz IMG* LED*
  mv ${scene_date}_${frame}.tgz ../../preproc/
  cd ..
  fi
done < dirlist.tmp
scp preproc_porotomo.lst $t31/insar/ALOS/${trk}/raw/

# remove temporary list files
rm dirlist.tmp files.tmp
