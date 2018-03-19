#!/bin/bash
# script to add new site info to appropriate metadata text files
# Elena C Reinisch 20170828
# edit ECR 20170830 check to see if ID is already in get_site_dims.sh

if [[ $# -eq 0 ]]
then
  echo "script for adding a new site to the database"
  echo "you need to have a unique 5-letter id code for the site and the DEM file in the current directory"
  echo "add_new_site.sh [site ID] [dem_file_name] [GMT -R region] [polygon] [optional, -R region in UTM] [UTM zone number]"
  echo "e.g.:"
  echo 'add_new_site.sh uwmad test_uwmad_dem.grd -R-89.80/-89.02/42.82/43.31 "POLYGON((-89.80 42.82, -89.02 42.82, -89.02 43.31, -89.80 43.31, -89.80 42.82))"'
  exit 1
fi

site=$1
demf=$2
region=$3
polygon=$4
utmregion=$5
utmzone=$6

# check to see if site ID is already in use
if [[ `grep $site ~ebaluyut/gmtsar-aux/get_site_dims.sh | wc -l` -gt 0 ]]
then
   echo "site ID in use already.  Please choose a different site ID"
   exit 1
fi

# add site information to site_dems.txt 
echo "$site $demf" >> ~ebaluyut/gmtsar-aux/txt_files/site_dems.txt
scp ~ebaluyut/gmtsar-aux/txt_files/site_dems.txt $t31/ebaluyut/gmtsar-aux/txt_files/
cp $demf /s21/insar/condor/feigl/insar/dem/
scp $demf $t31/ebaluyut/scratch/TEST_GMTSAR/insar/dem/

# add region information to get_site_dims.sh
sed -i "/*)/i \
\"$site\")" ~ebaluyut/gmtsar-aux/get_site_dims.sh
sed -i "/\"$site\"/a \  echo \"$region\"" ~ebaluyut/gmtsar-aux/get_site_dims.sh
sed -i "/*)/i \  ;;" ~ebaluyut/gmtsar-aux/get_site_dims.sh

scp ~ebaluyut/gmtsar-aux/get_site_dims.sh $t31/ebaluyut/gmtsar-aux
scp ~ebaluyut/gmtsar-aux/get_site_dims.sh $submit3:/home/ebaluyut/binKF

# add polygon information 
sed -i "/*)/i \
\"$site\")" ~ebaluyut/gmtsar-aux/get_site_polygon.sh
sed -i "/\"$site\"/a \  echo \"$polygon\""  ~ebaluyut/gmtsar-aux/get_site_polygon.sh
sed -i "/*)/i \  ;;"  ~ebaluyut/gmtsar-aux/get_site_polygon.sh 

# utm if supplied
if [[ ! -z $utmregion && ! -z $utmzone ]]
then
sed -i "/*)/i \
\"$site\")" ~ebaluyut/gmtsar-aux/get_site_dims_utm.sh
sed -i "/\"$site\"/a \  echo \"$utmregion\"" ~ebaluyut/gmtsar-aux/get_site_dims_utm.sh
sed -i "/*)/i \  ;;" ~ebaluyut/gmtsar-aux/get_site_dims_utm.sh

sed -i "/*)/i \
\"$site\")" ~ebaluyut/gmtsar-aux/get_site_utmzone.sh
sed -i "/\"$site\"/a \  echo \"$utmzone\""  ~ebaluyut/gmtsar-aux/get_site_utmzone.sh
sed -i "/*)/i \  ;;"  ~ebaluyut/gmtsar-aux/get_site_utmzone.sh
fi
