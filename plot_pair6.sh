#!/bin/bash 
# Elena C Reinisch 20161004
# script for plotting 1 pair with footer information
# requires the following text files: prd.ll, stm.ll, inj.ll, box.txt
# 20170531 ECR update to allow for UTM plots
# 20171110 ECR add case for stacked grd
# 20171212 Sam fix logic with double pipes
# 20171212 Sam & Kurt fix text labelling in UTM coordinates
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180327 update for new gmtsar-aux layout
# update ECR 20180327 update for new get_site_dims.sh
# update ECR SB 20180418 change polar cpt to copper cpt for unwrap/drange
# update SAB 20180508 change copper cpt to cool cpt for unwrap/drange
# update SAB 20180510 change makecpt to grd2cpt for unwrapped 
# update ECR 20180815 adding cosoc to database
# update ECR 20180919 only copy well files if they exist under gmtsar-aux
# update ECR 20180919 add tusca wells
# update KLF 20190724 add sanem wells
# update KLF 20200129
# update KLF 20210708 adapt to GMT v. 6
# update KLF 20211108 do NOT delete 
# update KLF 20220117 do not plot FORGE GPS stations

if [[ $# -eq 0 ]]; then
    echo "script for plotting 1 pair with footer information"
    echo "plot_pair6.sh [sat] [track] [site] [plot title] [grdfile] [outfile] [mmperfringe] [bperp] [user] [filter_wv] [time span] [pair name]"
    echo "plot_pair6.sh  TSX T30 forge title phasefilt_mask_utm.grd phase_filt_mask.ps 15.5 63.2 feigl 80 999 In20181115_20190418"
    echo "pair_name is used as title for plot"
    echo "mmperfringe is used as colorbar label when plotting unwrapped range change"
    echo "arguments  [bperp] [user] [filter_wv] [time span] [DEM file name with path] are used for comments only"
    exit 1
fi

# parse command line arguments
sat1=$1
trk1=$2
site=$3
pair1=$4
grdfile=$5
outfile=$6
mmperfringe=$7
bas1=$8
user=$9
filter_wv=${10}
dt=${11}
demf=${12}
cdir=`pwd`

if [[ ! -f $grdfile ]]; then
   echo "Could not find input grid file named $grdfile "
   exit -1
fi

# get appropriate well files
echo "site is " ${site}
# Testing on the directory does not port well
#if [[ -d "/usr1/ebaluyut/gmtsar-aux/${site}" ]]; then
#  if [[ `ls /usr1/ebaluyut/gmtsar-aux/${site} | wc -l` -gt 0 ]]; then
#if [[ -d "~ebaluyut/gmtsar-aux/${site}" ]]; then
#  if [[ `ls ~ebaluyut/gmtsar-aux/${site} | wc -l` -gt 0 ]]; then
#cp -v $HOME/FringeFlow/gmtsar-aux/${site}/* .   
#  fi
#fi
cp -v $HOME/siteinfo/${site}/* .

# set gmt environment varibles
#gmt gmtset PS_MEDIA = letter
#gmt gmtset FORMAT_FLOAT_OUT = %.12lg
#gmt gmtset MAP_FRAME_TYPE = plain
#gmt gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
#gmt gmtset FONT_ANNOT_PRIMARY = 8p
#gmt gmtset FONT_LABEL = 8p
#gmt gmtset FORMAT_GEO_MAP  = D 
#gmt gmtset FONT_TITLE = 9p

gmt gmtset PS_MEDIA = letter
gmt gmtset FORMAT_FLOAT_OUT = %.12lg
gmt gmtset MAP_FRAME_TYPE = plain
gmt gmtset MAP_TICK_LENGTH_PRIMARY = -0.05c
gmt gmtset FONT_ANNOT_PRIMARY = 12p
gmt gmtset FONT_LABEL = 12p
gmt gmtset FORMAT_GEO_MAP  = D
gmt gmtset FONT_TITLE = 14p
gmt gmtset MAP_LABEL_OFFSET = 5p
gmt gmtset MAP_TITLE_OFFSET = 3p
gmt gmtset FORMAT_FLOAT_OUT = %3.2f
gmt gmtset PROJ_LENGTH_UNIT = cm
#gmt gmtset PROJ_LENGTH_UNIT = inch

# define region for cutting/plotting
if [[ `gmt grdinfo  $grdfile | grep UTM | wc -l` -gt 0 ]] || [[ $grdfile == *"utm"* ]]; then
    region=`get_site_dims.sh ${site} 2`
    isutm=1
else
    region=`get_site_dims.sh ${site} 1`
    isutm=0
fi
echo $region

# set plotting scheme for UTM.  Determine scaling ratio between X and Y and plot larger axis with size 10
dx=`get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{printf("%10d",$2 - $1)}'`
dy=`get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{printf("%10d",$4 - $3)}'`

#echo DX = $dx
#echo DY = $dy

if [[ $dy -ge $dx ]];then
  pratio=`get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{printf("%1d\n", ($2-$1)/($4-$3)*10)}'`
  jflag="-JX${pratio}/10"
else
  pratio=`get_site_dims.sh ${site} 2 | awk -FR '{print $2}' | awk -F/ '{printf("%1d\n", ($4-$3)/($2-$1)*10)}'`
  jflag="-JX10/${pratio}"
fi
lengthx=`echo $jflag | awk -F/ '{print $1}' | awk -FX '{print $2}'`
lengthy=`echo $jflag | awk -F/ '{print $2}'`
if [[ $isutm == 0 ]];then
  jflag="-JM${lengthx}"
fi

# get dx and dy for plot tick marks
dlon=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($2 - $1)**2)**(1/2))/2)}' | awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
dlat=`echo $region | awk -FR '{print $2}' | awk -F/ '{print ( ((($4 - $3)**2)**(1/2))/2 )}'| awk '{printf("%1.1e", $1)}' | awk '{print substr($1,1,1) substr($1, 4, 4)}' | awk '{printf "%1f", $1}' `
#echo $dlat
#echo $dlon

# define region in km if UTM 
if [[ $isutm == 1 ]];then
  region_km=`get_site_dims.sh $site 2 | awk -FR '{print $2}' | awk -F/ '{printf("-R%6.6f/%6.6f/%6.6f/%6.6f", $1/1e3, $2/1e3, $3/1e3, $4/1e3)}'`
  dlat_km=`echo $dlat | awk '{print $1/1e3}'`
  dlon_km=`echo $dlon | awk '{print $1/1e3}'`
fi 

# file is wrapped phase
if [[ "$grdfile" == *"phase"* ]];then
  if [[ `gmt grdinfo  $grdfile | grep radian | wc -l` -gt 0 ]];then
    gmt makecpt -T-3.14159226418/3.14159226418/.1 -D > cpt.cpt # wrapped phase plot
  else
    gmt makecpt -T-0.5/0.5/.01 -D > cpt.cpt
  fi 
  # if not UTM, plot with file's region, dlat, and dlon 
  if [[ $isutm == 0 ]]; then
    #cp $pair1/unwrap.cpt cpt.cpt
    gmt grdimage $grdfile -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1} ${pair1}" > ${outfile}
  else # if UTM plot file without labeling anything
   gmt grdimage $grdfile -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K > ${outfile}
  fi
  gmt makecpt -T-0.5/0.5/.01 > cpt2.cpt
  gmt psscale  -C${cdir}/cpt2.cpt -Dx3.5/-1/${lengthx}/0.1h -Baf1+l"Phase (cycles, $mmperfringe mm/cycle)" -O -K  >> ${outfile}
  rm cpt.cpt cpt2.cpt

# file is unwrapped radians
elif [[ "$grdfile" == *"unwrap"*  ]]; then
  gmt grdmath $grdfile ISFINITE $grdfile MUL PI DIV 2.0 DIV $mmperfringe  MUL = r2mm.grd

  #20180510 SAB changed makecpt to grd2cpt for unwrapped phase plot 
  gmt makecpt -T-25/25/0.25 -Cpolar -D -I > cpt.cpt 
  zmin=`gmt grdinfo -C -L2 r2mm.grd | awk '{print $6}'`
  zmax=`gmt grdinfo -C -L2 r2mm.grd | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
  gmt makecpt -T${zmin}/${zmax}/${dz} -Cpolar -D -I > cpt.cpt 
 
  #if not UTM, plot with file's region, dlat, and dlon
  if [[ $isutm == 0 ]]; then
    gmt grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1} ${pair1}" -K > ${outfile}
  else
    gmt grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K > ${outfile}
  fi 
  #gmt psscale  -C${cdir}/${pair1}/unwrap.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  gmt psscale  -C${cdir}/cpt.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd

#  file is stacked unwrapped (unwrap_ll.grd)
elif [[ "$grdfile" == *"avg_range"* ]] || [[ "$grdfile" == *"stack"* ]] || [[ "$grdfile"* == *"summed"* ]]; then
  #grdmath $grdfile ISFINITE $grdfile MUL PI DIV 2.0 DIV $mmperfringe  MUL = r2mm.grd
  gmt grdmath $grdfile 1000  MUL = r2mm.grd
  zmin=`gmt grdinfo -C -L2 r2mm.grd | awk '{print $6}'`
  zmax=`gmt grdinfo -C -L2 r2mm.grd | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
  # 20180510 SAB changed makecpt to grd2cpt for unwrapped phase plot 
  #makecpt -T-3.5/0.5/0.05 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  #makecpt -T-0.04/0.07/0.005 -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  gmt makecpt -T${zmin}/${zmax}/${dz} -Cpolar -D -I > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]]; then
    # if not UTM, plot with file's region, dlat, and dlon 
    gmt grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1} ${pair1}" -K > ${outfile}
  else
    gmt grdimage r2mm.grd -Y7 -C${cdir}/cpt.cpt $jflag $region -P -K > ${outfile}
  fi
  gmt psscale  -C${cdir}/cpt.cpt -D5/-1/${lengthx}/0.1h -Baf1+l"Range change rate (mm/yr)" -O -K  >> ${outfile}
  rm cpt.cpt r2mm.grd

# file is unwrapped m 
elif [[ "$grdfile" == *"drho"* ]] || [[ "$grdfile" == *"range"* ]]; then
  gmt grdmath $grdfile 1000 MUL = r2mm.grd # convert to mm
  zmin=`gmt grdinfo -C -L2 r2mm.grd | awk '{print $6}'`
  zmax=`gmt grdinfo -C -L2 r2mm.grd | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
#  makecpt -T${zmin}/${zmax}/${dz} -Ccopper -D -I > cpt.cpt # unwrapped phase plot
#  makecpt -T${zmin}/${zmax}/${dz} -Ccool -D -I > cpt.cpt # unwrapped phase plot
#  20180510 SAB changed makecpt to grd2cpt for unwrapped phase plot 
  gmt grd2cpt r2mm.grd -Ccool -D -I > cpt.cpt # unwrapped phase plot 
  # if not UTM, plot with file's region, dlat, and dlon 
  if [[ $isutm == 0 ]]; then
    gmt grdimage r2mm.grd -X7.5 -C./cpt.cpt $jflag $region -P -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1} ${pair1}" -K > ${outfile}
  else
    gmt grdimage r2mm.grd -X7.5 -C./cpt.cpt $jflag $region -P -K > ${outfile}
  fi
  gmt psscale  -C./cpt.cpt -D3.5/-1/${lengthx}/0.1h -Baf1+l"Range change (mm/yr)" -O -K  >> ${outfile}
  #rm cpt.cpt r2mm.grd
  rm r2mm.grd

# file is a DEM
elif [[ "$grdfile" == *"dem"* ]]; then
  zmin=`gmt grdinfo  -C -L2 $grdfile | awk '{print $6}'`
  zmax=`gmt grdinfo  -C -L2 $grdfile | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
  #20180510 SAB changed makecpt to grd2cpt for unwrapped phase plot 
  gmt makecpt -T${zmin}/${zmax}/${dz} -Cpolar -D  > cpt.cpt # unwrapped phase plot
  # grd2cpt r2mm.grd -Cpolar -D  > cpt.cpt # unwrapped phase plot
  # if not UTM, plot with file's region, dlat, and dlon
  if [[ $isutm == 0 ]]; then
    gmt grdimage  $grdfile -X7.5 -C./cpt.cpt -JX7/12 $region -P -Bwsne -K > ${outfile}
  else
    gmt grdimage  $grdfile -X7.5 -C./cpt.cpt -JX7/12 $region -P -K > ${outfile}
  fi
  gmt psscale  -C./cpt.cpt -D3.5/-1/6/0.1h -Baf1+l"Elevation (m)" -O -K  >> ${outfile}
  rm cpt.cpt

# file contains a volumetric model
elif [[ "$grdfile" == *"volume"* ]]; then
  echo VOLUME CHANGE
  zmin=`gmt grdinfo  -C -L2 $grdfile | awk '{print $6}'`
  zmax=`gmt grdinfo  -C -L2 $grdfile | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
  #20180510 SAB changed makecpt to grd2cpt for unwrapped phase plot 
  makecpt -T${zmin}/${zmax}/${dz} -Cpolar -D  > cpt.cpt # unwrapped phase plot
  #  grd2cpt r2mm.grd -Cpolar -D  > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]] # if not UTM, plot with file's region, dlat, and dlon
  then
    gmt grdimage  $grdfile -X7.5 -C./cpt.cpt -JX7/12 $region -P -Bwsne -K > ${outfile}
  else
    gmt grdimage  $grdfile -X7.5 -C./cpt.cpt -JX7/12 $region -P -K > ${outfile}
  fi
  gmt psscale  -C./cpt.cpt -D3.5/-1/6/0.1h -Baf1+l"Volume Change (m^3/yr)" -O -K  >> ${outfile}
 # rm cpt.cpt

# file contains a model of temperature
elif [[ "$grdfile" == *"temperature"* ]]; then
  echo TEMPERATURE CHANGE
  zmin=`gmt grdinfo  -C -L2 $grdfile | awk '{print $6}'`
  zmax=`gmt grdinfo  -C -L2 $grdfile | awk '{print $7}'`
  dz=`echo $zmax $zmin | awk '{print ($1-$2)/50}'`
  #20180510 SAB changed makecpt to grd2cpt for unwrapped phase plot 
  makecpt -T${zmin}/${zmax}/${dz} -Cpolar -D  > cpt.cpt # unwrapped phase plot
  #  grd2cpt r2mm.grd -Cpolar -D  > cpt.cpt # unwrapped phase plot
  if [[ $isutm == 0 ]]; then
    gmt grdimage  $grdfile -X7.5 -Y5 -C./cpt.cpt $jflag $region -P -Bwsne -K > ${outfile}
  else
    gmt grdimage  $grdfile -X7.5 -Y5 -C./cpt.cpt $jflag $region -P -K > ${outfile}
  fi
  gmt psscale  -C./cpt.cpt -D3.5/-2/6/0.1h -A -Baf1+l"temperature change [C/yr]" -O -K  >> ${outfile}
  gmt psscale  -C./cptv.cpt -D3.5/-2/6/0.1h -Baf1+l"volume change [m^3/yr]" -O -K  >> ${outfile}
 # rm cpt.cpt
else
  cptname=`echo $grdfile | awk -Famp '{print $1"amp.cpt"}'`
  #echo $cptname
  if [[ $isutm == 0 ]]; then
    gmt grdimage  $grdfile -Y7 -C${cdir}/${cptname} ${jflag} $region -P -K -Bx${dlon} -By${dlat} -BWSne+t"${sat1} ${trk1} ${pair1}" > ${outfile}
  else
    gmt grdimage  $grdfile -Y7 -C${cdir}/${cptname} ${jflag} $region -P -K > ${outfile}
  fi 
  gmt psscale  -C${cdir}/${cptname} -D3.5/-1/${lengthx}/0.1h -Baf1+l"data" -O -K  >> ${outfile}
fi


# plot wells and Brady Box
 # use deg format files
if [[ $isutm == 0 ]]; then
  if [[ -e ${site}_box.txt ]]; then
    cat ${site}_box.txt | awk '{print $1,$2}' | gmt psxy $region -W1.5p -J -O -K -V -P >> ${outfile}
  fi
  if [[ "$site" == "brady" ]]; then
    cat ${site}_prd.ll | awk '{print $1,$2}' | gmt psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_inj.ll | awk '{print $1,$2}' | gmt psxy $region -J -Si0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_stm.ll | awk '{print $1,$2}' | gmt psxy $region -J -Ss0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_gps.txt | awk '{print $1,$2}' | gmt psxy ${region}  -J -Sa0.25 -Gblack  -O -K -V -P >> ${outfile}
    cat ${site}_gps.txt | awk '{print $1,$2 , $(NF)}' > text.tmp
    cat ${site}_faults_ll.txt | awk '{print $1,$2}' | gmt psxy ${region}  -J -W1  -O -K -V -P >> ${outfile}
    cat ${site}_fumaroles_ll.txt | awk '{print $1,$2}' | gmt psxy ${region}  -J -Sd0.25 -W.75  -O -K -V -P >> ${outfile}
    gmt pstext  text.tmp -R -F+jBL+f8p -J -Gwhite -N -O -K  >> ${outfile}
    rm ${site}_prd.ll ${site}_inj.ll  ${site}_stm.ll ${site}_box.txt
  elif [[ "$site" == "tungs" ]] || [[ "$site" == "dcamp" ]] || [[ "$site" == "tusca" ]]; then
    cat ${site}_wells_prod.txt | awk '{print $1,$2}' | gmt psxy $region -J -St0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj.txt | awk '{print $1,$2}' | gmt psxy $region -J -Si0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_mon.txt | awk '{print $1,$2}' | gmt psxy $region -J -Ss0.2 -Gblack -O -K -V -P >> ${outfile}
    rm ${site}_wells*.txt
  elif [[ -e ${site}_wells.txt ]]; then
    # set symbol size based on number of wells
    symsize=0.25
    cat ${site}_wells.txt  | awk '{print $1,$2}' | gmt psxy $region -J -St$symsize -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells.txt | awk '{print $1, $2, $(NF)}' > text.tmp
    #gmt pstext  text.tmp -R -F+jBL+f8p -J -Gwhite -N -O -K  >> ${outfile}
    rm text.tmp
  fi
else # use UTM format files
  if [[ -e ${site}_box_utm.txt ]]; then
    cat ${site}_box_utm.txt | awk '{print $1,$2}' | gmt psxy $region -W1.5p -J -O -K -V -P >> ${outfile}
  fi
  if [[ "$site" == "brady" ]]; then
    cat ${site}_prd.utm | awk '{print $1,$2}' | gmt psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_inj.utm | awk '{print $1,$2}' | gmt psxy $region -J -Si0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_stm.utm | awk '{print $1,$2}' | gmt psxy $region -J -Ss0.25 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_faults_utm.txt | awk '{print $1,$2}' | gmt psxy ${region} -J -W1 -O -K -V -P >> ${outfile}
    cat ${site}_fumaroles_utm.txt | awk '{print $1,$2}' | gmt psxy ${region}  -J -Sd0.25 -W.75  -O -K -V -P >> ${outfile}
    cat ${site}_gps_utm.txt | awk '{print $1,$2}' | gmt psxy ${region} -J -Sa0.5 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_gps_utm.txt | awk '{print $1,$2 , $(NF)}' > text.tmp
    gmt pstext  text.tmp -R -F+jBL+f8p -J -Gwhite -N -O -K  >> ${outfile}
    rm text.tmp
  elif [[ "$site" == "forge" ]]; then
    # plot a solid black triangle at the well
    cat ${site}_wells_utm.txt | awk '{print $1,$2}' | gmt psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
    # # plot an outlined triangle at the well
    #  -W Set pen attributes [Default pen is default,black]:
    #        <pen> is a comma-separated list of three optional items in the order:
    #            <width>[c|i|p], <color>, and <style>[c|i|p].
    #        <width> >= 0.0 sets pen width (default units are points); alternatively a pen
    #                  name: Choose among faint, default, or [thin|thick|fat][er|est], or obese.
    #        <color> = (1) <gray> or <red>/<green>/<blue>, all in range 0-255;
    #                  (2) #rrggbb, all in the range 0-255 using hexadecimal numbers;
    #                  (3) <c>/<m>/<y>/<k> in 0-100% range;
    #                  (4) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
    #                  (5) any valid color name.
    #        <style> = (1) pattern of dashes (-) and dots (.), scaled by <width>;
    #                  (2) "dashed", "dotted", "dashdot", "dotdash", or "solid";
    #                  (3) <pattern>[:<offset>]; <pattern> holds lengths (default unit points)
    #                      of any number of lines and gaps separated by underscores.
    #                     The optional <offset> shifts elements from start of the line [0].
  ## SAM PLEASE FIX cat ${site}_wells_utm.txt | awk '{print $1,$2}' | gmt psxy $region -J -St0.25 -Wthin,black,solid -O -K -V -P >> ${outfile}
  # cat ${site}_faults_utm.txt | awk '{print $1,$2}' | gmt psxy ${region} -J -W1 -O -K -V -P >> ${outfile}
  # cat ${site}_fumaroles_utm.txt | awk '{print $1,$2}' | gmt psxy ${region}  -J -Sd0.25 -W.75  -O -K -V -P >> ${outfile}
  # plot GPS stations with squares and label with text on white background
    # cat ${site}_gps_utm.txt | awk '{print $1,$2}' | gmt psxy ${region} -J -Sa0.1 -Gblack -O -K -V -P >> ${outfile}
    # cat ${site}_gps_utm.txt | awk '{print $1,$2, substr($5,5,2)}' > text.tmp
    # gmt pstext  text.tmp -R -F+jMC+f3p -J -Gwhite -N -O -K  >> ${outfile}
    # rm text.tmp
  elif [[ "$site" == "tungs" ]] || [[ "$site" == "dcamp" ]] || [[ "$site" == "tusca" ]] || [[ "$site" == "sanem" ]]; then
    cat ${site}_wells_prod_utm.txt | awk '{print $1,$2}' | gmt psxy $region -J -St0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj_utm.txt  | awk '{print $1,$2}' | gmt psxy $region -J -Si0.2 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_wells_mon_utm.txt  | awk '{print $1,$2}' | gmt psxy $region -J -Ss0.2 -Gblack -O -K -V -P >> ${outfile}
    #rm ${site}_wells*_utm.txt
  elif [[ "$site" == "cosoc" ]]; then
    cat ${site}_wells_prod_utm.txt | awk '{print $1,$2}' | gmt psxy $region -J -St0.2 -Gred   -O -K -V -P >> ${outfile}
    cat ${site}_wells_inj_utm.txt  | awk '{print $1,$2}' | gmt psxy $region -J -Si0.2 -Gblue  -O -K -V -P >> ${outfile}
    cat ${site}_gps_utm.txt        | awk '{print $1,$2}' | gmt psxy $region -J -Sa0.5 -Gblack -O -K -V -P >> ${outfile}
    cat ${site}_gps_utm.txt        | awk '{print $1,$2 , $(NF)}' > text.tmp
    gmt pstext  text.tmp -R -F+jBL+f8p -J -Gwhite -N -O -K  >> ${outfile}
    rm text.tmp
  elif [[ -e ${site}_wells_utm.txt ]]; then
    echo plotting  ${site}_wells_utm.txt 
    cat ${site}_wells_utm.txt 
    cat ${site}_wells_utm.txt | awk '{print $1,$2}' | gmt psxy $region -J -St0.25 -Gblack -O -K -V -P >> ${outfile}
    #cat ${site}_wells_utm.txt | awk '{print $1, $2,$(NF))' > text.tmp
    # gmt pstext  text.tmp -R -F+jBL+f8p -Gwhite -J -N -O -K  >> ${outfile}
    rm text.tmp
  fi
fi

# add scale bar for 1 km to wrapped phase plot for deg plots
if [[ $isutm == 0 ]]; then
  scalex=`echo "$region" | awk -F/ '{x = $2 -0.005; print x}'`
  scaley=`echo "$region" | awk -F/ '{x = $3 + .005; print x}'`
  gmt pscoast -JX50d/10d -R -N1 -L${scalex}/${scaley}/${scaley}/1 -O -K >> ${outfile}
  gmt pscoast -JX50d/10d -R -I0 -I1 -I2 -N1 -N2 -O -K >> ${outfile}
fi

# define bounds and add footer
#echo $ymin
#echo $textstart
if [[ $isutm == 1 ]]; then
    dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/7.5/2)}'`
    ymin=`echo "$region" | awk -F/ '{print $3}'`
    textstart=`echo ${dtext} | awk '{print ($1*8)}'`

    x1=`echo "$region" | awk -F/ '{print $1}'  | awk -FR '{print $2}'` # '{x = $2 - 0.005; print x}'`
    y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
    y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3 )}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
    y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
    y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
    y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
else
    dtext=`echo "$region" | awk -F/ '{print (($4 -$3)/10/2)}'`
    ymin=`echo "$region" | awk -F/ '{print $3}'`
    textstart=`echo ${dtext} | awk '{print ($1*8)}'`

    x1=`echo "$region" | awk -F/ '{print $1}' | awk -FR '{print $2}'`
    y1=`echo $ymin $textstart | awk '{print $1-$2}'` #`echo "$region" | awk -F/ '{x = 10; print x}'`
    x2=`echo $region | awk -F/ '{print $1}' | awk -FR '{x = $2 - 0.005; print x}'`
    y2=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - $3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1; print x}'`
    y3=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 2*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 1.5; print x}'`
    y4=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 3*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2; print x}'`
    y5=`echo $ymin ${textstart} $dtext | awk '{print ($1- $2 - 4*$3)}'` #`echo "$region" | awk -F/ '{x = $3 - 2.5; print x}'`
fi

#echo $x1
#echo $y1
#echo $y2
#echo $y3
#echo $y4
#echo $y5

# add footer info
if [[ "$grdfile" != *"stack"* && "$grdfile" != *"avg_range"* && "$grdfile" != *"summed"* ]]; then
  echo $x1 $y1  'Bperp [m]:' $bas1 > tmp.footer
  echo $x1 $y2  'time span [days]:' $dt >> tmp.footer
  echo $x1 $y3  'filter wavelength [m]:' $filter_wv >> tmp.footer
  echo $x1 $y4  'DEM:' $demf >> tmp.footer
  echo $x1 $y5  $user $cdir $pair1 >> tmp.footer
  cat tmp.footer
  gmt pstext  -R -F+jBL+f10p -J -N -O -K < tmp.footer >> ${outfile}
fi

# if in UTM also add plot with km axis overlay
if [[ $isutm == 1 ]]; then
  #echo jflag is $jflag
  gmt psbasemap $jflag $region_km -Bx${dlon_km}+u"km" -By${dlat_km}+u"km" -BWSne+t"${sat1} ${trk1} ${pair1}" -P -K -O >> ${outfile} 
fi

pdffile=`echo ${outfile} | sed 's/.ps/.pdf/'`
echo "pdffile is $pdffile"
ps2pdf ${outfile} ${pdffile}

#echo $pair1
