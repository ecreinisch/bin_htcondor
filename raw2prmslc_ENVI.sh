#!/bin/bash
# script to run pre-processing for Envisat pairs; for pair database only - not used for interferogram formation
# Elena C Reinisch 20170725

if [[ $# -eq 0 ]]
then
  echo "raw2prmslc_ENVI.sh"
  echo "script to run pre-processing for Envisat pairs; for pair database only - not used for interferogram formation"
  echo "takes name of text file with list of .baq files that need processing (without the .baq extension)"
  echo "raw2prmslc_ENVI.sh preproc_porotomo.lst"
  exit 1
fi

while read -r a; do
  raw_stem_name=$a
  # run preprocessing with default values
  ENVI_pre_process $raw_stem_name 0 0 0
done < $1

# move preprocessed files to preproc
mv *.LED *.SLC *PRM ../preproc/
