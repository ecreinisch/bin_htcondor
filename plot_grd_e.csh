#!/bin/csh -fvex
# Created by Elena C Reinisch based on script from Kurt Feigl 20150807
# Elena C Reinisch 20170518 plot grd file from any coordinate system
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180327 update for new gmtsar-aux layout
# update ECR 20180327 update for new get_site_dims.sh
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

# set variables
set in = $1
set quantity = $2
set type = $3
set pair = $4 
set out = ${pair}.ps
set sat = $5
set trk = $6
set site = $7
echo SAT = $sat
# get mmperfringe
if ( $sat == "TSX" ) then
  set mmperfringe = 15.5
else if ( $sat == "S1A" ) then
  set mmperfringe = 27.7
else 
  echo "mmperfringe not yet defined for this satellite. Update script before continuing."
  exit 1
endif

# get any text files with plot extras
cp ~ebaluyut/gmtsar-aux/${site}/* .

# determine if UTM or not
if ( `grdinfo $in | grep UTM | wc -l` > 0  || $in == *"utm"* ) then
   set ranges = `get_site_dims.sh $site 2`
   set uzone = `get_site_dims.sh $site 3`
   set isutm = 1
else
   set ranges = `get_site_dims.sh $site 1`
   set isutm = 0
endif

# set plotting scheme for UTM.  Determine scaling ratio between X and Y and plot larger axis with size 10
  set dx = `get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{print $2 - $1}'`
  set dy = `get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{print $4 - $3}'`
  if ( $dy >= $dx ) then
    set pratio = `get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{printf("%1d\n", ($2-$1)/($4-$3)*10)}'`
    set jflag = "-JX${pratio}/10"
  else
    set pratio = `get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{printf("%1d\n", ($4-$3)/($2-$1)*10)}'`
    set jflag = "-JX10/${pratio}"
  endif
set lengthx = `echo $jflag | awk -F/ '{print $1}' | awk -FX '{print $2}'`
set lengthy = `echo $jflag | awk -F/ '{print $2}'`
if ( $isutm == 0 ) then
    set jflag = "-JM${lengthx}"
endif
echo JFLAG = $jflag

# get dx and dy for plot tick marks
set dlon = `echo $ranges | awk -FR '{print $2}' | awk -F/ '{print ( ((($2 - $1)**2)**(1/2))/2)}' | awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
set dlat = `echo $ranges | awk -FR '{print $2}' | awk -F/ '{print ( ((($4 - $3)**2)**(1/2))/2 )}'| awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
echo dlon = $dlon
exho dlat = $dlat

# define region in km if UTM
if ( $isutm == 1 ) then
  set region_km = `get_site_dims.sh $site 2 | awk -FR '{print $2}' | awk -F/ '{printf("-R%6.6f/%6.6f/%6.6f/%6.6f", $1/1e3, $2/1e3, $3/1e3, $4/1e3)}'`
  set dlat_km = `echo $dlat | awk '{print $1/1e3}'`
  set dlon_km = `echo $dlon | awk '{print $1/1e3}'`
endif

# use SI units
gmt set -Ds

# set label
set mypwd = `pwd`
gmt grdinfo -L2 $in | tee tmp.info

# find units (dimensions)
set units=`gmt grdinfo $in | grep z_min | awk '{print $7,$8,$9,$10,$11}' `
#set units =`echo "cycles, ${mmperfringe}/cycle"`
echo "units is $units"

# make color table - should be continuous
gmt grd2cpt $in -Cjet -E256 >! tmp.cpt

# plot the grid as an image with nearest neighbor interpolation
#set utmin=`echo ${in} | sed 's/ll/utm/g'`
if ( $isutm == 0 ) then
  gmt grdimage ${in} -nn ${ranges} ${jflag} -P -BWesN+t"${sat} ${trk} ${pair}" -Bx${dlon} -By${dlat} -Ctmp.cpt -Y10 -K  --FONT_TITLE=14p,Helvetica,black > ${out}
  gmt psxy coord.rsp ${ranges} -J -P  -K -O  -Wthinner >> $out # draw lines 
else
  #gmt grdimage ${in} -JX7/10 -P -BWesN+t"${sat} ${trk} ${pair}" -Ba -Ctmp.cpt  -K -Y7 --FONT_TITLE=14p,Helvetica,black > ${out}
  #gmt grdimage ${in} -nn ${ranges} ${jflag} -P -BWesN+t"${sat} ${trk} ${pair}" -Bx${dlon}+u"m" -By${dlat}+u"m" -Ctmp.cpt  -K -Y10 --FONT_TITLE=14p,Helvetica,black > ${out}
  gmt grdimage ${in} -nn ${ranges} ${jflag} -P  -Ctmp.cpt  -K -Y10 --FONT_TITLE=14p,Helvetica,black > ${out}
  gmt mapproject coord.rsp -Ju+${uzone}/1:1 -C -F > coord_utm.rsp # project coord.rsp into UTM
  psbasemap $jflag $region_km -Bx${dlon_km}+u"km" -By${dlat_km}+u"km" -BWsNe+t"${sat} ${trk} ${pair}" -P -K -O >> ${out}
  gmt psxy coord_utm.rsp ${ranges} ${jflag} -P -K -O  -Wthinner >> $out  # draw lines
endif



# plot boxes and wells if files exist
#gmt psxy ../bradys_latlon -R -JM10 -P  -K -O  -Wthick >> $out 
#gmt psxy ~ebaluyut/bin_htcondor/bradys_utm ${ranges} ${jflag} -P  -K -O  -Wthick >> $out 
if ( $isutm == 0 ) then # use deg format files
  if ( -e ${site}_box.txt ) then
    cat ${site}_box.txt | awk '{print $1,$2}' | psxy ${ranges} -W1.5p -J -O -K -V -P >> ${out}
  endif
  if ( "$site" == "brady" ) then
    cat ~ebaluyut/gmtsar-aux/${site}/${site}_fumaroles_ll.txt | awk '{print $1,$2}' | psxy ${ranges}  -J -Sd0.25 -W.75 -O -K -V -P >> ${out}
    cat ${site}_prd.ll | awk '{print $1,$2}' | psxy ${ranges} -J -St0.25 -Gblack -O -K -V -P >> ${out}
    cat ${site}_inj.ll | awk '{print $1,$2}' | psxy ${ranges} -J -Si0.25 -Gblack -O -K -V -P >> ${out}
    cat ${site}_stm.ll | awk '{print $1,$2}' | psxy ${ranges} -J -Ss0.25 -Gblack -O -K -V -P >> ${out}
    cat ${site}_faults_ll.txt | awk '{print $1,$2}' | psxy ${ranges}  -J -W1  -O -K -V -P >> ${out}
   # cat ${site}_fumaroles_ll.txt | awk '{print $1,$2}' | psxy ${ranges}  -J -Sd0.25 -W.75 -O -K -V -P >> ${out}
    rm ${site}_prd.ll ${site}_inj.ll  ${site}_stm.ll ${site}_box.txt ${site}_faults_ll.txt #${site}_fumaroles_ll.txt 
  endif
else # use UTM format files
  if ( -e ${site}_box_utm.txt ) then
    cat ${site}_box_utm.txt | awk '{print $1,$2}' | psxy ${ranges} -W1.5p -J -O -K -V -P >> ${out}
  endif
  if ( "$site" == "brady" ) then
    cat ${site}_prd.utm | awk '{print $1,$2}' | psxy ${ranges} -J -St0.25 -Gblack -O -K -V -P >> ${out}
    cat ${site}_inj.utm | awk '{print $1,$2}' | psxy ${ranges} -J -Si0.25 -Gblack -O -K -V -P >> ${out}
    cat ${site}_stm.utm | awk '{print $1,$2}' | psxy ${ranges} -J -Ss0.25 -Gblack -O -K -V -P >> ${out}
    cat ${site}_faults_utm.txt | awk '{print $1,$2}' | psxy ${ranges} -J -W1 -O -K -V -P >> ${out}
    cat ${site}_fumaroles_utm.txt | awk '{print $1,$2}' | psxy ${ranges}  -J -Sd0.25 -W.75  -O -K -V -P >> ${out}
    rm ${site}_prd.utm ${site}_inj.utm  ${site}_stm.utm ${site}_box_utm.txt ${site}_faults_utm.txt ${site}_fumaroles_utm.txt
  endif
endif

# draw a distance scale if in lat/lon
if ( $isutm == 0 ) then
  # set midlat = 39.8
  set midlat = `gmt grdinfo $in -C | awk '{print ($4 + $5)/2.}'`
  gmt psbasemap -R -J -Lxf`echo $lengthx | awk '{print ($1 + 1.5)}'`/-2/$midlat/1k+l"km" -P -O -K >> $out
endif

# draw the color bar -E for equal
#gmt psscale -Ctmp.cpt --FORMAT_FLOAT_MAP=%.2g -D12/7/10/1 -E+nmissing -Bxaf -Byaf+l"$units" -O -K >> $out
gmt psscale -Ctmp.cpt --FORMAT_FLOAT_MAP=%.2g -D`echo $lengthx | awk '{print ($1 + 1)}'`/6/7/1 -E+nmissing -Bxaf -Byaf+l"$units" -O -K >> $out

# plot profile points
if (-e profile.rsp) then
   if ( $isutm == 0 ) then
     cat profile.rsp | awk 'NR % 10 == 0{print $0}' | gmt psxy -Sp -Gwhite -R ${jflag} -P -O -K -V >> $out
     # extract points using nearest neighbor interpolation
     gmt grdtrack profile.rsp -sa -G$in -nn | awk '{print $3,$4}' >! tmp.pg
     gmt psxy tmp.pg -Sp -Gred -JX${lengthx}/3 -P `gmt info tmp.pg -I-` -Y-4 -O -K \
     -BWS+t"$quantity" -Bxaf+l"Cross strike coordinate w.r.t. maximum [km]" -Byaf+l"$units" \
     --FONT_TITLE=14p,Helvetica,black >> $out
   else
     gmt mapproject profile.rsp -Ju+${uzone}/1:1 -C -F > profile_utm.rsp
     cat profile_utm.rsp | awk 'NR % 10 == 0{print $0}' | gmt psxy -Sp -Gwhite -R ${jflag} -P -O -K -V >> $out
     # extract points using nearest neighbor interpolation
     gmt grdtrack profile_utm.rsp -sa -G$in -nn | awk '{print $3,$4}' >! tmp.pg
     gmt psxy tmp.pg -Sp -Gred -JX${lengthx}/3 -P `gmt info tmp.pg -I-` -Y-4 -O -K \
     -BWS+t"$quantity" -Bxaf+l"Cross strike coordinate w.r.t. maximum [km]" -Byaf+l"$units" \
     --FONT_TITLE=14p,Helvetica,black >> $out
    endif
else
  echo "cannot find profile.rsp. Consider running make_profile.csh"
endif

#if ( $isutm == 1 ) then
#  psbasemap $jflag $region_km -Bx${dlon_km}+u"km" -By${dlat_km}+u"km" -BWsNe+t"${sat} ${trk} ${pair}" -P -K -O >> ${out}
#endif

exit

if (-e profile_utm.rsp) then
 # extract points using nearest neighbor interpolation
  gmt grdtrack profile_utm.rsp -sa -G$in -nn | awk '{print $3,$4}' >! tmp.pg

  # make a profile
  #gmt psxy tmp.pg -Sp -Gred -JX13/4 -P `gmt info tmp.pg -I-` -Y-6.5 -O -K \
  gmt psxy tmp.pg -Sp -Gred -JX7/3 -P `gmt info tmp.pg -I-` -Y-4 -O -K \
  -BWS+t"$quantity" -Bxaf+l"Cross strike coordinate w.r.t. maximum [km]" -Byaf+l"$units" \
  --FONT_TITLE=14p,Helvetica,black >> $out
#pstext -R -F+jBC -JX13/4 -N -O -K << EOF >> $out
#  `echo "test"`
#EOF
#echo "test" | gmt pstext -R1/13/1/4 -JX13/4  -F+cTL -O -M -N -K >> $out
#gmt pstext -R -J -F+f12p+jL -O -N -K << EOF >> $out
#-10 -6.5 `echo ${mypwd}/${pair}`
#EOF
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





