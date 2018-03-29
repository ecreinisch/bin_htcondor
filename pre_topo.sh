#!/bin/bash
# small script for preparing topo subdirectory. Run in head directory with topo, intf. RAW, and gipht as subdirectories
# ECR 20170228
# update ECR 20180327 update for new get_site_dims.sh

site=$1
demf=`tail -1 intf/PAIRSmake_check.txt | awk '{print $18}'`
gcut=`get_site_dims.sh ${site} 1`
gmt grdcut /t31/ebaluyut/scratch/TEST_GMTSAR/insar/dem/${demf} ${gcut} -Gtopo/dem.grd
