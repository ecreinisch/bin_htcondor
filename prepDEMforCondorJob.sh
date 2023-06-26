#!/bin/bash 
#!/usr/bin/env -S bash 

# script that makes sure there is a cut version of the DEM for each site
# Elena C Reinisch 20170709
# batzli 20210211 change for running on askja
# 2021/07/21 - not needed

if [[ ! $# -eq 5 ]] ; then
    echo "ERROR: $0 requires 5 arguments."
    exit 0
fi

demf=$1
xmin=$2
xmax=$3
ymin=$4
ymax=$5

# make sure you add GMT to path
#source /home/ebaluyut/setup.sh
#source ~/setup.sh

# check to see if cut version exists; if it doesn't, create one
#if [[ ! -e /s21/insar/condor/feigl/insar/dem/cut_$demf ]]
#then
#   grdcut /s21/insar/condor/feigl/insar/dem/$demf -G/s21/insar/condor/feigl/insar/dem/cut_$demf -R${xmin}/${xmax}/${ymin}/${ymax}
#fi

# askja version
if [[ ! -e /s12/insar/dem/cut_$demf ]]; then
	echo "cut version of $demf not found.  Making one now..."
	gmt grdcut /s12/insar/dem/$demf -G/s12/insar/dem/cut_$demf -R${xmin}/${xmax}/${ymin}/${ymax}
else
	echo "cut version of $demf found.  Will use /s12/insar/dem/cut_$demf "
fi

