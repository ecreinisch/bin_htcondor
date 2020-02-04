#!/bin/bash -vx
# small script for preparing topo subdirectory on maule. Run in head directory with topo, intf. RAW, and gipht as subdirectories
# ECR 20190520
# 20200128 Kurt - look harder for name of DEM

site=$1
#demf=`tail -1 intf/PAIRSmake_check.txt | awk '{print $18}'`
#demf=`cat intf/PAIRSmake_check.txt | awk '{print $18}' | grep grd | head -1`

# 20200128
# find list of PAIRSmake files
pms=`find .. -name "PAIRSmake*"`
# find most recent PAIRSmake file
pm1=`\ls -t1 $pms | head -1 | awk '{print $1}'`
# find name of DEM 
demf=`cat $pm1 | awk '{print $18}' | grep grd | head -1`
#gcut=`get_site_dims.sh ${site} 1`
cp -v /s21/insar/condor/feigl/insar/dem/cut_${demf} topo/dem.grd
