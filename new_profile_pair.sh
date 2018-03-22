#!/bin/bash
# plots profiles of gmt plots; builds off of Kurt Feigl's make_profile.csh and plot_grd_ll.csh 
# Elena C Reinisch 20160825
# variables are phase file directory and value being plotted
# e.g. ./profile_pair2.sh PHA phase; ./profile_pair2.sh PHAFILT phase-filtered
# 20170531 ECR update to allow for UTM plots
# update ECR 20180319 update for new bin_htcondor repo

if [[ $# -eq 0 ]]
then
  echo "script for plotting profiles of pairs"
  echo "run in intf directory; plots returned in ../Profiles directory"
  #echo "args: new_profile_pair.sh [phase_grd_file (with .grd)] [quantity (e.g. phase, phase-filtered)] [sat] [track] [site] [ref pt lat] [ref pt lon] [strike CW from N] [step size; typical value 0.05]"
  echo "args: new_profile_pair.sh [phase_grd_file (with .grd)] [quantity (e.g. phase, phase-filtered)] [sat] [track] [site] [ref pt lat] [ref pt lon] [strike CW from N]"
  exit 1 
fi


# define variables 
pha1=$1
quantity=$2
sat=$3
track=$4
site=$5
lat=$6
lon=$7
strikecw=$8
#stepsize=$9

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
ls -d In*/ > InList

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

for index in 0 # 2 # 0 1 2
do
# get profile values with designated profile
lat0=${lat[index]}
lon0=${lon[index]}

#tcsh -f ~ebaluyut/bin_htcondor/make_profile_e.csh ${lon0} ${lat0} 34 .05
tcsh -f ${bin_htcondor_home}/make_profile_e.csh ${lon0} ${lat0} ${strikecw} .05

sort profile.rsp | uniq -u

# plot profile
tcsh -f ${bin_htcondor_home}/plot_grd_ll_e.csh $pha1 $quantity $type $a
#tcsh -f ~ebaluyut/bin_htcondor/plot_grd_e_BradyInSARRCF.csh $pha1 $quantity $type $a $sat $track $site

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
