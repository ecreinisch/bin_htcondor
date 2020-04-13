#!/bin/bash
# how to run a pair of insar images 2060804 Kurt Feigl 20160806 Elena C Reinisch
# edit 20170218 Elena C Reinisch, change S1A setup for preprocessing per pair; save PRM and LED files to output
# edit 20170710 copy data from maule during job, send email when job has finished; transfer pair directly to maule 
# edit 20170801 ECR update to copy maule ALOS data with frame in the name
# edit 20171114 ECR comment out renaming of p2p_TSX script for airbus and instead add $site to pair2e.sh call
# edit 20180406 ECR update to use new bin_htcondor repo
# edit 20180604 ECR add S1B
# edit 20200406 Kurt and Sam try to fix bug about disk usage exceeds request

# set up environment variables with path names for GMT and GMTSAR
mkdir bin_htcondor
mv bin_htcondor.tgz bin_htcondor
cd bin_htcondor
tar -xzf bin_htcondor.tgz
rm bin_htcondor.tgz
cd ..
tar -xzf GMT5SAR.tgz
#mv home/feigl/GMT5SAR5.2 . 
tar -xzf ssh.tgz
tar -xzf GMT.tgz
# edit set paths in GMTSAR scripts to be relative to job directory
sed -i "/echo/c\echo \"$(pwd)/GMT5SAR5.2/share/gmtsar\"" GMT5SAR5.2/bin/gmtsar_sharedir.csh
tar -xzf gmtsar_dependencies.tgz

ln -s GMT5SAR5.2 gmtsar
ln -s GMT5.2.1 this_gmt

# link for libnetcdf and libhdf5 dependencies
cd this_gmt/lib64/
ln -s libhdf5_hl.so.6.0.4 libhdf5_hl.so.6
ln -s libhdf5.so.6.0.4 libhdf5.so.6
ln -s libnetcdf.so.6.0.0 libnetcdf.so.6
# for GMTSARv5.4
ln -s libhdf5_hl.so.8.0.2 libhdf5_hl.so.8
ln -s libhdf5.so.8.0.2 libhdf5.so.8
ln -s libnetcdf.so.7.2.0 libnetcdf.so.7
cd ../../

source setup.sh

# set satellite and track
sat=$1
trk=$2

# untar orbits directory if sat is ERS or ENVI
if [[ "$sat" == "ENVI" ]]
then
  tar -xf orbits_ENVI.tgz
  rm orbits_ENVI.tgz
elif [[ "$sat" == "ERS"* ]]
then
  tar -xf orbits_ERS.tgz
  rm orbits_ERS.tgz
  sat=ERS
fi

# clean up
rm GMT5SAR.tgz GMT.tgz ssh.tgz gmtsar_dependencies.tgz

# set master and slave variables
mast=$3
slav=$4
user=$5
satparam=$6 # extra parameter for satellite specific parameters (e.g., for S1A satparam = subswath number)
demf=$7
orb1a=`expr $mast - 1`
orb2a=`expr $slav - 1`

# set up ssh transfer
cp -r .ssh /home/${user}/

# set filter wavelength
filter_wv=$8
# set region variables
xmin=$9
xmax=${10}
ymin=${11}
ymax=${12}
site=${13}

# make a local copy of data
mkdir RAW 
mkdir dem

#cp -r /mnt/gluster/feigl/insar/dem/$demf dem/

# cut dem down to size
if [[ "$site" == "test" ]]
then
scp $maule:/s21/insar/condor/feigl/insar/dem/${demf} dem/$demf
xmax=
xmin=
ymax=
ymin=
else
# transfer cut grid file to job server
scp $maule:/s21/insar/condor/feigl/insar/dem/cut_$demf dem/$demf
## remove cut grid file from maule
#ssh -Y $maule "rm /s21/insar/condor/feigl/insar/dem/cut_dem.tmp"
#grdcut /mnt/gluster/feigl/insar/dem/$demf -Gdem/$demf -R$xmin/$xmax/$ymin/$ymax
fi

## get correct p2p file for TSX dcamp and tungs
#if [[ $sat == "TSX" ]]
#then
#  if [[ $site == "dcamp" || $site == "tungs" ]]
#  then
#      mv gmtsar/bin/p2p_TSX_SLC_airbus.sh gmtsar/bin/p2p_TSX_SLC.sh
#  fi
#fi

# ECR 20170709 update raw2prmslc and other data get, test in interactive
if [[ "$sat" == "S1A" || "$sat" == "S1B" ]]
then
  raw2prmslc_${sat}_htc.sh $mast $slav $trk $demf $satparam
elif [[ "$sat" == *"ALOS"* ]]
then 
  scp $maule:/s21/insar/${sat}/${trk}/preproc/${mast}_${satparam}.tgz RAW/${mast}.tgz
  scp $maule:/s21/insar/${sat}/${trk}/preproc/${slav}_${satparam}.tgz RAW/${slav}.tgz
  cd RAW
else
 cd RAW
 # get master data
 scp $maule:/s21/insar/${sat}/${trk}/preproc/${mast}*.tgz .
    # if duplicates, take the one corresponding to this site
   if [[ `ls ${mast}*.tgz | wc -l` -gt 1 ]]
   then
     # keep file that has correct site identifier if it exists
     if [[ -e ${mast}_${site}.tgz ]]
      then
      # keep only site specific file 
      rm ${mast}.tgz
      mv ${mast}_${site}.tgz ${mast}.tgz
     else # if file with correct site identifier doesn't exist then take original
      mv ${mast}.tgz .. 
      # remove incorrect files
      rm ${mast}*.*
      # move correct file back
      mv ../${mast}.tgz . 
     fi
   fi
 # get slave data
 scp $maule:/s21/insar/${sat}/${trk}/preproc/${slav}*.tgz .
    # if duplicates, take the one corresponding to this site
   if [[ `ls ${slav}*.tgz | wc -l` -gt 1 ]]
   then
     # keep file that has correct site identifier if it exists
     if [[ -e ${slav}_${site}.tgz ]]
      then
      # keep only site specific file
      rm ${slav}.tgz
      mv ${slav}_${site}.tgz ${slav}.tgz
     else # if file with correct site identifier doesn't exist then take original
      mv ${slav}.tgz ..
      # remove incorrect files
      rm ${slav}*.*
      # move correct file back
      mv ../${slav}.tgz .
     fi
   fi
fi

 # if data is ALOS then rename files to match epoch dates, otherwise untar as normal
if [[ "$sat" != "S1"*  ]]
then
 if [[ "$sat" == "ALOS"* ]]
 then
   mkdir tmp_mast tmp_slav 
   # rename master data by epoch date
   mv ${mast}.tgz tmp_mast 
   cd tmp_mast
   tar -xzvf ${mast}.tgz 
   rm ${mast}.tgz
   mastroot=`ls LED* | awk -F\- '{print $2}'`
   for mastfile in `ls`; do
      mv $mastfile ../`echo $mastfile | sed "s/${mastroot}/${mast}/"`
   done
   cd ..; rm -r tmp_mast
   # rename slave data by epoch date
   mv ${slav}.tgz tmp_slav
   cd tmp_slav
   tar -xzvf ${slav}.tgz
   rm ${slav}.tgz
   slavroot=`ls LED* | awk -F\- '{print $2}'`
   for slavfile in `ls`; do
      mv $slavfile ../`echo $slavfile | sed "s/${slavroot}/${slav}/"`
   done
   cd ..; rm -r tmp_slav
 else
   tar -xzvf ${mast}*.tgz 
   tar -xzvf ${slav}*.tgz 
   rm ${mast}*.tgz ${slav}*.tgz
 fi
 cd ..
fi

# run a script to write a script
pair2e.sh "$sat" "$mast" "$slav" $satparam dem/${demf} $filter_wv $site $xmin $xmax $ymin $ymax

# actually run the script run.sh output from pair2e.sh
cd In"$mast"_"$slav"; 

bash run.sh

# clean up afterwards
find . -type f  ! -name '*.png'  ! -name '*LED*' ! -name '*PRM' ! -name '*.tif' ! -name '*.tiff' ! -name '*.cpt' ! -name '*corr*.grd'  !  -name '*.kml' ! -name 'display_amp*.grd' ! -name 'phase*.grd' ! -name 'unwrap*.grd' ! -name 'trans.dat'  -delete
find . -type l -delete
mv intf/*/* .
mv topo/* .
mv ../config.*.txt .
mv raw/*LED* raw/*PRM .
rm -rvf intf topo raw dem SLC

if [[ ${mast} != 20170324 || ${slav} != 20170313 ]]
then
grdcut phase_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphase_ll.grd
grdcut phasefilt_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphasefilt_ll.grd
grdcut unwrap_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_ll.grd
grdcut unwrap_mask_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_mask_ll.grd
fi

# print completion status and compute arc if necessary
if [[ -e "phase_ll.grd" && -e "phasefilt_ll.grd" && -e "unwrap_mask_ll.grd" ]] 
then
    pair_status=1
    #grdcut phase_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphase_ll.grd
    #grdcut phasefilt_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphasefilt_ll.grd
    #grdcut unwrap_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_ll.grd
    #grdcut unwrap_mask_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_mask_ll.grd
    gmt grdmath phase_ll.grd phasefilt_ll.grd ARC = arc.grd
    # calculate mean, std, and rms of arc; print to txt file
    arc_mean=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $3}'`
    arc_std=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $5}'`
    arc_rms=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $7}'`
    echo "arc_mean = ${arc_mean}"
    echo "arc_std = ${arc_std}"
    echo "arc_rms = ${arc_rms}"
    rm arc.grd
else
    pair_status=0
fi
echo "pair_status = ${pair_status}"



cd ..
rm -rvf RAW

tar -czvf In${mast}_${slav}.tgz In${mast}_${slav}

# transfer pair to maule under /s21/insar/[sat][trk]/site
ssh -Y $maule "mkdir -p /s21/insar/$sat/$trk/$site" 
scp In${mast}_${slav}.tgz $maule:/s21/insar/$sat/$trk/$site/

# clean up after pair is transferred
rm In${mast}_${slav}.tgz 
#mkdir -p tmp
#mv * tmp/


## send email notification when completed
#useremail="${user}@wisc.edu"
#sendmail "$useremail" <<EOF
#subject: job complete - submit-3 ${sat} ${trk} In${mast}_${slav}.tgz
#run_pair.sh has completed on submit-3 for ${sat} ${trk}: In${mast}_${slav}.tgz
#EOF

## make directory to save to if nonexistent 
#mkdir -p /mnt/gluster/${user}/pairs
#mkdir -p /mnt/gluster/${user}/pairs/$sat
#mkdir -p /mnt/gluster/${user}/pairs/$sat/$trk

## move pair to gluster
#mv In${mast}_${slav}.tgz /mnt/gluster/${user}/pairs/$sat/$trk/
exit 0



