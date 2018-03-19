#!/bin/bash
# Script for querying/downloading S1A data based on Scott Baker's ssara_federated_query.py
# If data is downloaded preparation for pre-processing on HTC is performed
# Elena C. Reinisch 20170125
# edit ECR 20170301 adding pre-processing preparation if data is downloaded
# edit ECR 20170307 incorporate change from raw/RAW to raw, preproc

if [[ $# -eq 0 ]]
then
  echo "query and download S1A data"
  echo "inputs: [site] [query start interval date, given in YYYY-MM-DD] [query end interval date, given in YYYY-MM-DD] [d/k, d for download k for kml file]"
  echo "Example, kml only:"
  echo " getS1Adata.sh brady 2016-10-01 2016-12-01 k"
  echo "Example, with download:"
  echo " getS1Adata.sh brady 2016-10-01 2016-12-01 d"
  exit 1
fi

# get parameters
site=$1
trk=$site
tstart=$2
tend=$3
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

# use SSARA query based on site's polygon
case "$site" in
"brady")
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-119.01911973953247 39.8040915261595,-118.99873495101929 39.8040915261595,-118.99873495101929 39.789088908334485,-119.01911973953247 39.789088908334485,-119.01911973953247 39.8040915261595))" -s $tstart -e $tend --$status
  ;;
"mcgin")
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-117.6919090194407 39.66684680613911, -117.6919090194407 39.67244569755783, -117.6849326882351 39.67244569755783, -117.6849326882351 39.66684680613911, -117.6919090194407 39.66684680613911))"  -s $tstart -e $tend --$status
  ;;
"dcamp")
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-118.35 38.815, -118.35 38.865, -118.25 38.865, -118.25 38.815, -118.35 38.815))"   -s $tstart -e $tend --$status
  ;;
"emesa") 
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-115.332916666 32.6670833334, -115.332916666 32.91625, -115.167083334 32.91625, -115.167083334 32.6670833334, -115.332916666 32.6670833334))"   -s $tstart -e $tend --$status
  ;;
"tungs")
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-117.6862733369275 39.67244569755783, -117.6919090194407 39.66776355092392, -117.6906027275874 39.66684680613911, -117.6849326882351 39.67153401886861, -117.6862733369275 39.67244569755783))" -s $tstart -e $tend --$status
 ;;
"dixie")
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-118.1375544666061 39.76728909273659, -117.9726034519923 39.76155907198107, -117.9661583795073 39.83590474090825, -118.1384607218144 39.83892561603565, -118.1375544666061 39.76728909273659))" -s $tstart -e $tend --$status
  ;;
*)
  echo "undefined polygon for site. Please udpate script"
  exit 1
  ;;
esac
# use SSARA query based on site's polygon
# first get metadata, and allow for script to time out the first few times`
lount=0
qcount=0
while [[ $lcount -lt 6 && $qcount -eq 0 ]]; do
  polygon=$(get_site_polygon.sh $site)
  echo POLYGON = $polygon
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="$polygon" -s $tstart -e $tend --kml

  let lcount=lcount+1
  qcount=`cat $(ls ssara_search*.kml | tail -1) | grep "Start Time" | wc -l`
done

# exit the script if query unsuccessful
if [[ $lcount -ge 6 ]]; then
  echo "Query was unsuccessful. Adjust search parameters or try again at a different time."
  exit 1
fi

# add in pre-preprocessing and transfer of data to to HTC if data was downloaded
if [[ "$status" == "download" ]]
then
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="$polygon" -s $tstart -e $tend --$status


 # unzip downloads
> newSAFE.lst

for i in `ls *.zip`; do
  if [[ ! -d `echo $i | awk -F.zip '{print $1".SAFE"}'` ]]
  then
    if [[ `echo $i` == *"1SDV"*  && $site == "brady" ]]
    then
      # remove dual band data
      rm $i
    else
      echo $i
      unzip $i
      echo "`echo $i | awk -F.zip '{print $1".SAFE"}'` " >> newSAFE.lst
    fi
  fi
done

# get orbital info
sentinel_orb.sh newSAFE.lst

# transfer data to submit-3 
paste newSAFE.lst newEOF.lst > newTransfer.lst
preS1A_htc.sh $trk $site newTransfer.lst
mv tmp transfer-`date +%Y%m%d_%H%M`

exit 

# get initial PRM files for egenerate_pairlist
tmp_preproc_S1A.sh $trk $site newTransfer.lst

# update pairlist
mkdir -p ../preproc
cd ../preproc
egenerate_pairlist.sh ${site}
cd ../raw

# move data to maule
# TBD
fi
