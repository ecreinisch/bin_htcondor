#!/bin/bash -vex

# set the region_cut parameter in the config file

ref=${1}
sec=${2}
cnf=${3}

cat config.tsx.txt | sed 's/proc_stage = 1/proc_stage = 1\n skip_stage = 2,3,4,5,6/' > config.tsx.step1.txt
p2p_processing.csh TSX ${ref} ${sec} config.tsx.step1.txt

# write subregion for cutting to config file
#sed -i "/region_cut/c\region_cut = $xmin/$xmax/$ymin/$ymax" $cnf
# 2021/07/06 Need to find radar coordinates (range, azimuth) for bounding box of (cut dem)
cd raw
echo Running dem2topo.csh
echo "Working directory is now $PWD"

dem2topo_ra.csh 20200415.PRM ../topo/dem.grd 

ra_cut=`gmt grdinfo -C topo_ra.grd | awk '{printf("%d/%d/%d/%d\n",$2,$3,$4,$5)}'`
#ra_cut='0/14350/0/12440'
cd ..
echo "ra_cut is $ra_cut"
sed -i "/region_cut/c\region_cut = $ra_cut" $cnf

# s12/feigl/In20200415_20210505
# if ( 0/14350/0/12440 !=  ) then
# echo "Cutting SLC image to $region_cut"
# echo Cutting SLC image to 0/14350/0/12440
# Cutting SLC image to 0/14350/0/12440
# cut_slc $master.PRM junk1 $region_cut
# cut_slc 20200415.PRM junk1 0/14350/0/12440
#  wrong range   

