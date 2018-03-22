#!/bin/bash
# plots comparisons of wrapped phase and unwrapped range for each pair
# to be run in subdirectory intf 
# Elena C Reinisch 20170520
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180321 update to use user defined ${bin_htcondor_home} for script paths

if [[ $# -eq 0 ]]
then
echo "plots specified form of grd files of pairs in PAIRSmake.txt"
echo "run in intf directory"
echo "ARGS: PAIRSmake_file, phase_prefix1"
echo "E.g.: plot_PAIRSmake.sh PAIRSmake_check.txt phase_ll"
exit 1
fi

# find all successful pairs
cat $1 | awk '$20 == 1 {print ;}' > tmp.lst
pha1=$2
pha2=$3
pha3=$4

sat=`cat tmp.lst | tail -1 | awk '{print $17}'`
trk=`cat tmp.lst | tail -1 | awk '{print $9}'`
site=`cat tmp.lst | tail -1 | awk '{print $12}'`
user=`cat tmp.lst | tail -1 | awk '{print $(NF)}'`

# make directory if not already there to store plots to
mkdir -p ../Plots

while read -r line; do
   # find baseline information for each pair, truncate to whole number
   echo $line
   bperp=`echo $line | awk '{print $15}'`
   pair=`echo $line | awk '{printf("In%8d_%8d\n",$1, $2)}'`
   unw=`echo $line | awk '{print $21}'`
   if [[ $pha1 == *"phasefilt"* ]]
   then
   filter_wv=`echo $line | awk '{print $19}'`
   else
   filter_wv=nan
   fi
   mast=`echo $line | awk '{printf("%s-%s-%s\n", substr($1, 1, 4), substr($1, 5, 2), substr($1, 7, 2))}'`
   slav=`echo $line | awk '{printf("%s-%s-%s\n", substr($2, 1, 4), substr($2, 5, 2), substr($2, 7, 2))}'`
   dt=`echo $(( ( $(date -ud $slav +'%s') - $(date -ud $mast +'%s') )/60/60/24 ))` 
   demf=`echo $line | awk '{print $18}'`
    
    # run plotting scripts
   count=1
   for pfile in $pha1 $pha2 $pha3; do
     if [[ -e $pair/${pfile}.grd ]]
     then
       mmperfringe=`echo $line | awk '{printf("%2.1f\n", $13 /2 * 1000)}'`
     echo COUNT = $count
     case $count in
 	1)
          ${bin_htcondor_home}/plot_pair_panel_ls.sh $sat $trk $site Observed $pair/${pfile}.grd ${pair}_${pfile}_${count}-tmp.ps $mmperfringe $bperp $user $filter_wv $dt $pair
          ;;
        2)
          ${bin_htcondor_home}/plot_pair_panel_cs.sh $sat $trk $site Modeled $pair/${pfile}.grd ${pair}_${pfile}_${count}-tmp.ps $mmperfringe $bperp $user $filter_wv $dt $demf
          ;;
        3)
          ${bin_htcondor_home}/plot_pair_panel_rs.sh $sat $trk $site Residual $pair/${pfile}.grd ${pair}_${pfile}_${count}-tmp.ps $mmperfringe $bperp $user $filter_wv $dt $demf
          ;;
#        4)
#          ${bin_htcondor_home}/plot_pair_panel_rs.sh $sat $trk $site Deviation $pair/${pfile}.grd ${pair}_${pfile}_${count}-tmp.ps $mmperfringe $bperp $user $filter_wv $dt $demf
#          ;;
        *)
          exit 1
          ;;
      esac  
       ${bin_htcondor_home}/ps2pdf_crop_short.sh  ${pair}_${pfile}_${count}-tmp.ps
       mv ${pair}_${pfile}_${count}-tmp.ps ../Plots
       mv ${pair}_${pfile}_${count}-tmp.pdf ../Plots
      count=`expr $count + 1`
     fi
   done
   
   # join images
   cd ../Plots
   #gs -q -dNOPAUSE -dBATCH -sDEVICE=pswrite -sOutputFile=merged.pdf ${pair}_${pha1}.pdf ${pair}_${pha2}.pdf ${pair}_${pha3}.pdf ${pair}_${pha4}.pdf
  # montage ${pair}_${pha1}.pdf ${pair}_${pha2}.pdf ${pair}_${pha3}.pdf ${pair}_${pha4}.pdf   -tile 4x1 -geometry 1000 ${pair}_4comp.pdf
  # montage ${pair}_${pha1}.ps ${pair}_${pha2}.ps ${pair}_${pha3}.ps ${pair}_${pha4}.ps   -tile 4x1 -geometry 1000 ${pair}_4comp.ps
  convert -density 300 ${pair}_${pha1}_1-tmp.pdf ${pair}_${pha2}_2-tmp.pdf ${pair}_${pha3}_3-tmp.pdf  +append tmp3.pdf 
  convert -density 300 tmp3.pdf -quality 100 ${pair}_3comp.pdf
  rm *tmp*.pdf
  #convert ${pair}_${pha1}.ps ${pair}_${pha2}.ps ${pair}_${pha3}.ps ${pair}_${pha4}.ps +append ${pair}_4comp.ps 
  #${bin_htcondor_home}/ps2pdf_crop.sh  ${pair}_4comp.ps

  # merge to one page
#  pdf2ps merged.pdf merged.ps
#  psnup -4 merged.ps > ${pair}_4comp.ps

  cd ../intf/

done < tmp.lst
rm tmp.lst
