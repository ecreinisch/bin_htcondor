#!/bin/bash
# Script for querying/downloading S1A data based on Scott Baker's ssara_federated_query.py
# If data is downloaded preparation for pre-processing on HTC is performed
# Elena C. Reinisch 20170125
# edit ECR 20170301 adding pre-processing preparation if data is downloaded
# edit ECR 20170307 incorporate change from raw/RAW to raw, preproc
# edit ECR 20171204 add maule polygon
# edit ECR 20180319 comment out outdate portions of script at bottom and fix fi issue
# edit ECR 20180319 remove case statement and replace with output of get_site_polygon.sh 
# edit ECR 20180322 add --asfResponseTimeout=25 to mitigate ASF time outs; add check to see if EarthData End User Agreement has been signed
# edit ECR 20180604 add option for frame specification
# 20191009

if [[ $# -eq 0 ]]
then
  echo "query and download S1A and S1B data"
  echo "inputs: [site] [query start interval date, given in YYYY-MM-DD] [query end interval date, given in YYYY-MM-DD] [optional track/frame, number only, e.g. 144 (for track only), 144/14 (for tack and frame)] [d/k, d for download k for kml file]"
  echo "Example, kml only:"
  echo " getS1Adata.sh brady 2016-10-01 2016-12-01 k"
  echo "Example, with download and track specified:"
  echo " getS1Adata.sh brady 2016-10-01 2016-12-01 144 d"
  echo "Example, with download, track, and frame specified:"
  echo "getS1Adata.sh fuego 2018-01-01 2018-06-04 136/43 d"
  exit 1
fi

# get parameters
site=$1
tstart=$2
tend=$3
echo $site
echo $tstart
echo $tend

if [[ $# -eq 4 ]]
then 
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
   trk=
elif [[ $# -eq 5 ]]
then
  if [[ "$5" == "d" ]]
   then
     status=download
   elif [[ "$5" == "k" ]]
   then
     status=kml
   else
     echo "unrecognized option (enter d for download or k for kml). Defaulting to kml"
     status=kml
   fi
   if [[ `echo $4 | grep / | wc -l` -eq 0  ]]
   then
     trk="-r $4"
     frame=""
   else
     trk="-r $(echo $4 | awk -F/ '{print $1}')"
     frame="-f $(echo $4 | awk -F/ '{print $2}')"
   fi
fi

# use SSARA query based on site's polygon
polygon=$(get_site_polygon.sh $site)

# only continue if site is defined
if [[ `echo ${polygon} | grep POLYGON | wc -l` -gt 0 ]]; then
  echo POLYGON = $polygon
else
  echo "site not yet added to workflow or polygon not in get_site_polygon.sh.  See manual to learn how to add a site to the workflow."
  exit 1
fi

# first get metadata, and allow for script to time out the first few times`
lount=0
qcount=0
while [[ $lcount -lt 6 && $qcount -eq 0 ]]; do
  ssara_federated_query.py --platform="SENTINEL-1A,SENTINEL-1B" --intersectsWith="$polygon" ${trk} ${frame} --asfResponseTimeout=25 -s $tstart -e $tend --kml

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
#  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="$polygon" $trk --asfResponseTimeout=25 -s $tstart -e $tend --$status

grep "Download URL" $(ls ssara_search*.kml | tail -1) | awk '{print $4}' > ziplist.tmp
wget --user $asfuser --password $asfpass -i ziplist.tmp

# check that END_USER agreement has been signed
if [[ `ls -l *zip | awk '{print $5}' | grep 1544` -gt 0 ]]; then
   echo "It looks like the .zip files have not been downloaded correctly.  Check to see that they are zip files and not text files.  If they are text files, go to https://vertex.daac.asf.alaska.edu/, log in to your Earthdata account (same credentials as ASF) and complete the End User Agreement"
   exit 1
fi


# # unzip downloads
> newSAFE.lst

for i in `ls *.zip`; do
  if [[ ! -d `echo $i | awk -F.zip '{print $1".SAFE"}'` ]]
  then
#    if [[ `echo $i` == *"1SDV"* ]]
#    then
#      # remove dual band data
#      rm $i
#    else
      echo $i
      unzip $i
      echo "`echo $i | awk -F.zip '{print $1".SAFE"}'` " >> newSAFE.lst
#    fi
  fi
done

# COMMENT OUT BELOW BECAUSE NEW SETUP ON MAULE
## get orbital info
#sentinel_orb.sh newSAFE.lst
#
## transfer data to submit-3 
#paste newSAFE.lst newEOF.lst > newTransfer.lst
#preS1A_htc.sh $trk $site newTransfer.lst
#mv tmp transfer-`date +%Y%m%d_%H%M`
#
#exit 
#
## get initial PRM files for egenerate_pairlist
#tmp_preproc_S1A.sh $trk $site newTransfer.lst
#
## update pairlist
#mkdir -p ../preproc
#cd ../preproc
#egenerate_pairlist.sh ${site}
#cd ../raw
#
## move data to maule
## TBD
fi
