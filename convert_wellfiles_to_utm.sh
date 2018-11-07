#!/bin/bash
# simple script to convert lat/lon well files to UTM files 
# input file format: lon lat [optional well name]
# output file format: utmx utmy [optional well name]
# Elena C Reinisch 20180919

if [[ $# -eq 0 ]]
then
  echo "convert_wellfiles_to_utm.sh [file_name]"
fi

latlonfile=$1
utmfile=$(echo $latlonfile | awk -F.txt '{print $1"_utm.txt"}')
> $utmfile

# check that bin_htcondor_home variable will be recognized
if [[ `echo $bin_htcondor_home | grep "~" | wc -l` -gt 0 ]]; then
   echo "Warning: your $bin_htcondor_home variable uses ~.  Python scripts will not be able to recognize this path variable.  Please change your $bin_htcondor_home variable to a hard path, like /usr1/[username]/bin_htcondor or /home/[username]/bin_htcondor in your setup.sh script and resource before running this script again."
   exit 1
fi

while read line; do
  if [[ `echo $line | grep ">" | wc -l` -eq 0 ]]; then
  lat=$(echo $line | awk '{print $2}')
  lon=$(echo $line | awk '{print $1}')
  extradata=$(echo $line | awk '{print $3}')
  python ${bin_htcondor_home}/python2deg2utm.py $lat $lon > utm.tmp
  utmx=$(grep Easting utm.tmp | awk '{print $3}')
  utmy=$(grep Northing utm.tmp | awk '{print $3}')
  echo $utmx $utmy $extradata >> $utmfile
  rm utm.tmp
  else
  echo $line >> $utmfile
  fi
done < $latlonfile

