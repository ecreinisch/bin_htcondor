#!/bin/bash
# script to give dimensions of interest based on site 
# Elena C Reinisch 20180327
# batzli update 20210304 made more universal with $user variable but requires each user have /gmtsar-aux in their home directory as with /bin_htcondor
# 2021/03/18 Kurt and Sam, make "batzli" the user to hold the data base

# SITE 5 LETTER CODE NAMES
#
# brady - Bradys Hot Springs, NV, USA
# maule - Laguna del Maule, Chile
# mcgin - McGinness Hills
# dcamp - Don Campell
# cosoc - Coso, CA
# tungs - Tungsen
# emesa - East Mesa
# fallo - Fallon, NV
# milfo - Milford, UT
# fawns - Fawnskin

if [[ $# -eq 0 ]]; then
  echo "script to give dimensions of interest based on site"
  echo "usage: get_site_dims.sh [site] [coordinate system index (1 for lat/lon, 2 for UTM, 3 for UTM zone)]"
  echo "e.g., get_site_dims.sh brady 1"
  exit 1
fi

if [[ $# -eq 1 ]]; then
 echo "must input coordinate system index"
 echo "1 for lat/lon"
 echo "2 for UTM"
 echo "3 for UTM zone"
 exit 1
fi

# get user name for location of text file 
# user=`echo $HOME | awk -F/ '{print $(NF)}'`
# on Askja, Sam Batzli holds reference (and only) copy of this data base.
# It is private. 
user="batzli"

site=$1
coord_id=$2

if [[ `grep $site /home/${user}/gmtsar-aux/site_dims.txt | wc -l` -gt 0 ]]; then
  if [[ `grep $site -A${coord_id} /home/${user}/gmtsar-aux/site_dims.txt | tail -1 | wc -w` -gt 0 ]]; then  
    echo $(grep $site -A${coord_id} /home/${user}/gmtsar-aux/site_dims.txt | tail -1)
  else 
    echo "option not yet defined for this site."
    exit 1
  fi
else 
  echo "site undefined."
  exit 1
fi
