#!/bin/bash
# small script for preparing topo subdirectory on maule. Run in head directory with topo, intf. RAW, and gipht as subdirectories
# ECR 20190520

site=$1
#demf=`tail -1 intf/PAIRSmake_check.txt | awk '{print $18}'`
demf=`cat intf/PAIRSmake_check.txt | awk '{print $18}' | grep grd | head -1`
#gcut=`get_site_dims.sh ${site} 1`
cp /s21/insar/condor/feigl/insar/dem/cut_${demf} -Gtopo/dem.grd
