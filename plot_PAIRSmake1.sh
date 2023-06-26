#!/bin/bash -vx
# plot wrapped phase or unwrapped range for each pair
# to be run in subdirectory intf 
# ./new_plot_brady.sh TSX T53
# edit ECR 20180319 save plot to intf/[pair] directory
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180418 also save copy of pdf plot to Plots dir
# update ECR 20180511 don't add full paths to scripts since already on path
# update KLF 20190724 find wells
# 20200128 look harder for PAIRSmake.txt file
# 20210708 update KLF adapt to GMT v. 6 by calling plot_pair6.sh
# update KLF 20211108 do NOT delete 


if [[ $# -eq 0 ]]; then
   echo "plots specified form of grd files of pairs in PAIRSmake.txt"
   echo "run in intf directory"
   echo "ARGS: PAIRSmake_file, phase_prefix1"
   echo "E.g.: plot_PAIRSmake.sh PAIRSmake_check.txt phase_ll"
   exit 1
fi

# find all successful pairs
if [[ -e $1 ]]; then
   #cat $1 | awk '$20 == 1 {print ;}' > tmp.lst
   # take all pairs
   cat $1 | awk 'NF > 18 {print ;}' > tmp.lst
else
   # 20200128
   # find list of PAIRSmake files
   pms=`find .. -name "PAIRSmake*"`
   # find most recent PAIRSmake file
   pm1=`\ls -lt $pms | head -1 | awk '{print $9}'`
   cat $pms | awk '$20 == 1 {print ;}' > tmp.lst
fi 

# second argument is type of grid file to plot
pha1=$2
#pha2=$3

sat=`cat tmp.lst | tail -1 | awk '{print $17}'`
trk=`cat tmp.lst | tail -1 | awk '{print $9}'`
site=`cat tmp.lst | tail -1 | awk '{print $12}'`
user=`cat tmp.lst | tail -1 | awk '{print $(NF)}'`

# make directory if not already there to store plots to
#mkdir -p ../Plots

while read -r line; do
   # find baseline information for each pair, truncate to whole number
   echo $line
   bperp=`echo $line | awk '{print $15}'`
   pair=`echo $line | awk '{printf("In%8d_%8d\n",$1, $2)}'`
   unw=`echo $line | awk '{print $21}'`
   if [[ $pha1 == *"phasefilt"* ]]; then
      filter_wv=`echo $line | awk '{print $19}'`
   else
      filter_wv="NaN"
   fi
   ref=`echo $line | awk '{printf("%s-%s-%s\n", substr($1, 1, 4), substr($1, 5, 2), substr($1, 7, 2))}'`
   sec=`echo $line | awk '{printf("%s-%s-%s\n", substr($2, 1, 4), substr($2, 5, 2), substr($2, 7, 2))}'`
   dt=`echo $(( ( $(date -ud $sec +'%s') - $(date -ud $ref +'%s') )/60/60/24 ))` 
   demf=`echo $line | awk '{print $18}'`
   echo $demf

    # run plotting scripts
   if [[ -e ${pair}/${pha1}.grd ]]; then
      cd ${pair}
      mmperfringe=`echo $line | awk '{printf("%2.1f\n", $13 /2 * 1000)}'`
      # echo "plot_pair.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf"
      # plot_pair.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf"
      #plot_pair6.sh  TSX T30 forge "title" phasefilt_mask_utm.grd phase_filt_mask.ps 15.5 63.2 $USER 80 999 In20181115_20190418
      echo "plot_pair6.sh $sat $trk $site $pair $pair/${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf"
      plot_pair6.sh $sat $trk $site $pair ${pha1}.grd ${pair}_${pha1}.ps $mmperfringe $bperp $user $filter_wv $dt $demf
      ps2pdf_crop.sh  ${pair}_${pha1}.ps
      #cp ${pair}_${pha1}.pdf ../Plots/
      #mv ${pair}_${pha1}.ps ${pair}/
      #mv ${pair}_${pha1}.pdf ${pair}/
      cd ..
   else
      echo ERROR missing $pair/${pha1}.grd
   fi
done < tmp.lst

# clean up
#\rm -fv tmp.lst ${site}*.txt gmt.conf  gmt.history

