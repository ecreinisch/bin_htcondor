#!/bin/bash  
# add -vex to above line for diagnostic purposes  
# based on file from Kurt Feigl
# edit Elena Reinisch 20160909 add subregions for Brady, McGinness Hills,  and Fawnskin
# takes argument for study area:
# mcgh - McGinness Hills
# fawn - Fawnskin
# brady - Bradys
# 20170215 ECR edit for HTC use
# 20170307 ECR edit to incorporate change from RAW to preproc dir names
# 20170413 ECR add dyear to grd file comments
# 20170418 ECR update region information to pull from get_site_dims.sh
# 20170418 KLF & SAB create geotif files, too
# 20170421 ECR & KLR & SAB remove proj_ra2ll lines
# 20170530 ECR switch to converting to UTM using grd2xyz & mapproject 
# 20170713 ECR add creation of drange (range change rate in m per year)
# 20170724 ECR include Sam's leapfrog scripts
# 20170914 ECR more robust for PRM files
# 20170926 Kurt and Sam - update RANGES for tungs
# 20180319 ECR update for new bin_htcondor repo
# 20180327 ECR update for new gmtsar-aux layout
# 20180327 ECR update for new get_site_dims.sh
# 20180418 ECR update removing outdated line for amp_utm
# 20180829 ECR update to make robust for southern hemisphere areas

if [[ $# -eq 0 ]]
then
cat - << ENDOFDOC
$0:t Last modification 20160819

Prepare files from GMT for input into GIPhT version 3.0

Designed to be run in a directory named "gipht" located at the same level as the GMT directories named "topo" and "intf, for example:"

   /data/FAWNSKIN/preproc/
   /data/FAWNSKIN/SLC/
   /data/FAWNSKIN/gipht/
   /data/FAWNSKIN/intf/
   /data/FAWNSKIN/topo/

Takes argument of site ID
e.g.: prepare_grds_for_gipht_e.sh brady

ENDOFDOC

exit 1

else
SAREA=$1 #`pwd | awk -F/gipht '{print $1}' | awk -F/ '{print $2}'`

# set Region of interest here W/E/S/N in degrees
echo $SAREA
#case "$SAREA" in
#  mcgh) # McGinness Hills
#  RANGES='-R-116.95/-116.85/39.56/39.61'  
#  ZONE=11   
#  ;;
#  fawn) # Fawnskin
#  RANGES='-R-116.96/-116.85/34.33/34.39'  # Fawnskin
#  ZONE=11
#  ;;
#  brady) # Bradys
#  RANGES='-R-119.03/-118.99/39.78/39.82'  # Brady
#  ZONE=11
#  ;;
#  *)
#-119.03/-118.99/39.78/39.82
#  echo "ERROR: unknown study area $1"
#  exit 1
#  ;;
#esac
RANGES=`get_site_dims.sh $SAREA 1`
URANGES=`get_site_dims.sh $SAREA 2`
ZONE=`get_site_dims.sh $SAREA 3` 
echo $RANGES
echo $ZONE
DEM=../topo/dem.grd

# Clarify name to distinguish (lon,lat) from UTM (easting, northing)
if [[ ! -e ../topo/dem_ll.grd ]]; then
  \cp $DEM ../topo/dem_ll.grd
fi

# find increments from DEM
incx=`grdinfo $DEM -Vq | grep x_inc | awk '{print $7}'` ; echo incx is $incx
incy=`grdinfo $DEM -Vq | grep y_inc | awk '{print $7}'` ; echo incy is $incy

echo INCX = $incx
echo INCY = $incy

# go to the place where we have interfegograms
cd ../intf

# loop over all possible pa-R-119.03/-118.99/39.78/39.82s 3-digit day of year
for PAIR in `ls -d In*_*`; do
echo Working on pair $PAIR
cd $PAIR

#cp *.PRM ../../preproc/

# remove any old files
echo "Deleting old files...."
\rm -rfv *utm*.grd *cut*.grd

# take real and imagingary parts
grdmath phasefilt_ll.grd COS = refilt_ll.grd
grdmath phasefilt_ll.grd SIN = imfilt_ll.grd
grdmath phase_ll.grd COS = re_ll.grd
grdmath phase_ll.grd SIN = im_ll.grd

# find the name of the parameter file 
imast=`echo $PAIR | awk -F_ '{print $1}' | awk -Fn '{print $2}'`
prmfile=../../preproc/$imast.PRM
echo prmfile is $prmfile

# find fringe spacing in m
metersperfringe=`grep radar_wavelength $prmfile | awk 'NR == 1 {print $3/2.}'`

# second try at fringe spacing if can't read from PRM
if [[ -z $metersperfringe || $metersperfringe == 0 ]]
then
   metersperfringe=`tail -1 ../PAIRSmake_check.txt | awk '{print $13/2}'`
fi

echo metersperfringe is $metersperfringe

# convert from radians to meters
grdmath unwrap_mask_ll.grd ISFINITE unwrap_mask_ll.grd MUL PI DIV 2.0 DIV $metersperfringe MUL = drhomaskd_ll.grd

# cut 
for GRD in  ../../topo/dem_ll.grd drhomaskd_ll.grd re_ll.grd display_amp_ll.grd im_ll.grd refilt_ll.grd imfilt_ll.grd; do
   grdsample $GRD $RANGES -I$incx/$incy -r -G`echo $GRD | sed 's/ll/ll_cut/'`
   echo $GRD | sed 's/ll/ll_cut/'
#   echo ${GRD:r}_cut.grd
done

# project cut grids into UTM
for GRD in ../../topo/dem_ll.grd drhomaskd_ll.grd re_ll.grd display_amp_ll.grd im_ll.grd refilt_ll.grd imfilt_ll.grd; do
   CUTGRD=`echo $GRD | sed 's/ll/ll_cut/'`
   UTMGRD=`echo $GRD | sed 's/ll/utm/'`

 echo $UTMGRD
   # note that the plus sign in the -Ju switch assumes northern hemisphere
   if [[ $UTMGRD == "re"* || $UTMGRD == "im"* || $UTMGRD == "drhomaskd"* || $UTMGRD == *".grd" ]]
   then
     grdproject $CUTGRD -Ju$ZONE/1:1 -C -F $RANGES -G$UTMGRD  
   else
     # convert grd file to temporary text file
     grd2xyz $CUTGRD > grd_ll.tmp
     mapproject grd_ll.tmp -Ju$ZONE/1:1 -C -F > grd_utm.tmp
     xnodes=`grdinfo $CUTGRD -C | awk '{print $10}'`
     ynodes=`grdinfo $CUTGRD -C | awk '{print $11}'`
     deltax=`echo ${URANGES}/${xnodes}/${ynodes} | awk -FR '{print $2}' | awk -F/ '{print ($2-$1)/($5-1)}'`
     deltay=`echo ${URANGES}/${xnodes}/${ynodes} | awk -FR '{print $2}' | awk -F/ '{print ($4-$3)/($6-1)}'`
 #   echo XNODES = $xnodes
  #  echo YNODES = $ynodes
     if [[ $deltax < 0  ]]
     then
       deltax=`echo $deltax | awk '{print (-1)*$1}'`
     fi
     if [[ $deltay < 0 ]]
     then
       deltay=`echo $deltay | awk '{print (-1)*$1}'`
     fi
     echo deltax = $deltax
     echo deltay = $deltay
     echo URANGES = $URANGES
  #   xyz2grd grd_utm.tmp -I${deltax}/${deltay} $URANGES -G$UTMGRD
     #xyz2grd grd_utm.tmp -I8.1671/10.6729 $URANGES -G$UTMGRD
  #nearneighbor ../intf/In20111224_20121027/grd_utm.tmp -I8.16705/10.6729 -N4 -S100 -R326160/329680/4405200/4409800+ue -Gtest.grd
     echo "CUTGRD is" $CUTGRD
     nearneighbor grd_utm.tmp -I${deltax}/${deltay} -N4 -S100 ${URANGES}+ue -G$UTMGRD
     rm grd_utm.tmp grd_ll.tmp  
    fi
done 
 
  if [[ "$SAREA" == "brady" ]]
  then 
   # copy unwrapped grid to grid with far field displacement subtracted out
   #grdmath drhomaskd_utm.grd -Rk328.5/329.5/4405/4406 MEAN = tmp_mean.grd
   #grdmath drhomaskd_utm.grd $URANGES MEAN = tmp_mean.grd
   grdmath drhomaskd_utm.grd -R326500/327500/4408500/4409500 MEAN = tmp_mean.grd
   RHOMEAN=`grdinfo tmp_mean.grd | grep z_min | awk '{print $3}'`
   grdmath drhomaskd_utm.grd $RHOMEAN SUB = drhomaskd0_utm.grd
   rm tmp_mean.grd
   fi

# edit metadata in grd file headers
# -Dxname/yname/zname/scale/offset/invalid/title/remark 
mast=`echo $PAIR | awk -F_ '{print $1}' | awk -FIn '{print $2}'`
slav=`echo $PAIR | awk -F_ '{print $2}'`
dmast=`grep SC_clock_start ../../preproc/*${mast}*.PRM | awk '{print $3}'`
dslav=`grep SC_clock_start ../../preproc/*${slav}*.PRM | awk '{print $3}'`
grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"m"/1///"elevation"/"dyear(mast) = ${dmast}; dyear(slav) = ${dslav}; m/fringe = ${metersperfringe}"          ../../topo/dem_utm.grd
grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"m"/1///"range change"/"dyear(mast) = ${dmast}; dyear(slav) = ${dslav}; m/fringe = ${metersperfringe}" drhomaskd_utm.grd

# make grd file for unwrapped range change rate [m/yr] named drange_utm.grd; edit comments
# script also makes tif files
drhomaskd2drangeperyr.sh drhomaskd_utm.grd

#commands to make geotiff version of drhomaskd_utm
grdconvert drhomaskd_utm.grd=nf out_drho.tif=gd:GTiFF
gdal_translate -a_srs EPSG:32611 out_drho.tif drhomaskd_utm.tif

# convert real and imaginary parts back into phase
grdmath imfilt_utm.grd refilt_utm.grd ATAN2 = phasefilt_utm.grd 
grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"radians"/1///"wrapped phase"/"dyear(mast) = ${dmast}; dyear(slav) = ${dslav}" phasefilt_utm.grd 
grdmath im_utm.grd re_utm.grd ATAN2 = phase_utm.grd
grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"radians"/1///"wrapped phase"/"dyear(mast) = ${dmast}; dyear(slav) = ${dslav}" phase_utm.grd

#commands to make geotiff version for phasefilt_utm
grdconvert phasefilt_utm.grd=nf out_filt.tif=gd:GTiFF
gdal_translate -a_srs EPSG:32611 out_filt.tif phasefilt_utm.tif
grdconvert phase_utm.grd=nf out_p.tif=gd:GTiFF
gdal_translate -a_srs EPSG:32611 out_p.tif phase_utm.tif

echo ii is $ii
# perform quad-tree resampling
#/Users/feigl/gipht/pha2qls/pha2qls1.csh -i phasefilt_utm.grd -L 24 -M 8 -N 4 
#commented out because script no available on maule
#csh -f pha2qls.csh -i phasefilt_utm.grd -L 24 -M 8 -N 4 

#grdinfo phasefilt_utm.grd

# make geotiffs for amp and display_amp
#grdconvert amp_utm.grd=nf out_amp.tif=gd:GTiFF
#gdal_translate -a_srs EPSG:32611 out_amp.tif amp_utm.tif
echo converting display_amp_utm.grd
grdconvert display_amp_utm.grd=nf out_display_amp.tif=gd:GTiFF
gdal_translate -a_srs EPSG:32611 out_display_amp.tif display_amp_utm.tif

# make Sam's leapfrog geotiff files
master=`echo $PAIR | awk -FIn '{print $2}' | awk -F_ '{print $1}'`
slave=`echo $PAIR | awk -F_ '{print $2}'`
cp ~ebaluyut/gmtsar-aux/phasefilt_colortable_UInt16.txt .
cp ~ebaluyut/gmtsar-aux/drange_colortable_UInt16.txt .
make_leapfrog_geotiffs.sh phasefilt_utm.tif ${master} ${slave}
make_leapfrog_geotiffs.sh drange_utm.tif ${master} ${slave} 
\rm -f phasefilt_colortable_UInt16.txt drange_colortable_UInt16.txt

# clean up
\rm -f tmp.grd re_ll.grd im_ll.grd re_utm.grd im_utm.grd tmp *cut*.grd *out*.tif *out*.xml

# make unit vector files
#gmt grd2xyz phasefilt_ll.grd  > ${PAIR}_llt.txt
gmtconvert trans.dat -bi5 | awk '{print $4, $5, $3}' | column -t > ${PAIR}_llt.txt

cd ..
done # loop over PAIR

cd ../preproc
find ../intf -name "*_llt.txt" > llt.tmp 
echo "#pair look_e look_n look_u" > unit_vectors.txt
while read -r a; do
master=`echo $a | awk -F/ '{print $(NF)}' | awk -FIn '{print $2}' | awk -F_ '{print $1}'`
slav=`echo $a | awk -F/ '{print $(NF)}' | awk -FIn '{print $2}' | awk -F_ '{print $2}' | awk -F_llt '{print $1}'`
if [[ `pwd` == *"ALOS"* ]]
then
ALOS_look ${master}.PRM < $a > In${master}_${slav}-orb.txt
else
SAT_look ${master}.PRM < $a > In${master}_${slav}-orb.txt
fi
#echo In${master}_${slav} `awk '{print $4, $5, $6; next}' In${master}_${slav}-orb.txt | awk '{++a[$0]}END{for(i in a)if(a[i]>max){max=a[i];k=i}print k}'` >> unit_vectors.txt
unit_vector=`cat In${master}_${slav}-orb.txt | awk '{print $4, $5, $6}' | sort | uniq -c | sort -r | head -1|  xargs | cut -d" " -f2-`
echo "In${master}_${slav} $unit_vector"  >> unit_vectors.txt
done < llt.tmp
rm llt.tmp
cd ../gipht

echo "Successful completion. Created:"
\ls -l ../intf/*/*utm*.grd
\ls -l ../intf/*/*utm*.tif
fi

#commands to make geotiff version for amp_utm.grd
#../intf/In${master}_${slav}/

#grdconvert ../intf/In${master}_${slav}/amp_utm.grd=nf ../intf/In${master}_${slav}/out_amp.tif=gd:GTiFF
#gdal_translate -a_srs EPSG:32611 ../intf/In${master}_${slav}/out_amp.tif ../intf/In${master}_${slav}/amp_utm.tif
#grdconvert ../intf/In${master}_${slav}/display_amp_utm.grd=nf ../intf/In${master}_${slav}/out_diaplay_amp.tif=gd:GTiFF
#gdal_translate -a_srs EPSG:32611 ../intf/In${master}_${slav}/out_display_amp.tif ../intf/In${master}_${slav}/display_amp_utm.tif


#exit 1

