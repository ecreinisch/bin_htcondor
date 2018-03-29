#!/bin/bash
# script for plotting histogram of 1 grd file with footer information
# Elena C Reinisch 20161004
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180327 update for new gmtsar-aux layout
# update ECR 20180327 update for new get_site_dims.sh

if [[ $# -eq 0 ]]
then
echo "script for plotting histogram of 1 grd file with footer information"
echo "currently works with lat/lon versions only"
echo "plot_hist.sh [sat] [track] [site] [pair_name] [grdfile] [data unit] [outfile] [user] [baseline] [filter_wv] [time span] [DEM file name with path]"
echo "pair_name is used as title for plot"
echo "arguments [user] [baseline] [filter_wv] [time span] [DEM file name with path] are used for comments only"
exit 1
fi

sat1=$1
trk1=$2
site=$3
pair1=$4
pha1=$5
pha_unit=$6
outfile=$7
user=$8
bas1=$9
filter_wv=${10}
dt=${11}
demf=${12}
cdir=`pwd`
echo $pair1
echo $pha1
echo $outfile

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
gmtset FONT_ANNOT_PRIMARY = 12p,Courier
gmtset FONT_LABEL = 12p
gmtset FORMAT_GEO_MAP  = D
gmtset FONT_TITLE = 14p
gmtset MAP_LABEL_OFFSET = 5p
gmtset MAP_TITLE_OFFSET = 3p
gmtset FORMAT_FLOAT_OUT = %3.2f

# define region for cutting/plotting
region=`get_site_dims.sh ${site} 1`
echo $region

# image wrapped phase first, adding title to figure
dlon=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($2 - $1)**2)**(1/2))/2)}' | awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
dlat=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($4 - $3)**2)**(1/2))/2 )}'| awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
echo $dlat
echo $dlon

# get size of data for histogram bin width
nbins=`grdinfo -C $pha1 | awk '{print ($7-$6)/sqrt($10*$11)}'`

#if [[ "$pha1" == *"phase"* ]]
#then
grd2xyz ${pha1} -Z > hist.txt
gmt pshistogram hist.txt -Y7 -JX10/10 -F -L0.5 -W$nbins -BWSne+t"Histogram of ${pha1} for ${pair1}" -Bx+L"${pha_unit}" -By+L"N" -K -P > ${outfile}
#rm hist.txt
#elif [[ "$pha1" == *"unwrap"* ]]
#then
#grd2xyz ${pha1} -Z > hist.txt
#gmt pshistogram hist.txt -JX10/10 -F -L0.5 -W$nbins -BWSne+t"Histogram of ${pha1} for ${pair} ${iname}" -Bx+L"range change" -By+L"N" -K -P > ${outfile}
#rm hist.txt
#else
#grd2xyz ${pha1} -Z > hist.txt
#gmt pshistogram hist.txt -JX10/10 -F -L0.5 -W$nbins -BWSne+t"Histogram of ${pha1} for ${pair} ${iname}" -Bx+L"units" -By+L"N" -K -P > ${outfile}
#rm hist.txt
#fi

# define bounds and add footer
dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/10/1.6)}'`
ymin=`echo "$region" | awk -F/ '{print ($3)}'`
textstart=`echo ${dtext} | awk '{print ($1*7)}'`
x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
x2=`echo $region | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`

pstext -Xf2 -R -F+jBL -J -N -O -K << EOF >> ${outfile}
$x1 $y1  `echo "Bperp [m]: $bas1"`
$x1 $y2  `echo "time span [days]: $dt"`
$x1 $y3  `echo "filter wavelength [m]: $filter_wv"`
$x1 $y4  `echo "$user: $cdir/$pair1"`
EOF

echo $pair1
