#!/bin/bash
# script that makes sure there is a cut version of the DEM for each site
# Elena C Reinisch 20170709
demf=$1
xmin=$2
xmax=$3
ymin=$4
ymax=$5

# make sure you add GMT to path
#source /home/ebaluyut/setup.sh
source ~/setup.sh

# check to see if cut version exists; if it doesn't, create one
if [[ ! -e /s21/insar/condor/feigl/insar/dem/cut_$demf ]]
then
   grdcut /s21/insar/condor/feigl/insar/dem/$demf -G/s21/insar/condor/feigl/insar/dem/cut_$demf -R${xmin}/${xmax}/${ymin}/${ymax}
fi
