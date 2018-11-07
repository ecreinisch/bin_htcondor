#!/bin/sh
# Script to pre-process Sentinel-1a TOPS mode in batch form on HTCondor
# Elena C Reinisch 20170206
# edit ECR 20170217 for preprocessing during run_pair.sh
# edit ECR 20170710 update to copy data directly from maule
# edit ECR 20180919 merge S1A and S1B

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
#mkdir S1A${mast}_${satparam}
#mkdir S1A${slav}_${satparam}
scp $maule:/s21/insar/S1A/${trk}/preproc/S1*${mast}_${satparam}.tgz ${mast}.tgz
scp $maule:/s21/insar/S1A/${trk}/preproc/S1*${slav}_${satparam}.tgz ${slav}.tgz
#cd S1A${mast}_${satparam}
tar -xzvf $mast.tgz
mv *${mast}*.SAFE S1A${mast}_${satparam} 
rm $mast.tgz
#cd ../S1A${slav}_${satparam}
tar -xzvf $slav.tgz
mv *${slav}*.SAFE S1A${slav}_${satparam} 
rm $slav.tgz
#cd ..

# get master files
#mbase_name=`find /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${mast}*${satparam}/s1a*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#cat /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${mast}*${satparam}/${mbase_name}.xml > ./${mbase_name}.xml
#mEOF_file=`ls /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${mast}*${satparam}/*.EOF | awk -F/ '{print $(NF)}'`
mbase_name=`find S1A${mast}*${satparam}/annotation/s1*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
cat S1A${mast}*${satparam}/annotation/${mbase_name}.xml > ./${mbase_name}.xml
mEOF_file=`ls S1A${mast}*${satparam}/*.EOF | awk -F/ '{print $(NF)}'`

# get master files
#sbase_name=`find /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${slav}*${satparam}/s1a*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#cat /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${slav}*${satparam}/${sbase_name}.xml > ./${sbase_name}.xml
#sEOF_file=`ls /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${slav}*${satparam}/*.EOF  | awk -F/ '{print $(NF)}'`
sbase_name=`find S1A${slav}*${satparam}/annotation/s1*00${satparam}.xml | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
cat S1A${slav}*${satparam}/annotation/${sbase_name}.xml > ./${sbase_name}.xml
sEOF_file=`ls S1A${slav}*${satparam}/*.EOF  | awk -F/ '{print $(NF)}'`

# set up symbolic links
#ln -s /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${mast}*${satparam}/s1a*00${satparam}.tiff .
#ln -s /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${mast}*${satparam}/$mEOF_file .
#ln -s /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${slav}*${satparam}/s1a*00${satparam}.tiff .
#ln -s /mnt/gluster/feigl/insar/S1A/${trk}/preproc/S1A${slav}*${satparam}/$sEOF_file .
ln -s S1A${mast}*${satparam}/measurement/s1*00${satparam}.tiff .
ln -s S1A${mast}*${satparam}/$mEOF_file .
ln -s S1A${slav}*${satparam}/measurement/s1*00${satparam}.tiff .
ln -s S1A${slav}*${satparam}/$sEOF_file .
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
