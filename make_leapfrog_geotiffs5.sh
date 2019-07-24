#!/bin/bash
#
# Get variables from command line e.g. ./make_leapfrog_geotiffs3.sh tungs drange_utm.tif In20171104_20180327
# Needs to be run in the /intf direcotry.  
echo starting GeoTIFFs...
site="$1"
filename="$2"
pairdir="$3"
masterdate=${pairdir:2:8}
slavedate=${pairdir:11:8}
date_range=${masterdate}_${slavedate} #e.g. 20130513_20140511
cd $pairdir
echo processing ${site} ${filename} ${date_range}
#  Stretch, index, and add 'no_data' alpha channel to the image and pick the correct color table
if [ $filename == 'phasefilt_utm.tif' ] 
then
  # make base file name without extension
  filebase=phasefilt_utm
  # scale the image to unsigned 16-bit integer
  gdal_translate -of GTiff -ot UInt16 -scale -3.1416 3.1416 1 65535 -a_nodata 0 phasefilt_utm.tif phasefilt_utm_indexed.tif
  # work with new 16-bit image
  filename2=phasefilt_utm_indexed.tif
  # make base file name without extension
  filebase2=phasefilt_utm_indexed
  # define the correct colortable
  colortable=~batzli/phasefilt_colortable_UInt16.txt
  # make temporary .vrt template file from original so details of dimensions match in source of .vrt file
  gdal_translate -of VRT ${filename2} ${filebase2}.template.vrt
  # Delete line 9 from the template and save as new temp file
  sed -e '9d' ${filebase2}.template.vrt > tmp1.vrt
  # Insert metadata date range from variable at line 6
  awk -v "n=6" -v "s=    <MDI key=\"TIFFTAG_IMAGEDESCRIPTION\">${site} ${date_range}</MDI>" '(NR==n) { print s } 1' tmp1.vrt > tmp2.vrt
  # Merge the color table with the template at line 9 and make a new .vrt temp file
  sed "9r ${colortable}" tmp2.vrt > tmp3.vrt
  # Copy to final .vrt file
  cp tmp3.vrt ${filebase}.vrt
  # Convert the final .vrt back to a final 8-bit RGBA .tif
  gdal_translate -of GTiff -ot Byte -expand rgba ${filebase}.vrt ${site}_${date_range}_${filebase}_byte.tif
  # Remove temp files
  rm tmp*.vrt
  # Remove template .vrt
  rm ${filebase2}.template.vrt
  # Remove final .vrt file
  rm ${filebase}.vrt
  # Remove indexed .tif
  rm ${filename2}
elif [ $filename == 'drange_utm.tif' ]
then
  # make base file name without extension
  filebase=$(sed 's/.\{4\}$//' <<< "$filename")
  # grep min and max from the gdalinfo to redefine stretch around zero
  grepmin=$(gdalinfo drange_utm.tif | grep "STATISTICS_MINIMUM=" | cut -c24-41)
  grepmax=$(gdalinfo drange_utm.tif | grep "STATISTICS_MAXIMUM=" | cut -c24-41)
  min=$grepmin
  max=$grepmax
  #if [ $( echo "$min < 0" | bc ) -eq 1 ]; then
  #  newmin=`echo "$min - $max" | bc`
  #  newmax=`echo "$newmin * -1" | bc`
  #else
  #  newmax=`echo "$min + $max" | bc`
  #  newmin=`echo "$newmax * -1" | bc`
  #fi
  # scale image to make it symmetrical around zero with 65535 values and an alpha
  gdal_translate -of GTiff -ot UInt16 -scale ${min} ${max} 1 65535 -a_nodata 0 ${filename} ${filebase}_indexed.tif
  # work with new 16-bit image
  filename2=${filebase}_indexed.tif
  # make base file name without extension
  filebase2=$(sed 's/.\{4\}$//' <<< "$filename2")
  # use standard red-white-blue color table 
  #colortable=drange_avg_colortable_UInt16.txt
  colortable=~batzli/drange_cool_colortable_UInt16.txt
  # make temporary .vrt template file from original so details of dimensions match in source of .vrt file
  gdal_translate -of VRT ${filename2} ${filebase2}.template.vrt
  # Delete line 9 from the template and save as new temp file
  sed -e '9d' ${filebase2}.template.vrt > tmp1.vrt
  # Insert metadata date range from variable at line 6
  awk -v "n=6" -v "s=    <MDI key=\"TIFFTAG_IMAGEDESCRIPTION\">${site} ${date_range} MIN=${min} MAX=${max}</MDI>" '(NR==n) { print s } 1' tmp1.vrt > tmp2.vrt
  # Merge the color table with the template at line 9 and make a new .vrt temp file
  sed "9r ${colortable}" tmp2.vrt > tmp3.vrt
  # Convert the .vrt back to a .tif
  cp tmp3.vrt ${filebase}.vrt
  # Convert the final .vrt back to a final 8-bit RGBA .tif
  gdal_translate -of GTiff -ot Byte -expand rgba ${filebase}.vrt ${site}_${date_range}_${filebase}_byte.tif
  # Remove temp files
  #rm tmp*.vrt
  # Remove template .vrt
  #rm ${filebase2}.template.vrt
  # Remove final .vrt file
  #rm ${filebase}.vrt
  # Remove indexed .tif
  #rm ${filename2}
else
  echo Sorry: cannot find file or there is no color table for this file.
fi
