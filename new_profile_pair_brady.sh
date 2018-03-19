#!/bin/bash
# plots profiles of gmt plots; builds off of Kurt Feigl's make_profile.csh and plot_grd_ll.csh 
# Elena C Reinisch 20160825
# variables are phase file directory and value being plotted
# e.g. ./profile_pair2.sh PHA phase; ./profile_pair2.sh PHAFILT phase-filtered
# 20170531 ECR update to allow for UTM plots
# update ECR 20180319 update for new bin_htcondor repo

if [[ $# -eq 0 ]]
then
  echo "script for plotting profiles of Brady pairs"
  echo "run in intf directory; plots returned in ../Profiles directory"
  echo "args: new_profile_pair_brady.sh [phase_grd_file (with .grd)] [quantity (e.g. phase, phase-filtered)] [sat] [track] [site]"
  exit 1 
fi


# define variables 
pha1=$1
quantity=$2
sat=$3
track=$4
site=$5

echo $pha1

if [[ $pha1 == *"phase"* ]]
then
type="phase"
elif [[ $pha1 == *"unwrap"* || $pha1 == *"drho"* || $pha1 == *"range"* ]]
then
type="unwrapped"
elif [[ $pha1 == *"drange"* ]]
then
type="unwrapped"
else
type="undefined"
echo "Warning: undefined filetype. See new_profile_pair_brady.sh for more details"
fi 

# make list of pairs
#find . -name "$pha1" | awk -F/ '{print $2}' | awk -F. '{print $1}' > InList
ls -d In2* > InList

# make directory to save profiles to (if doesn't exist)
mkdir -p ../Profiles

# make a profile plot for each pair 
while read -r a; do
cd $a
# get necessary text file that holds Brady box coordinates
cp ~ebaluyut/gmtsar-aux/txt_files/bradys_latlon .
> GrdList
> profile.rsp
> coord.rsp

#lat=(39.78525 39.795 39.8025)
#lon=(-119.0034 -119.0034 -119.001)
#lat=39.803
#lon=-119.005
# upper, mid, and lower reservoir
#lat=(39.803 39.8 39.791) 
#lon=(-119.005 -119.0105 -119.0179)
lat=39.804 #39.8030
lon=-119.007 # -119.008

# for DAS comparison segment 50
lat=39.799787084247832 #39.8030
lon=-119.0059781097303 # -119.008

for index in 0 # 2 # 0 1 2
do
# get profile values with designated profile
#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh 3.284351845218282e+05 4.405203916995400e+06 34 .05
#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh -119.0034 39.7795 34 .05 # northwest split
#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh -119.0034 39.78525 34 .05 # northwest split
#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh -119.00972222 39.76644444 34 .05 #upper southeastern okada
#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh -119.00972222 39.76244444 34 .05 #lower southeastern okada
#lat0=39.78525 # lower SE okada
#lon0=-119.0034 # lower SE okada
#lat0=39.795 # in between okadas
#lon0=-119.0034 # in between okadas
#lat0=39.8025 # NW okada
#lon0=-119.001 # NW okada
lat0=${lat[index]}
lon0=${lon[index]}

#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh ${lon0} ${lat0} 34 .05
tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh ${lon0} ${lat0} 94.528824236000005 .05

sort profile.rsp | uniq -u

# plot profile
#tcsh -f ~ebaluyut/bin_htcondor/plot_grd_ll_e.csh $pha1 $quantity $type $a
tcsh -f ~ebaluyut/bin_htcondor/plot_grd_e_BradyInSARRCF.csh $pha1 $quantity $type $a $sat $track $site

# crop and move plots
ps2pdf_crop.sh ${a}.ps
mv ${a}.pdf ../../Profiles/${a}_`echo $pha1| awk -F\. '{print $1}'`-${lon0}_${lat0}.pdf
mv ${a}.ps ../../Profiles/${a}_`echo $pha1| awk -F\. '{print $1}'`-${lon0}_${lat0}.ps

done
cd ..
done < InList

# clean up
rm InList GrdList *.rsp

cd ..
