#!/bin/bash -vex
# script for making clean gmt plots comparing phase from 2 different satellites
# Elena C Reinisch 20161004
# 20170531 ECR update to allow for UTM plots as well
# 20171212 Sam & Kurt plot wells on second panel
# 20171212 Sam & Kurt fix text labelling in UTM coordinates
# update ECR 20180319 update for new bin_htcondor repo


if [[ $# -eq 0 ]]
then
echo "script for plotting 2 grd files side-by-side with footer information"
echo "plot_pair_comp.sh [sat] [track] [site] [pair_name] [grdfile1] [grdfile2] [outfile] [mmperfringe] [baseline] [user] [filter_wv] [time span] [DEM file name with path]"
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
pha2=$6
outfile=$7
mmperfringe=$8
bas1=$9
user=${10}
filter_wv=${11}
dt=${12}
demf=${13}
cdir=`pwd`
echo ${outfile}

# get appropriate well files
cp ~ebaluyut/gmtsar-aux/txt_files/${site}_* .

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
if [[ `grdinfo $pha1 | grep UTM | wc -l` -gt 0 ]] || [[ $pha1 == *"utm"* ]]
then
    region=`get_site_dims_utm.sh ${site}`
    isutm=1
else
    region=`get_site_dims.sh ${site}`
    isutm=0
fi
echo $region

# set plotting scheme for UTM.  Determine scaling ratio between X and Y and plot larger axis with size 10
dx=`get_site_dims_utm.sh ${site} | awk -FR '{print $2}' | awk -F/ '{print $2 - $1}'`
dy=`get_site_dims_utm.sh ${site} | awk -FR '{print $2}' | awk -F/ '{print $4 - $3}'`
echo DY = $dy
echo DX = $dx
if [[ $dy -ge $dx ]]
then
  pratio=`get_site_dims_utm.sh ${site} | awk -FR '{print $2}' | awk -F/ '{printf("%1d\n", ($2-$1)/($4-$3)*7)}'`
  jflag="-JX${pratio}/7"
else
  pratio=`get_site_dims_utm.sh ${site} | awk -FR '{print $2}' | awk -F/ '{printf("%1d\n", ($4-$3)/($2-$1)*7)}'`
  jflag="-JX7/${pratio}"
fi
lengthx=`echo $jflag | awk -F/ '{print $1}' | awk -FX '{print $2}'`
lengthy=`echo $jflag | awk -F/ '{print $2}'`
if [[ $isutm == 0 ]]
then
  jflag="-JM${lengthx}"
fi
echo JFLAG = $jflag

# get dx and dy for plot tick marks
dlon=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($2 - $1)**2)**(1/2))/2)}' | awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
dlat=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($4 - $3)**2)**(1/2))/2 )}'| awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
echo $dlat
echo $dlon

# define region in km if UTM 
if [[ $isutm == 1 ]]
then
  region_km=`get_site_dims_utm.sh $site | awk -FR '{print $2}' | awk -F/ '{printf("-R%6.6f/%6.6f/%6.6f/%6.6f", $1/1e3, $2/1e3, $3/1e3, $4/1e3)}'`
  dlat_km=`echo $dlat | awk '{print $1/1e3}'`
  dlon_km=`echo $dlon | awk '{print $1/1e3}'`
fi 

# if file is phase
if [[ "$pha1" == *"phase"* ]]
then
  if [[ `grdinfo $pha1 | grep radian | wc -l` -gt 0 ]]
  then
    makecpt -T-3.14159226418/3.14159226418/.1 -D > cpt.cpt # wrapped phase plot
  else
    makecpt -T-0.5/0.5/.01 -D > cpt.cpt
  fi 
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon 
  then
    grdimage $pha1 -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1}" > ${outfile}
  else # if UTM plot file without labeling anything
   grdimage $pha1 -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K > ${outfile}
  fi
  makecpt -T-0.5/0.5/.01 > cpt2.cpt
  psscale -C${cdir}/cpt2.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Phase (cycles, $mmperfringe mm/cycle)" -O -K  >> ${outfile}
  rm cpt.cpt cpt2.cpt
# if file is unwrapped radians
elif [[ "$pha1" == *"unwrap"*  ]]
then
  grdmath $pha1 ISFINITE $pha1 MUL PI DIV 2.0 DIV $mmperfringe  MUL = r2mm.grd
  makecpt -T-15/15/0.1 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1}" -K > ${outfile}
  else
    grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K > ${outfile}
  fi 
  psscale -C${cdir}/unwl -1 |rap.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd
# if file is unwrapped m 
elif [[ "$pha1" == *"drho"* ]] || [[ "$pha1" == *"range"* ]]
then
  grdmath $pha1 1000 MUL = r2mm.grd # convert to mm
  makecpt -T-15/15/0.1 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage r2mm.grd -Y7 -C./cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1}" -K > ${outfile}
  else
    grdimage r2mm.grd -Y7 -C./cpt.cpt $jflag $region -P -K > ${outfile}
  fi
  psscale -C./cpt.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd
else
  cptname=`echo $pha1 | awk -Famp '{print $1"amp.cpt"}'`
  echo $cptname
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage $pha1 -Y7 -C${cdir}/${cptname} ${jflag} $region -P -K -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1}" > ${outfile}
  else
    grdimage $pha1 -Y7 -C${cdir}/${cptname} ${jflag} $region -P -K > ${outfile}
  fi 
  psscale -C${cdir}/${cptname} -D3.5/-1/${lengthx}/0.1h -Baf1+l"data" -O -K  >> ${outfile}
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
 elif [[ "$site" == "tungs" ]] || [[ "$site" == "dcamp" ]]
  then
    cat ${site}_wells_prod.txt | awk '{print $1,$2}' | psxy $region -J -St0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj.txt | awk '{print $1,$2}' | psxy $region -J -Si0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_mon.txt | awk '{print $1,$2}' | psxy $region -J -Ss0.2 -Gblack -O -K -V -P >> ${outfile}
    # 2017121 # rm ${site}_wells*.txt
  elif [[ -e ${site}_wells.txt ]]
  then
    cat ${site}_wells.txt  | awk '{print $1,$2}' | psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
 #  if [[ "$site" == "dixie" ]]
 #   then
 #     cat ${site}_wells.txt | head -2 | awk '{print $1, $2+.005, $(NF)}' > text.tmp
 #     cat ${site}_wells.txt | tail -1 | awk '{print $1, $2-.005, $(NF)}' >> text.tmp
 #   else
      cat ${site}_wells.txt | awk '{print $1, $2, $(NF)}' > text.tmp
 #   fi
#    pstext text.tmp -R -F+jBL+f5p -J  -Gwhite -O -K  >> ${outfile}
    rm text.tmp
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
 elif [[ "$site" == "tungs" ]] || [[ "$site" == "dcamp" ]]
  then
    cat ${site}_wells_prod_utm.txt | awk '{print $1,$2}' | psxy $region -J -St0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj_utm.txt | awk '{print $1,$2}' | psxy $region -J -Si0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_mon_utm.txt | awk '{print $1,$2}' | psxy $region -J -Ss0.2 -Gblack -O -K -V -P >> ${outfile}
    # 2017121 # rm ${site}_wells*_utm.txt
  elif [[ -e ${site}_wells_utm.txt ]]
  then
    cat ${site}_wells_utm.txt  | awk '{print $1,$2}' | psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
#  if [[ "$site" == "dixie" ]]
#    then
#      cat ${site}_wells_utm.txt | head -2 | tail -1 | awk '{print $1, $2+500, $(NF)}' > text.tmp
#      cat ${site}_wells_utm.txt | tail -1 | awk '{print $1, $2-500, $(NF)}' >> text.tmp
#    else
      cat ${site}_wells_utm.txt | awk '{print $1, $2, $(NF)}' > text.tmp
#    fi
 #   pstext text.tmp -R -F+jBL+f5p -J -Gwhite -O -K  >> ${outfile}
    rm text.tmp
  fi
fi

# add scale bar for 1 km to wrapped phase plot for deg plots
if [[ $isutm == 0 ]]
then
  scalex=`echo "$region" | awk -F/ '{x = $2 -0.005; print x}'`
  scaley=`echo "$region" | awk -F/ '{x = $3 + .005; print x}'`
  pscoast -JX50d/10d -R -N1 -L${scalex}/${scaley}/${scaley}/1 -O -K >> ${outfile}
  pscoast -JX50d/10d -R -I0 -I1 -I2 -N1 -N2 -O -K >> ${outfile}
fi

# define bounds and add footer
ymin=`echo "$region" | awk -F/ '{print $3}'`
echo $ymin
echo $textstart
if [[ $isutm == 1 ]]
then
# define vertical step size in cm
dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/5/2)}'`
textstart=`echo ${dtext} | awk '{print ($1*7)}'`

#x1=325500 # `echo "$region" | awk -F/ '{print $1}'  | awk -FR '{print $2}'` # '{x = $2 - 0.005; print x}'`
x1=`echo "$region" | awk -F/ '{print $1}'  | awk -FR '{print $2}'` # '{x = $2 - 0.005; print x}'`
y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3 )}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
#y1=`expr $ymin - 1400`
#y2=`expr $ymin - 1600`
#y3=`expr $ymin - 1800`
#y4=`expr $ymin - 2000`
#y5=`expr $ymin - 2200`
else
  # define vertical step size in cm
dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/10/2)}'`
textstart=`echo ${dtext} | awk '{print ($1*7)}'`

#x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{print $2}'`
y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
x2=`echo $region | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
fi

echo $x1
echo $y1
echo $y2
echo $y3
echo $y4
echo $y5

# add footer info
#pstext -Xf2 -R -F+jBL -J -N -O -K << EOF >> ${outfile}
pstext -R -F+jBL+f10p -J -N -O -K << EOF >> ${outfile}
$x1 $y1  `echo "Bperp [m]: $bas1"`
$x1 $y2  `echo "time span [days]: $dt"`
$x1 $y3  `echo "filter wavelength [m]: $filter_wv"`
$x1 $y4  `echo "DEM: $demf"`
$x1 $y5  `echo "$user: $cdir/$pair1"`
EOF

# if in UTM also add plot with km axis overlay
if [[ $isutm == 1 ]]
then
  psbasemap $jflag $region_km -Bx${dlon_km}+u"km" -By${dlat_km}+u"km" -BWSne+t"${sat1} ${trk1}" -P -K -O >> ${outfile}
fi


## plot second image
echo PLOT 2 STARTING NOW
# if file is phase
if [[ "$pha2" == *"phase"* ]]
then
  if [[ `grdinfo $pha2 | grep radian | wc -l` -gt 0 ]]
  then
    makecpt -T-3.14159226418/3.14159226418/.1 -D > cpt.cpt # wrapped phase plot
  else
    makecpt -T-0.5/0.5/.01 -D > cpt.cpt
  fi
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage $pha2 -X7.5 -C${cdir}/cpt.cpt $jflag $region -P -O -K -Bx${dlon} -By${dlat} -BwSnE+t"${pair1}" >> ${outfile}
  else # if UTM plot file without labeling anything
   grdimage $pha2 -X7.5 -C${cdir}/cpt.cpt $jflag $region -P -O -K >> ${outfile}
  fi
  makecpt -T-0.5/0.5/.01 > cpt2.cpt
  psscale -C${cdir}/cpt2.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Phase (cycles, $mmperfringe mm/cycle)" -O -K  >> ${outfile}
  rm cpt.cpt cpt2.cpt
# if file is unwrapped radians
elif [[ "$pha2" == *"unwrap"*  ]]
then
  grdmath $pha2 ISFINITE $pha2 MUL PI DIV 2.0 DIV $mmperfringe  MUL = r2mm.grd
  makecpt -T-15/15/0.1 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
   # cp $pair1/unwrap.cpt cpt.cpt
    grdimage r2mm.grd -X7.5 -C${cdir}/cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BwSnE+t"${pair1}" -O -K >> ${outfile}
  else
    grdimage r2mm.grd -X7.5 -C${cdir}/cpt.cpt $jflag $region -P  -O -K >> ${outfile}
  fi
  psscale -C${cdir}/cpt.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd
# if file is unwrapped m
elif [[ "$pha2" == *"drho"* ]] || [[ "$pha2" == *"range"* ]]
then
  grdmath $pha2 1000 MUL = r2mm.grd # convert to mm
  makecpt -T-15/15/0.1 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage r2mm.grd -X7.5 -C./cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BwSnE+t"${pair1}" -K -O >> ${outfile}
  else
    grdimage r2mm.grd -X7.5 -C./cpt.cpt $jflag $region -P -K -O >> ${outfile}
  fi
  psscale -C./cpt.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd
else
  cptname=`echo $pha2 | awk -Famp '{print $1"amp.cpt"}'`
  echo $cptname
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    grdimage $pha2 -X7.5 -C${cdir}/${cptname} ${jflag} $region -P -K -O -Bx${dlon} -By${dlat} -BwSnE+t"${pair1}" >> ${outfile}
  else
    grdimage $pha2 -X7.5 -C${cdir}/${cptname} ${jflag} $region -P -K -O >> ${outfile}
  fi
  psscale -C${cdir}/${cptname} -D3.5/-1/${lengthx}/0.1h -Baf1+l"data" -O -K  >> ${outfile}
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
 elif [[ "$site" == "tungs" ]] || [[ "$site" == "dcamp" ]]
  then
    cat ${site}_wells_prod.txt | awk '{print $1,$2}' | psxy $region -J -St0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj.txt | awk '{print $1,$2}' | psxy $region -J -Si0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_mon.txt | awk '{print $1,$2}' | psxy $region -J -Ss0.2 -Gblack -O -K -V -P >> ${outfile}
    rm ${site}_wells*.txt
  elif [[ -e ${site}_wells.txt ]]
  then
    cat ${site}_wells.txt  | awk '{print $1,$2}' | psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
 #  if [[ "$site" == "dixie" ]]
 #   then
 #     cat ${site}_wells.txt | head -2 | awk '{print $1, $2+.005, $(NF)}' > text.tmp
 #     cat ${site}_wells.txt | tail -1 | awk '{print $1, $2-.005, $(NF)}' >> text.tmp
 #   else
      cat ${site}_wells.txt | awk '{print $1, $2, $(NF)}' > text.tmp
 #   fi
 #   pstext text.tmp -R -F+jBL+f5p -J -Gwhite -N -O -K  >> ${outfile}
    rm text.tmp
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
 elif [[ "$site" == "tungs" ]] || [[ "$site" == "dcamp" ]]
  then
    cat ${site}_wells_prod_utm.txt | awk '{print $1,$2}' | psxy $region -J -St0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj_utm.txt | awk '{print $1,$2}' | psxy $region -J -Si0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_mon_utm.txt | awk '{print $1,$2}' | psxy $region -J -Ss0.2 -Gblack -O -K -V -P >> ${outfile}
    rm ${site}_wells*_utm.txt
  elif [[ -e ${site}_wells_utm.txt ]]
  then
    cat ${site}_wells_utm.txt  | awk '{print $1,$2}' | psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
 #  if [[ "$site" == "dixie" ]]
 #   then
 #     cat ${site}_wells_utm.txt | head -2 | awk '{print $1, $2+500, $(NF)}' > text.tmp
 #     cat ${site}_wells_utm.txt | tail -1 | awk '{print $1, $2-500, $(NF)}' >> text.tmp
 #   else
      cat ${site}_wells_utm.txt | awk '{print $1, $2, $(NF)}' > text.tmp
 #   fi
 #   pstext text.tmp -R -F+jBL+f5p -J -Gwhite -N -O -K  >> ${outfile}
    rm text.tmp
  fi
fi

# add scale bar for 1 km to wrapped phase plot for deg plots
if [[ $isutm == 0 ]]
then
  scalex=`echo "$region" | awk -F/ '{x = $2 -0.005; print x}'`
  scaley=`echo "$region" | awk -F/ '{x = $3 + .005; print x}'`
  pscoast -JX50d/10d -R -N1 -L${scalex}/${scaley}/${scaley}/1 -O -K >> ${outfile}
  pscoast -JX50d/10d -R -I0 -I1 -I2 -N1 -N2 -O -K >> ${outfile}
fi

# if in UTM also add plot with km axis overlay
if [[ $isutm == 1 ]]
then
  psbasemap $jflag $region_km -Bx${dlon_km}+u"km" -By${dlat_km}+u"km" -BwSnE+t"${pair1}" -P -K -O >> ${outfile}
fi

exit



# define bounds and add footer
dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/10/2)}'`
ymin=`echo "$region" | awk -F/ '{print $3}'`
textstart=`echo ${dtext} | awk '{print ($1*7)}'`
echo $ymin
echo $textstart
if [[ $isutm == 1 ]]
then
#x1=325500 # `echo "$region" | awk -F/ '{print $1}'  | awk -FR '{print $2}'` # '{x = $2 - 0.005; print x}'`
x1=`echo "$region" | awk -F/ '{print $1}'  | awk -FR '{print $2}'` # '{x = $2 - 0.005; print x}'`
y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3 )}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
#y1=`expr $ymin - 1400`
#y2=`expr $ymin - 1600`
#y3=`expr $ymin - 1800`
#y4=`expr $ymin - 2000`
#y5=`expr $ymin - 2200`
else
#x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{print $2}'`
y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
x2=`echo $region | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
fi

echo $x1
echo $y1
echo $y2
echo $y3
echo $y4
echo $y5

# add footer info
#pstext -Xf2 -R -F+jBL -J -N -O -K << EOF >> ${outfile}
pstext -R -F+jBL+f10p -J -N -O -K << EOF >> ${outfile}
$x1 $y1  `echo "Bperp [m]: $bas1"`
$x1 $y2  `echo "time span [days]: $dt"`
$x1 $y3  `echo "filter wavelength [m]: $filter_wv"`
$x1 $y4  `echo "DEM: $demf"`
$x1 $y5  `echo "$user: $cdir/$pair1"`
EOF
