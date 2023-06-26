#!/bin/bash
#
# 20210301 script for finding epoch date and absOrbit in DLR folder
# takes one argument: folder name

# if no argument is supplied, display usage 
display_usage() {
        echo "Please provide a folder downloaded and gunzipped from DLR." 
        echo "Example: getDatefromDLR.sh dims_op_oc_dfd2_578204172_1"
        echo "(does not work on a .tar.gz file: try tar -xvf [file].tar.gz)"	
        }

if [  $# -le 0 ]
        then
        display_usage
        exit 1
fi

if [[ ${1} == *"tar.gz"* ]];
        then
        display_usage
        exit 1
fi

XML=`find ${1} -name "*.xml" | grep -v ANNOTATION | grep -v iif`
thedate=`grep startTimeUTC $XML | awk 'NR==1{print substr($1,15,4) substr($1,20,2) substr($1,23,2)}'`
absorbit=`grep absOrbit $XML | awk 'NR==1{print substr($1,11,5)}'`
relorbit=`grep relOrbit $XML | awk 'NR==1{print substr($1,11,2)}'`
echo "The date is $thedate and Absolute Orbit is: $absorbit and Relative Orbit is: $relorbit" 
