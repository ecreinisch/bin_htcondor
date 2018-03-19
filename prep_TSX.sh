#!/bin/bash
# script for tarring the appropriate preprocessed files for TSX for HTCondor jobs
# run in preproc directory
# Elena C Reinisch 20170831

ls *.PRM > list.tmp

while read -r a; do
  epoch=`echo $a | awk -F\.PRM '{print $1}'`
  tar -czvf $epoch.tgz $epoch.LED $epoch.PRM $epoch.SLC
done < list.tmp

rm list.tmp
