#!/bin/bash
# Script to automatically query for TSX data monthly, with pre-processing and update to pairlist
# Elena C Reinisch 20170215

# define variables
tstart=$1
tend=$2
track=$3

# query for new data
getTSXdata.sh -s${tstart} -e${tend} -t${track}

download_lst=`ls download-$(date +%Y%m%d)* | tail -1`
for i in `cat $download_lst  | awk -F/ '{print $(NF); next}'`; do
tar -xzvf i
done

cat $download_lst  | awk -F/ '{print $(NF); next}' | awk -F. '{print $1; next}' > dir.lst 

# Preprocess new data
raw2prmslc_TSX.sh dir.lst
rm dir.lst

# update pairlist
cd RAW
egenerate_pairlist.sh
