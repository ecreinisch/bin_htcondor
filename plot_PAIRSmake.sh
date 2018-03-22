#!/bin/bash
# plots comparisons of wrapped phase and unwrapped range for each pair
# to be run in subdirectory intf 
# edit ECR 20180319 save plots to int/[pair] directory
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180321 use user defined ${bin_htcondor_home} for script paths

if [[ $# -eq 0 ]]
then
echo "plots comparisons of two grd files side by side"
echo "run in intf directory"
echo "ARGS: PAIRSmake_file, phase_prefix1, phase_prefix2"
echo "E.g.: plot_PAIRSmake.sh PAIRSmake_check.txt phase_ll phasefilt_ll"
exit 1
fi

# find all successful pairs
cat $1 | awk '$20 == 1 {print ;}' > tmp.lst
pha1=$2
pha2=$3

sat=`cat tmp.lst | tail -1 | awk '{print $17}'`
trk=`cat tmp.lst | tail -1 | awk '{print $9}'`
site=`cat tmp.lst | tail -1 | awk '{print $12}'`
user=`cat tmp.lst | tail -1 | awk '{print $28}'`

## make directory if not already there to store plots to
#mkdir -p ../Plots

while read -r line; do
   # find baseline information for each pair, truncate to whole number
   echo $line
   bperp=`echo $line | awk '{print $15}'`
   pair=`echo $line | awk '{printf("In%8d_%8d\n",$1, $2)}'`
   unw=`echo $line | awk '{print $21}'`
   if [[ $pha1 == *"filt"* || $pha2 == *"filt"* ]]
   then
     filter_wv=`echo $line | awk '{print $19}'`
   else
     filter_wv=nan
   fi
   mast=`echo $line | awk '{printf("%s-%s-%s\n", substr($1, 1, 4), substr($1, 5, 2), substr($1, 7, 2))}'`
   slav=`echo $line | awk '{printf("%s-%s-%s\n", substr($2, 1, 4), substr($2, 5, 2), substr($2, 7, 2))}'`
   dt=`echo $(( ( $(date -ud $slav +'%s') - $(date -ud $mast +'%s') )/60/60/24 ))` 
   demf=`echo $line | awk '{print $18}'`
   echo $pair

    # run plotting scripts
   if [[ -e $pair/${pha1}.grd && -e $pair/${pha2}.grd ]]
   then
   mmperfringe=`echo $line | awk '{printf("%2.1f\n", $13 /2 * 1000)}'`
   ${bin_htcondor_home}/plot_pair_comp.sh $sat $trk $site $pair $pair/${pha1}.grd $pair/${pha2}.grd ${pair}_${pha1}_${pha2}.ps $mmperfringe $bperp $user $filter_wv $dt $demf
   ${bin_htcondor_home}/ps2pdf_crop.sh  ${pair}_${pha1}_${pha2}.ps
   mv ${pair}_${pha1}_${pha2}.ps ${pair}/
   mv ${pair}_${pha1}_${pha2}.pdf ${pair}/
   fi
done < tmp.lst
rm tmp.lst
