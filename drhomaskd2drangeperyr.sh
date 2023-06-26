#!/bin/bash
# converts from unwrapped range change in [m] (drhomaskd) to unwrapped range change rate [m/yr] (drange)
# edits header info and creates tif files
# used in prepare_grids_for_gipht_esk.sh 
# Elena C Reinisch 20170713
# 20200128 Kurt check for existence before proceeding
# 20210708 KLF port to GMT v. 6
# 20211008 KLF & SAB remove GDAL calls

drhofile=$1
echo DRHOFILE = $drhofile

if [[ $drhofile == *"/drho"* ]]
then 
 path=`echo $drhofile | awk -F/drhomaskd '{print $1}'`
else
 path="."
fi

# 20200128 check for existence before proceeding
if [[ ! -e $drhofile ]]
then
echo ERROR Could not find range file named $drhofile
exit 1
fi

## find time span of pair in terms of days
#dt=`gmt grdinfo $drhofile | grep dyear | sed 's/;//g' | awk '{printf("%5.5f", ($8-$5))}'`

# find difference in years
mast=`gmt grdinfo $drhofile | grep dyear | sed 's/;//g' | awk '{print $5}'`
slav=`gmt grdinfo $drhofile | grep dyear | sed 's/;//g' | awk '{print $8}'`
if [[ -z $mast ]]; then
  mast=`pwd | awk -F/ '{print $NF}' | awk -F_ '{print $1}' | awk -FIn '{print $2}'`
  slav=`pwd | awk -F/ '{print $NF}' | awk -F_ '{print $2}'`
fi
myear=`echo $mast | awk '{print substr($1, 1, 4)}'`
myearend=`echo $mast | awk '{print substr($1, 1, 4)"-12-31" }'`
mday=`echo $mast | awk '{print substr($1, 5, 3)}'`
syear=`echo $slav | awk '{print substr($1, 1, 4)}'`
syearend=`echo $slav | awk '{print substr($1, 1, 4)"-12-31"}'`
sday=`echo $slav | awk '{print substr($1, 5, 3)}'`
daysinmyear=`date -ud $myearend +'%j'`
daysinsyear=`date -ud $syearend +'%j'`
dyearm=`echo $myear $mday $daysinmyear | awk '{printf("%5.4f", $1+$2/$3)}'`
dyears=`echo $syear $sday $daysinsyear | awk '{printf("%5.4f", $1+$2/$3)}'`
dyears=`echo $syear $sday $daysinsyear | awk '{printf("%5.4f", $1+$2/$3)}'`
dt=`echo $dyears $dyearm | awk '{printf("%5.4f", $1-$2)}'`

# make drange file as rate [m/yr]
gmt grdmath $drhofile $dt DIV = $path/drange_utm.grd

# replace comments
gmt grdedit -D:::"m/yr":::"range change rate": $path/drange_utm.grd

# #commands to make geotiff version of drhomaskd_utm
# gmt grdconvert drange_utm.grd=nf out_drange.tif=gd:GTiFF
# gdal_translate -a_srs EPSG:32611 out_drange.tif drange_utm.tif
# rm out_drange.tif
