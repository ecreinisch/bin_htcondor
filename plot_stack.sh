#!/bin/bash
# script to plot stack of grd files
# Elena C Reinisch 20180329

if [[ $# -eq 0 ]]; then
  echo "script to plot stack of grd files"
  echo "run in directory intf directory"
  echo "plot_stack.sh [list of pair directories to include in stack] [name of grd file to stack] [sat] [trk] [site]"
  exit 1
fi

InList=$1
grdfile=$2
sat=$3
trk=$4
site=$5
demf=`grep $site ~ebaluyut/gmtsar-aux/site_dems.txt | awk '{print $2}'`
metersperfringe=`tail -1 PAIRSmake_check.txt | awk '{print $13/2}'`

# make sure $InList is in proper format
sed -i "s/\///g" $InList
sed -i "s/In//g" $InList
sed -i "s/_/ /g" $InList

# get list of files to stack
> grdlist.tmp
> stack_list.txt
while read -r a b; do
  filename=`find In${a}_${b}/ -name $grdfile`
  if [[ ! -z $filename  ]]; then 
    echo "$a $b $filename" >> stack_list.txt
  fi
done < $InList

# combine lists
#paste --delimiters=" " $InList grdlist.tmp > stack_list.txt

# in matlab
matlab -nodisplay << EOFE | tee stack.log
addpath ${bin_htcondor_home}
addpath(genpath('/usr1/ebaluyut/gipht'))
avg_rate_range_grds('stack_list.txt', ${metersperfringe})
EOFE



# Plot
if [[ $grdfile == *"unwrap"* ]]; then
 # if [[ $grdfile == *"ll.grd"* ]]; then
    grdproject avg_range_mperyr.grd -Ju+`get_site_dims.sh $site 3`/1:1 -C -F `get_site_dims.sh $site 1` -Gavg_range_mperyr_utm.grd
 # fi
  plot_pair.sh $sat $trk $site Stack avg_range_mperyr_utm.grd avg_range_mmperyr_utm.ps 15.5 nan ebaluyut 80 nan $demf
#else
#  plot_pair.sh $sat $trk $site Stack avg_range_radperyr_utm.grd avg_range_mmperyr_utm.ps 15.5 nan ebaluyut 80 nan $demf
fi
