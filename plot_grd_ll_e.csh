#!/bin/csh -fvex
#       $Id$
#
#  Kurt Feigl 20150807
#
# Plot an interferogram in lon, lat coordinates from a GMT grid file
# 
 if ($#argv == 0) then
    echo "Plot an interferogram in lon, lat coordinates from a GMT grid file"
    echo ""
    echo ""
    echo "Usage: $0:t phase_ll.grd ."
     echo ""
    echo ""
    echo ""
    exit 1
  endif
#echo "SET QUANTITY TO PROPER LABEL!!!"
set in = $1
echo in is $in
#set out = $in:r.ps
set pair = $4 #`echo $in | awk -F. '{print $1}'`
set out = ${pair}.ps
# use SI units
gmt set -Ds
set type = $3

# set label
set mypwd = `pwd`

gmt grdinfo -L2 $in | tee tmp.info

# find mm per cycle based on satellite
# find appropriate mm/cycle
#if [[ $sat == "TSX" ]]
#then
#    mmperfringe="15.5"
#elif [[ $sat == "SNT1A" ]]
#then
#    mmperfringe="27.7"
#else
#    mmperfringe=""
#fi
set mmperfringe = 15.5
set sat = TSX
set trk = T53

# find ranges
#set ranges = `gmt grdinfo $in -I-`
#echo "$ranges"
set ranges = -R-119.02/-118.99/39.78/39.82
echo $ranges 
echo $out
echo $in
echo $pair
# find mid latitude
#set midlat = `gmt grdinfo $in -C | awk '{print ($4 + $5)/2.}'`
set midlat = 39.8
#echo midlat is $midlat

# find observable quantity 
#set quantity = `gmt grdinfo $in | grep Title | awk '{print $3,$4,$5,$6,$7,$8,$9,$10}' `
set quantity = $2
echo quantity is $quantity

# find units (dimensions)
set units=`gmt grdinfo $in | grep z_min | awk '{print $7,$8,$9,$10,$11}' `
#set units =`echo "cycles, ${mmperfringe}/cycle"`
echo "units is $units"

# make color table - should be continuous

#gmt grd2cpt $in -Cjet  -T= >! tmp.cpt     # symmetric about zero
gmt grd2cpt $in -Cjet -E256 >! tmp.cpt

# plot the grid as an image with nearest neighbor interpolation
gmt grdimage ${in} -nn ${ranges} -JM10 -P -BWesN+t"${sat} ${trk} ${pair}" -Ba -Ctmp.cpt -Y10 -K  --FONT_TITLE=14p,Helvetica,black > ${out}

 # draw lines
gmt psxy coord.rsp -R -JM10 -P  -K -O  -Wthinner >> $out  
gmt psxy ../bradys_latlon -R -JM10 -P  -K -O  -Wthick >> $out 
# draw a distance scale
gmt psbasemap -R -J -Lxf1/-1/$midlat/1k+l"km" -P -O -K >> $out

# plot profile points
if (-e profile.rsp) then
   #gmt psxy profile.rsp -Sp -Gwhite -R -JM10 -P -O -K -V >> $out
   cat profile.rsp | awk 'NR % 10 == 0{print $0}' | gmt psxy -Sp -Gwhite -R -JM10 -P -O -K -V >> $out
endif

# draw a distance scale
#gmt psbasemap -R -J -Lxf1/1/$midlat/10k+l"km" -P -O -K >> $out

# draw the color bar -E for equal
gmt psscale -Ctmp.cpt --FORMAT_FLOAT_MAP=%.2g -D12/7/10/1 -E+nmissing -Bxaf -Byaf+l"$units" -O -K >> $out

if (-e profile.rsp) then
 # # extract points using nearest neighbor interpolation
 # gmt grdtrack profile.rsp -sa -G$in -nn | awk '{print $3,$4}' >! tmp.pg

 # # make a profile
 # gmt psxy tmp.pg -Sp -Gred -JX15/5 -P `gmt info tmp.pg -I-` -Y-7 -O -K \
 # -BWS+t"$quantity" -Bxaf+l"Cross strike coordinate w.r.t. maximum [km]" -Byaf+l"$units" \
 # --FONT_TITLE=14p,Helvetica,black >> $out

 # extract points using nearest neighbor interpolation
  gmt grdtrack profile.rsp -sa -G$in -nn | awk '{print $3,$4}' >! tmp.pg



  # make a profile
  gmt psxy tmp.pg -Sp -Gred -JX13/4 -P `gmt info tmp.pg -I-` -Y-6.5 -O -K \
  -BWS+t"$quantity" -Bxaf+l"Cross strike coordinate w.r.t. maximum [km]" -Byaf+l"$units" \
  --FONT_TITLE=14p,Helvetica,black >> $out
#pstext -R -F+jBC -JX13/4 -N -O -K << EOF >> $out
#  `echo "test"`
#EOF
#echo "test" | gmt pstext -R1/13/1/4 -JX13/4  -F+cTL -O -M -N -K >> $out
gmt pstext -R -J -F+f12p+jL -O -N -K << EOF >> $out

-10 -6.5 `echo ${mypwd}/${pair}`
EOF
else
  echo "cannot find profile.rsp. Consider running make_profile.csh"
endif

echo "SET QUANTITY TO PROPER LABEL!!!"
exit
# write some text
cat tmp.info | awk '{$1="";print 0, NR, $0}' >! tmp.txt
gmt pstext tmp.txt -F+jBL+f9p,Courier,black -JX18/-12 -R0/15/0/40 -P -O -K -X-2 -Y-14 -V >> $out

# must be last line
gmt psxy /dev/null  -J -R -P -O -UBL/0/-3/$mypwd >> $out

#if ($#argv == 2) then
#  gs $out 
#endif





