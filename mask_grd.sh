#!/bin/bash
# mask a grid file based on polygon
# ECR 20180130

if [[ $# -eq 0 ]]; then
   echo "makes masked version of grd file based on polygons in input file"
   echo "outputs to grid file with masked_ prepended to name"
   echo "mask_grd.sh [polygons text file] [grd file to mask]"
   echo "e.g. mask_grd.sh polygons.txt grd.grd"
   exit 1
fi

# initialize
poly=$1
gfile=$2

# get mask from polygon
gmt grdmask ${poly} -R${gfile} -N1/NaN/NaN -Gmask.grd

# apply mask
gmt grdmath ${gfile} mask.grd OR = masked_${gfile}
