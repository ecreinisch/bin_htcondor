#!/bin/sh
# Script to pre-process Sentinel-1B TOPS mode in batch form on HTCondor
# Elena C Reinisch 20180604

# set variables
mast=$1
slav=$2
trk=$3
demf=$4
satparam=`echo $5 | awk -FF '{print $(NF)}'`

# source setup file
source setup.sh

# prepare temporary working environment
rm -rf RAW
mkdir RAW
cd RAW

# get raw data
#mkdir S1B${mast}_${satparam}
#mkdir S1B${slav}_${satparam}
scp $maule:/s21/insar/S1B/${trk}/preproc/S1B${mast}_${satparam}.tgz ${mast}.tgz
scp $maule:/s21/insar/S1B/${trk}/preproc/S1B${slav}_${satparam}.tgz ${slav}.tgz
#cd S1B${mast}_${satparam}
tar -xzvf $mast.tgz
mv *${mast}*.SAFE S1B${mast}_${satparam} 
rm $mast.tgz
#cd ../S1B${slav}_${satparam}
tar -xzvf $slav.tgz
mv *${slav}*.SAFE S1B${slav}_${satparam} 
rm $slav.tgz
#cd ..

# get master files
#mbase_name=`find /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${mast}*${satparam}/s1b*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#cat /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${mast}*${satparam}/${mbase_name}.xml > ./${mbase_name}.xml
#mEOF_file=`ls /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${mast}*${satparam}/*.EOF | awk -F/ '{print $(NF)}'`
mbase_name=`find S1B${mast}*${satparam}/annotation/s1b*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
cat S1B${mast}*${satparam}/annotation/${mbase_name}.xml > ./${mbase_name}.xml
mEOF_file=`ls S1B${mast}*${satparam}/*.EOF | awk -F/ '{print $(NF)}'`

# get master files
#sbase_name=`find /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${slav}*${satparam}/s1b*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#cat /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${slav}*${satparam}/${sbase_name}.xml > ./${sbase_name}.xml
#sEOF_file=`ls /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${slav}*${satparam}/*.EOF  | awk -F/ '{print $(NF)}'`
sbase_name=`find S1B${slav}*${satparam}/annotation/s1b*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
cat S1B${slav}*${satparam}/annotation/${sbase_name}.xml > ./${sbase_name}.xml
sEOF_file=`ls S1B${slav}*${satparam}/*.EOF  | awk -F/ '{print $(NF)}'`

# set up symbolic links
#ln -s /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${mast}*${satparam}/s1b*00${satparam}.tiff .
#ln -s /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${mast}*${satparam}/$mEOF_file .
#ln -s /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${slav}*${satparam}/s1b*00${satparam}.tiff .
#ln -s /mnt/gluster/feigl/insar/S1B/${trk}/preproc/S1B${slav}*${satparam}/$sEOF_file .
ln -s S1B${mast}*${satparam}/measurement/s1b*00${satparam}.tiff .
ln -s S1B${mast}*${satparam}/$mEOF_file .
ln -s S1B${slav}*${satparam}/measurement/s1b*00${satparam}.tiff .
ln -s S1B${slav}*${satparam}/$sEOF_file .
ln -s ../dem/${demf} dem.grd 

echo $mbase_name 
echo $mEOF_file
echo $sbase_name
echo $sEOF_file

# perform preprocessing
align_tops.csh `echo ${mbase_name} ${mEOF_file} ${sbase_name} $sEOF_file dem.grd`

# rename PRM, LED, and SLC files
for i in `ls *.LED *.PRM *.SLC`; do
 mv $i `echo $i | awk -F_ '{printf("%s_%s\n", $1, $3)}'`
 if [[ $i == *"PRM"* ]]
 then
  old_root=`echo $i | awk -F. '{print $1}'`
  new_root=`echo $i | awk -F_ '{printf("%s_%s\n", $1, $3)}' | awk -F. '{print $1}'`
   sed -i "s/${old_root}/${new_root}/g" ${new_root}.PRM
 fi
done 

# clean up 
rm *.grd *xml *tiff *dat *EOF

cd ..
