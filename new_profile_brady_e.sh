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

sat1=$1
trk1=$2
pair1=$3
pha1=$4
pha2=$5
bas1=$6
outfile=$7
cdir=`pwd`

# get appropriate well files
cp /usr1/ebaluyut/SCRIPTS/*.ll .
cp /usr1/ebaluyut/SCRIPTS/box.txt .

# set gmt environment varibles
gmtset PS_MEDIA = letter
gmtset FORMAT_FLOAT_OUT = %.12lg
gmtset MAP_FRAME_TYPE = plain
gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
gmtset FONT_ANNOT_PRIMARY = 8p
gmtset FONT_LABEL = 8p
gmtset FORMAT_GEO_MAP  = D 
gmtset FONT_TITLE = 9p

# define color bars 
makecpt -T-3.14159226418/3.14159226418/.1 -D > cpt.cpt # wrapped phase plot
makecpt -T-25/25/0.25 -Cpolar -D -I > cptr.cpt # unwrapped phase plot

# define region for cutting/plotting
region=-R-119.03/-118.99/39.78/39.82
echo "$outfile"
# image wrapped phase first, adding title to figure
grdimage $pha1 -Y3 -C${cdir}/cpt.cpt -JM5 $region -P -K -Bx0.02 -By0.02 -BWSne+t"$sat1 $trk1" > $outfile

# plot wells and Brady Box
cat prd.ll | awk '{print $1,$2}' | psxy $region -J -St0.125 -Gblack -O -K -V -P >> $outfile
cat inj.ll | awk '{print $1,$2}' | psxy $region -J -Si0.125 -Gblack -O -K -V -P >> $outfile
cat stm.ll | awk '{print $1,$2}' | psxy $region -J -Ss0.125 -Gblack -O -K -V -P >> $outfile
cat box.txt | awk '{print $1,$2}' | psxy $region -J -O -K -V -P >> $outfile
# draw profile line
gmt psxy coord.rsp -R -JM5 -P  -K -O  -Wthinner >> $outfile

# add scale bar for 1 km to wrapped phase plot
#pscoast -J -R -N1 -L-119.024/39.779/39.779/1 -O -K >> $outfile
pscoast -J -R -N1 -L-118.9975/39.784/39.784/1 -O -K >> $outfile

# plot profile points
if (-e profile.rsp) then
   #gmt psxy profile.rsp -Sp -Gwhite -R -JM10 -P -O -K -V >> $out
   cat profile.rsp | awk 'NR % 10 == 0{print $0}' | gmt psxy -Sp -Gwhite -R -JM5 -P -O -K -V >> $outfile
endif

# extract points using nearest neighbor interpolation
  gmt grdtrack profile.rsp -sa -G$pha1 -nn | awk '{print $3,$4}' >! tmp.pg

  # make a profile
  gmt psxy tmp.pg -Sp -Gred -JX7/4 -P `gmt info tmp.pg -I-` -Y-6.5 -O -K \
  -BWS+t"phase" -Bxaf+l"Cross strike coordinate w.r.t. maximum [km]" -Byaf+l"cycles" \
  --FONT_TITLE=14p,Helvetica,black >> $outfile


# find appropriate mm/cycle
if [[ $sat1 == "TSX" ]]
then
    mmperfringe="15.5"
elif [[ $sat1 == "SNT1A" ]]
then
    mmperfringe="27.7"
else
    mmperfringe=""
fi

# convert unwrapped phase to mm
grdmath $pha2 ISFINITE $pha2 MUL PI DIV 2.0 DIV $mmperfringe  MUL = r2mm.grd


grdimage r2mm.grd -X5.25 -C${cdir}/cptr.cpt -JM5 $region -P -Bx0.02 -By0.02  -BwSne+t"$pair1" -O -K >> $outfile
# add scale bar to second plot
pscoast -J -R -N1 -L-118.9975/39.784/39.784/1 -O -K >> $outfile


# plot wells and Brady Box
cat prd.ll | awk '{print $1,$2}' | psxy $region -J -St0.125 -Gblack -O -K -V -P >> $outfile
cat inj.ll | awk '{print $1,$2}' | psxy $region -J -Si0.125 -Gblack -O -K -V -P >> $outfile
cat stm.ll | awk '{print $1,$2}' | psxy $region -J -Ss0.125 -Gblack -O -K -V -P >> $outfile
cat box.txt | awk '{print $1,$2}' | psxy $region -J -O -K -V -P >> $outfile

makecpt -T-0.5/0.5/.01 > cpt2.cpt

# add colorbars to both plots with labels
psscale -C${cdir}/cpt2.cpt -D-2.75/-1./5/0.125h -Baf1+l"Phase (cycles, $mmperfringe mm/cycle)" -O -K  >> $outfile
psscale -C${cdir}/cptr.cpt -D2.5/-1./5/0.125h -Baf10+l"Range change rate (mm/yr)" -O -K  >> $outfile


# add working directory path as footer
pstext -X-2.25 -R -F+jBC -J -N -O -K << EOF >> $outfile
-119.035 39.765  `echo "Bperp $bas1 m"`
-119.03 39.762 `echo "$cdir/$pair1"`
EOF
echo $cdir
echo $pair1

rm cpt.cpt cptr.cpt prd.ll inj.ll stm.ll box.txt r2mm.grd
