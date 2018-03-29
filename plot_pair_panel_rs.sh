#!/bin/bash
# script for plotting 1 pair with footer information for right side plots in a panel
# Elena C Reinisch 20170520
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180327 update for new gmtsar-aux layout
# update ECR 20180327 update for new get_site_dims.sh

if [[ $# -eq 0 ]]
then
echo "script for plotting 1 pair with footer information"
echo "plot_pair.sh [sat] [track] [site] [pair_name] [grdfile] [outfile] [mmperfringe] [baseline] [user] [filter_wv] [time span] [DEM file name with path]"
echo "pair_name is used as title for plot"
echo "mmperfringe is used as colorbar label when plotting unwrapped range change"
echo "arguments  [baseline] [user] [filter_wv] [time span] [DEM file name with path] are used for comments only"


exit 1
fi

sat1=$1
trk1=$2
site=$3
pair1=$4
pha1=$5
outfile=$6
mmperfringe=$7
bas1=$8
user=$9
filter_wv=${10}
dt=${11}
demf=${12}
cdir=`pwd`

# get appropriate well files
cp ~ebaluyut/gmtsar-aux/${site}/* .

# set gmt environment varibles
#gmtset PS_MEDIA = letter
#gmtset FORMAT_FLOAT_OUT = %.12lg
#gmtset MAP_FRAME_TYPE = plain
#gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
#gmtset FONT_ANNOT_PRIMARY = 8p
#gmtset FONT_LABEL = 8p
#gmtset FORMAT_GEO_MAP  = D 
#gmtset FONT_TITLE = 9p

gmtset PS_MEDIA = letter
gmtset FORMAT_FLOAT_OUT = %.12lg
gmtset MAP_FRAME_TYPE = plain
gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
gmtset FONT_ANNOT_PRIMARY = 12p
gmtset FONT_LABEL = 12p
gmtset FORMAT_GEO_MAP  = D
gmtset FONT_TITLE = 14p
gmtset MAP_LABEL_OFFSET = 5p
gmtset MAP_TITLE_OFFSET = 3p
gmtset FORMAT_FLOAT_OUT = %3.2f

# define region for cutting/plotting
if [[ `grdinfo $pha1 | grep UTM | wc -l` -gt 0 || $pha1 == *"utm"* ]]
then
    region=`get_site_dims.sh ${site} 2`
    isutm=1
else
    region=`get_site_dims.sh ${site} 1`
    isutm=0
fi
echo $region

# get dx and dy for plot tick marks
dlon=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($2 - $1)**2)**(1/2))/2)}' | awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
dlat=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($4 - $3)**2)**(1/2))/2 )}'| awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
echo $dlat
echo $dlon

# define region in km if UTM
if [[ $isutm == 1 ]]
then
  region_km=`get_site_dims.sh $site 2 | awk -FR '{print $2}' | awk -F/ '{printf("-R%6.6f/%6.6f/%6.6f/%6.6f", $1/1e3, $2/1e3, $3/1e3, $4/1e3)}'`
  dlat_km=`echo $dlat | awk '{print $1/1e3}'`
  dlon_km=`echo $dlon | awk '{print $1/1e3}'`
fi

if [[ "$pha1" == *"phase"* ]]
then
  if [[ `grdinfo $pha1 | grep radians | wc -l` -gt 0 ]]
  then
    makecpt -T-3.14159226418/3.14159226418/.1 -D > cpt.cpt # wrapped phase plot
  else
    makecpt -T-0.5/0.5/.01 -D > cpt.cpt
  fi
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage $pha1 -Y7 -C${cdir}/cpt.cpt -JX7/12 $region -P -K -Bwsne > ${outfile}
  else # if UTM plot file without labeling anything
   grdimage $pha1 -Y7 -C${cdir}/cpt.cpt -JX7/12 $region -P -K > ${outfile}
  fi
  makecpt -T-0.5/0.5/.01 > cpt2.cpt
  psscale -C${cdir}/cpt2.cpt -D3.5/-1/6/0.1h -Baf1+l"Phase (cycles, $mmperfringe mm/cycle)" -O -K  >> ${outfile}
  rm cpt.cpt cpt2.cpt
# if file is unwrapped radians
elif [[ "$pha1" == *"unwrap"*  ]]
then
  grdmath $pha1 ISFINITE $pha1 MUL PI DIV 2.0 DIV $mmperfringe  MUL = r2mm.grd
  makecpt -T-25/25/0.25 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt -JX7/10 $region -P  -Bwsne -O -K > ${outfile}
  else
    grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt -JX7/10 $region -P  -O -K > ${outfile}
  fi
  psscale -C${cdir}/unwrap.cpt -D3.5/-1/6/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd
# if file is unwrapped m
elif [[ "$pha1" == *"drho"* || "$pha1" == *"range"* ]]
then
  grdmath $pha1 1000 MUL = r2mm.grd
  makecpt -T-15/15/0.1 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage r2mm.grd -X7.5 -C./cpt.cpt -JX7/12 $region -P -Bwsne -K > ${outfile}
  else
    grdimage r2mm.grd -X7.5 -C./cpt.cpt -JX7/12 $region -P -K > ${outfile}
  fi
  psscale -C./cpt.cpt -D3.5/-1/6/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd
elif [[ "$pha1" == *"volume_change"* ]]
then
  zmin=`grdinfo -C -L2 $pha1 | awk '{print $12 - 3*$13}'`
  zmax=`grdinfo -C -L2 $pha1 | awk '{print $13 + 2*$13}'`
  #zmax=`grdinfo -C -L2 $pha1 | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
  makecpt -T${zmin}/${zmax}/${dz} -Cpolar -D  > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage $pha1 -X7.5 -C./cpt.cpt -JX7/12 $region -P -Bwsne -K > ${outfile}
  else
    grdimage $pha1 -X7.5 -C./cpt.cpt -JX7/12 $region -P -K > ${outfile}
  fi
  psscale -C./cpt.cpt -D3.5/-1/6/0.1h -Baf1+l"Volume change (m^3)" -O -K  >> ${outfile}
  rm cpt.cpt
else
  cptname=`echo $pha1 | awk -Famp '{print $1"amp.cpt"}'`
  echo $cptname
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage $pha1 -Y7 -C${cdir}/${cptname} -JX10/10 $region -P -K -Bwsne > ${outfile}
  else
    grdimage $pha1 -Y7 -C${cdir}/${cptname} -JX10/10 $region -P -K > ${outfile}
  fi
  psscale -C${cdir}/${cptname} -D5/-1/9/0.1h -Baf1+l"data" -O -K  >> ${outfile}
fi

# plot wells and Brady Box
if [[ $isutm == 0 ]] # use deg format files
then
  if [[ -e ${site}_box.txt ]]
  then
    cat ${site}_box.txt | awk '{print $1,$2}' | psxy $region -W1.5p -J -O -K -V -P >> ${outfile}
  fi
  if [[ "$site" == "brady" ]]
  then
    cat ${site}_prd.ll | awk '{print $1,$2}' | psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_inj.ll | awk '{print $1,$2}' | psxy $region -J -Si0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_stm.ll | awk '{print $1,$2}' | psxy $region -J -Ss0.25 -Gblack -O -K -V -P >> ${outfile}
    rm ${site}_prd.ll ${site}_inj.ll  ${site}_stm.ll ${site}_box.txt
  fi
else # use UTM format files
  if [[ -e ${site}_box_utm.txt ]]
  then
    cat ${site}_box_utm.txt | awk '{print $1,$2}' | psxy $region -W1.5p -J -O -K -V -P >> ${outfile}
  fi
  if [[ "$site" == "brady" ]]
  then
    cat ${site}_prd.utm | awk '{print $1,$2}' | psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_inj.utm | awk '{print $1,$2}' | psxy $region -J -Si0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_stm.utm | awk '{print $1,$2}' | psxy $region -J -Ss0.25 -Gblack -O -K -V -P >> ${outfile}
  fi
fi
# exit
## END HERE FOR RIGHT SIDE PLOTS
## add scale bar for 1 km to wrapped phase plot for deg plots
#if [[ $isutm == 0 ]]
#then
#  scalex=`echo "$region" | awk -F/ '{x = $2 -0.005; print x}'`
#  scaley=`echo "$region" | awk -F/ '{x = $3 + .005; print x}'`
#  pscoast -JX50d/10d -R -N1 -L${scalex}/${scaley}/${scaley}/1 -O -K >> ${outfile}
#  pscoast -JX50d/10d -R -I0 -I1 -I2 -N1 -N2 -O -K >> ${outfile}
#fi
#
## define bounds and add footer
#dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/10/1.6)}'`
#ymin=`echo "$region" | awk -F/ '{print $3}'`
#textstart=`echo ${dtext} | awk '{print ($1*7)}'`
#
#if [[ $isutm == 1 ]]
#then
#x1=325000 # `echo "$region" | awk -F/ '{print $1}'  | awk -FR '{print $2}'` # '{x = $2 - 0.005; print x}'`
#y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
#x2=`echo $region | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
#y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3 )}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
#y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
#y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
#y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
#y1=`expr $ymin - 600`
#y2=`expr $ymin - 800`
#y3=`expr $ymin - 1000`
#y4=`expr $ymin - 1200`
#y5=`expr $ymin - 1400`
#else
#x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
#y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
#x2=`echo $region | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
#y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
#y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
#y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
#y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
#fi
#
#echo $x1
#echo $y1
#echo $y2
#echo $y3
#echo $y4
#echo $y5
#
## add footer info
##pstext -Xf2 -R -F+jBL -J -N -O -K << EOF >> ${outfile}
#pstext -R -F+jBL -J -N -O -K << EOF >> ${outfile}
#$x1 $y1  `echo "$sat1 $trk1 $pair"`
#$x1 $y2  `echo "Bperp [m]: $bas1"`
#$x1 $y3  `echo "time span [days]: $dt"`
#EOF

# add title info
pstext  -R -F+f18p,Helvetica-Bold+cTL -Gwhite -J -N -O -K << EOF >> ${outfile}
$pair1
EOF

# if in UTM also add plot with km axis overlay
if [[ $isutm == 1 ]]
then
# -Bx${dlon_km}+u"km" -By${dlat_km}+u"km"
  psbasemap -JX7/12 $region_km -Bx${dlon_km}+u"km" -Bwsne -P -K -O >> ${outfile}
fi

echo $pair1
