#!/bin/bash
# script to add new sat/track info to appropriate metadata text files
# script to add new sat/track info to appropriate metadata text files
# also make sure that the appropriate sat/trk directories are initialized
# Elena C Reinisch 20170828
# update ECR 20180321 change calling for txt files based on new gmtsar-aux organization
# update ECR 20180406 rsync to sync whole directory

if [[ $# -eq 0 ]]
then
  echo "script for adding a new site to the database"
  echo "you need to have the unique 5-letter id code for the site"
  echo "add_new_sattrack.sh [site ID] [sat] [track] [frame]"
  echo "e.g.:"
  echo "add_new_sattrack.sh brady TSX T53 strip_008R"
  exit 1
fi

site=$1
sat=$2
trk=$3
frame=$4

# check to see if site ID is already in use
if [[ `grep $site ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $trk | grep $frame | wc -l` -gt 0 ]]
then
   echo "It looks like this is already in the database.  Please double check."
   exit 1
fi

# add sat information to site_sats.txt 
echo "$site $sat $trk $frame" >> ~ebaluyut/gmtsar-aux/site_sats.txt
if [[ "$sat" == "TSX" ]]
then
  echo "$site TDX $trk $frame" >> ~ebaluyut/gmtsar-aux/site_sats.txt
fi

#scp ~ebaluyut/gmtsar-aux/site_sats.txt $t31/ebaluyut/gmtsar-aux/

# make sure directory for track exists on maule and porotomo
mkdir -p /s21/insar/$sat/$trk/raw
mkdir -p /s21/insar/$sat/$trk/preproc
mkdir -p /s21/insar/$sat/$trk/site
ssh -Y $ice "mkdir -p /mnt/t31/insar/$sat/$trk/raw; mkdir -p /mnt/t31/insar/$sat/$trk/preproc; mkdir -p /mnt/t31/insar/$sat/$trk/$site"

# sync between servers
rsync -a ~ebaluyut/gmtsar-aux/ $t31/ebaluyut/gmtsar-aux
rsync -a ~ebaluyut/gmtsar-aux/ $submit3:/home/ebaluyut/gmtsar-aux
