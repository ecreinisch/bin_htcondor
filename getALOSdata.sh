#!/bin/bash
# Script for querying/downloading ALOS data based on Scott Baker's ssara_federated_query.py
# Elena C. Reinisch 20170608
# edit ECR 20170828 remove cases statement for sites, pull polygon info from get_site_polygon.sh
# edit ECR 20170828 add beam mode option and nan placeholder for optional parameters
# edit ECR 20180322 add --asfResponseTimeout=25 to mitigate ASF time outs
# edit ECR 20180807 add check for frame discrepancy (in reference to ALOS T112 Frame 6450 discrepancy for maule)

if [[ $# -eq 0 ]]
then
  echo "query and download ALOS data"
  echo "inputs: [site] [query start interval date, given in YYYY-MM-DD] [query end interval date, given in YYYY-MM-DD] [d/k, d for download k for kml file] [optional track number (no T)] [optiobal frame number] [optional beam mode (FBS/FBD)]"
  echo "for any optional parameters you don't want to specify you can enter nan as a placeholder value to add optional parameters further down in the list"
  echo "Example, kml only:"
  echo " getALOSdata.sh brady 2016-10-01 2016-12-01 k"
  echo "Example, with download:"
  echo " getALOSdata.sh brady 2016-10-01 2016-12-01 d"
  echo "Example with track 215 from frame 780 with beam mode FBD"
  echo "getALOSdata.sh brady 2010-10-01 2010-12-01 d 215 780 FBD"
  echo "Example, specify beammode without frame"
  echo "getALOSdata.sh brady 2010-10-01 2010-12-01 d 215 nan FBD"
  exit 1
fi

# get parameters
site=$1
trk=$site
tstart=$2
tend=$3
trk=$5
frame=$6
beammode=$7
if [[ ! -z $trk ]]
then
  if [[ $trk == nan ]]
  then
    trk=
  else
    trk="-r $trk"
  fi
fi
if [[ ! -z $frame ]]
then
   if [[ $frame == nan ]]
   then
     frame=
    else
     frame="-f $frame"
   fi
fi
if [[ ! -z $beammode ]]
then
   if [[ $beammode == nan ]]
   then
     beammode=
   else
     beammode="--beamMode=$beammode"
   fi
fi

echo $site
echo $tstart
echo $tend
if [[ "$4" == "d" ]]
then
  status=download
elif [[ "$4" == "k" ]]
then
  status=kml
else 
  echo "unrecognized option (enter d for download or k for kml). Defaulting to kml"
  status=kml
fi

# remove old search files
echo "moving any previous search kmls to search_archive"
mv ssara_search*kml search_archive/

# use SSARA query based on site's polygon
# first get metadata, and allow for script to time out the first few times`
lount=0
qcount=0
while [[ $lcount -lt 6 && $qcount -eq 0 ]]; do
  polygon=$(get_site_polygon.sh $site)
  echo POLYGON = $polygon
  ssara_federated_query.py --platform=ALOS --intersectsWith="$polygon" --asfResponseTimeout=25 -s $tstart -e $tend $trk $frame $beammode --kml

  let lcount=lcount+1
  qcount=`cat $(ls ssara_search*.kml | tail -1) | grep "Start Time" | wc -l`
done 

# exit the script if query unsuccessful
if [[ $lcount -ge 6 ]]; then
  echo "Query was unsuccessful. Adjust search parameters or try again at a different time."
  exit 1
fi

#if downloading, call the script again
if [[ "$status" == "download" ]]
then
  ssara_federated_query.py --platform=ALOS --intersectsWith="$polygon" --asfResponseTimeout=25 -s $tstart -e $tend $trk $frame $beammode --$status
fi

if [[ ! -z $frame ]]; then
# double check that frame information in query file is correct (in reference to ALOS T112 Frame 6450 discrepancy for maule)
newkml=$(ls ssara*.kml | tail -1)
if [[ `grep "Download URL" ${newkml} | awk -F/ '{print $NF}' | awk -F- '{print substr($1, 12, 4)}' | sort -u | wc -l` -gt 1 ]]; then
   echo "discrepancy between frames (more than one frame downloaded). Check kml and downloaded zip files"
   exit 1
fi

dataframe=$(grep "Download URL" ${newkml} | awk -F/ '{print $NF}' | awk -F- '{print substr($1, 12, 4)}' | sort -u)

if [[ `grep "First Frame" ${newkml} | awk -F" : " '{print $2}' | head -1` != ${dataframe} ]]; then
   echo "Discrepancy between kml listed frame and frame of data.  Editing kml file to include proper frame."
   echo "To reproduce this error, run:"
   echo "ssara_federated_query.py --platform=ALOS --intersectsWith=$polygon --asfResponseTimeout=25 -s $tstart -e $tend $trk $frame $beammode --kml"
   kmlframe=$(grep "First Frame" ${newkml} | awk -F" : " '{print $2}' | head -1)
   sed -i "s/Frame : ${kmlframe}/Frame : ${dataframe}/g" ${newkml}
fi

fi
