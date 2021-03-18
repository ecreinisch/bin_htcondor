#!/bin/bash
#
# 20210301 script for finding epoch date in DLR folder
# takes one argument: folder name

# if no argument is supplied, display usage 
display_usage() {
        echo "Please provide a folder downloaded and gunzipped from DLR." 
        echo "Example: getDatefromDLR.sh dims_op_oc_dfd2_578204172_1"
        echo "(does not work on a .tar.gz file)"	
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
grep startTimeUTC $XML | awk 'NR==1{print substr($1,15,4) substr($1,20,2) substr($1,23,2)}'
