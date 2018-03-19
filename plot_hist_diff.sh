#!/bin/bash
# script for making clean gmt plots comparing phase from 2 different satellites
# THIS VERSION PLOTS IN CYCLES
# compares wrapped phase and unwrapped range
# Tabrez Ali
# Edits by Elena C Reinisch 20161004
# inputs SAT1 TRACK1 PAIR1_DATES phase.grd.file baseline_file_1 output.ps.file
# can be run iteratively using ~/SCRIPTS/run_plot_brady_comp.sh sat1 trk 1 sat2 trk2 pair_list_file
#
# requires the following text files: prd.ll, stm.ll, inj.ll, box.txt

if [[ $# -eq 0 ]]
then
echo "script for plotting histogram of differenced grd files with footer information"
echo "plot_hist_diff.sh [sat] [track] [site] [pair1_name] [grdfile1] [pair2_name] [grdfile2] [data unit] [outfile] [user] [baseline] [filter_wv] [time span] [DEM file name with path]"
echo "pair_name is used as title for plot"
echo "arguments [user] [baseline] [filter_wv] [time span] [DEM file name with path] are used for comments only"
exit 1
fi

sat1=$1
trk1=$2
site=$3
pair1=$4
pha1=$5
pair2=$6
pha2=$7
pha_unit=$8
outfile=$9
user=${10}
bas1=${11}
filter_wv=${12}
dt=${13}
demf=${14}
cdir=`pwd`

# set gmt environment varibles
gmtset PS_MEDIA = letter
gmtset FORMAT_FLOAT_OUT = %.12lg
gmtset MAP_FRAME_TYPE = plain
gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
gmtset FONT_ANNOT_PRIMARY = 12p,Courier
gmtset FONT_LABEL = 12p
gmtset FORMAT_GEO_MAP  = D
gmtset FONT_TITLE = 14p
gmtset MAP_LABEL_OFFSET = 5p
gmtset MAP_TITLE_OFFSET = 5p
gmtset FORMAT_FLOAT_OUT = %3.2f

# define region for cutting/plotting
region=`get_site_dims.sh ${site}`
echo $region

# image wrapped phase first, adding title to figure
dlon=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($2 - $1)**2)**(1/2))/2)}' | awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
dlat=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($4 - $3)**2)**(1/2))/2 )}'| awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
echo $dlat
echo $dlon

# get differenced grd file
grdmath $pha1 $pha2 SUB = res.grd

# get size of data for histogram bin width
nbins=`grdinfo -C res.grd | awk '{print ($7-$6)/sqrt($10*$11)}'`

grd2xyz res.grd -Z > hist.txt
pshistogram hist.txt -Y7 -JX10/10 -F -L0.5 -W$nbins -BWSne+t"Histogram of ${pair1} ${pha1} - ${pair2} ${pha2}" -Bx+l"${pha_unit}" -By+l"N" -K -P > ${outfile}
rm hist.txt res.grd

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
