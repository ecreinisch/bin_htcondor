#!/bin/bash
# given txt file with 2 columns of grd files, find residuals and plot in histogram
# Elena C Reinisch 20170318
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180321 update so that scripts are referenced from user defined ${bin_htcondor_home}

dir1=$1
dir2=$2
ifile=$3
iname=$(echo $ifile | awk -F. '{print $1}')

#ls -d $dir1/intf/In* | awk -F/ '{print $(NF)}' > pairs.tmp
cat $dir1/intf/PAIRSmake_check.txt | awk '$20 == 1 {print ;}' > tmp.lst
sat=`cat tmp.lst | tail -1 | awk '{print $17}'`
trk=`cat tmp.lst | tail -1 | awk '{print $9}'`
site=`cat tmp.lst | tail -1 | awk '{print $12}'`
user=`cat tmp.lst | tail -1 | awk '{print $28}'`
demf2=`cat $dir2/intf/PAIRSmake_check.txt | tail -1 |  awk '{print $18}'`

while read -r line; do
   # find baseline information for each pair, truncate to whole number
   echo $line
   bperp=`echo $line | awk '{print $15}'`
   pair=`echo $line | awk '{printf("In%8d_%8d\n",$1, $2)}'`
   unw=`echo $line | awk '{print $21}'`
   filter_wv=`echo $line | awk '{print $19}'`
   #dt=`echo $line | awk '{print $8 - $7}'`
   mast=`echo $line | awk '{printf("%s-%s-%s\n", substr($1, 1, 4), substr($1, 5, 2), substr($1, 7, 2))}'`
   slav=`echo $line | awk '{printf("%s-%s-%s\n", substr($2, 1, 4), substr($2, 5, 2), substr($2, 7, 2))}'`
   dt=`echo $(( ( $(date -ud $slav +'%s') - $(date -ud $mast +'%s') )/60/60/24 ))` 
   demf1=`echo $line | awk '{print $18}'`
   mmperfringe=`echo $line | awk '{printf("%2.1f\n", $13 /2 * 1000)}'`

# set gmt environment varibles
gmtset PS_MEDIA = letter
gmtset FORMAT_FLOAT_OUT = %.12lg
gmtset MAP_FRAME_TYPE = plain
gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
gmtset FONT_ANNOT_PRIMARY = 10p
gmtset FONT_LABEL = 10p
gmtset FORMAT_GEO_MAP  = D 
gmtset FONT_TITLE = 12p
gmtset MAP_LABEL_OFFSET = 3p
gmtset MAP_TITLE_OFFSET = 3p
gmtset FORMAT_FLOAT_OUT = %3.2f

   
   grdmath $dir1/intf/${pair}/$ifile $dir2/intf/${pair}/$ifile SUB = res_${pair}-${iname}.grd
grd2xyz res_${pair}-${iname}.grd -Z > res_${pair}-${iname}.txt
gmt pshistogram res_${pair}-${iname}.txt -Jx.8/.002 -F -L0.5 -W0.2 -BWSne+t"Histogram of Differenced ${iname} values: ${pair}" -Bx+L"(${iname}_1) - (${iname}_2)" -By+L"N" -Ya5 -K -P > hist_res_${pair}-${iname}.ps
    
#region=
#x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
#y1=`echo "$region" | awk -F/ '{x = $3 - 0.008; print x}'`
#x2=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.000; print x}'`
#y2=`echo "$region" | awk -F/ '{x = $3 - 0.009; print x}'`
#y3=`echo "$region" | awk -F/ '{x = $3 - 0.01; print x}'`
#y4=`echo "$region" | awk -F/ '{x = $3 - 0.011; print x}'`
#y5=`echo "$region" | awk -F/ '{x = $3 - 0.012; print x}'`
x1=1
y1=1500
x2=2
y2=1250
x3=3
y3=1000
x4=4
y4=750
x5=5
y5=500
echo $x1
echo $y1
echo $x2
echo $y2
echo $user
echo $cdir 
echo $pair1
#$x2 $y2 `echo "$user $cdir/$pair1"`
#pstext -Xf2 -R0/10/0/10 -F+jBL -J -N -O -K << EOF >> hist_res_${pair}-${iname}.ps
pstext -R -F+jBL -J -N -O -K << EOF >> hist_res_${pair}-${iname}.ps
$x1 $y1  `echo "Bperp [m]: $bperp"`
$x1 $y2  `echo "time span [days]: $dt"`
$x1 $y3  `echo "filter wavelength [m]: $filter_wv"` 
$x1 $y4  `echo "DEM for ${iname}_1: $demf1"`
$x1 $y5  `echo "DEM for ${iname}_2: $demf2"`
EOF


   ${bin_htcondor_home}/ps2pdf_crop.sh  hist_res_${pair}-${iname}.ps
  # mv ${pair}_phafilt_unw.ps ../Plots
  # mv ${pair}_phafilt_unw.pdf ../Plots
   
done < tmp.lst

