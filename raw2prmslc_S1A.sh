#!/bin/bash
# script for pre-processing S1A data; to be used on porotomo for getting pair list metadata (not for forming actual pairs)
# run in raw directory
# 20170427 Elena C Reinisch
# update ECR 20180327 update for new get_site_dims.sh

if [[ $# -eq 0 ]]
then
  echo "script for pre-processing S1A data; to be used on porotomo for getting pair list metadata (not for forming actual pairs)"
  echo "run in raw directory"
  echo "raw2prmslc_S1A.sh [trk] [site] [list of directories]"
  echo "e.g."
  echo "raw2prmslc_S1A.sh T144 brady preproc_porotomo.lst"
  exit 1
fi

# set environment variables
trk=$1
site=$2
sat="S1A"
#site=`grep $sat /t31/ebaluyut/gmtsar-aux/site_sats.txt | grep $trk | awk '{print $1}'`
subswath=`grep $site /t31/ebaluyut/gmtsar-aux/txt_files/site_sats.txt | grep $sat | grep $trk | awk '{print $4}' | awk -FF '{print $2}'`
demf=`grep $site /t31/ebaluyut/gmtsar-aux/txt_files/site_dems.txt | awk '{print $2}'`

echo subswath =  $subswath

# get data from preproc_porotomo.lst
while read -r a b; do
  if [[ ! -d $a ]]
  then
     scp -r $maule:/s21/insar/S1A/${trk}/raw/$a .
     cp $a/$b .
  fi
done < $3

mkdir -p raw_tmp
cp $3 raw_tmp/tmp.lst
cd raw_tmp

# get list of all SAFE directories
#ls -d ../*SAFE | awk -F/ '{print $(NF)}' > SAFE.lst
#ls ../*EOF | awk -F/ '{print $(NF)}' > EOF.lst 
#paste $SAFElst $EOFlst > tmp.lst
#rm SAFE.lst EOF.lst

# initialize data.in
> data.in

# set up dem link
region=`get_site_dims.sh $site 1`
echo DEMF = $demf
grdcut /t31/ebaluyut/scratch/TEST_GMTSAR/insar/dem/$demf -Gdem.grd $region 

# split data by 1SSV and 1SDV
grep _1SDV_ tmp.lst > DV.lst
grep _1SSV_ tmp.lst > SV.lst

# set up master 
head -1 DV.lst > mastDV.lst
head -1 SV.lst > mastSV.lst

# make slave list
sed -i '1d' DV.lst
sed -i '1d' SV.lst

# in order to correct for Elevation Antenna Pattern Change, cat the manifest and aux files to the xmls
# delete the first line of the manifest file as it's not a typical xml file.
while read -r c d; do
msafe_dir=$c
mEOFfile=$d
echo msafe_dir = $c
echo mEOFfile = $d
mbase_name=`find ../${msafe_dir}/annotation -name "s1a*00${subswath}.xml" | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#awk 'NR>1 {print $0}' < ../${msafe_dir}/manifest.safe > tmp_file
#cat ../${msafe_dir}/annotation/${mbase_name}.xml tmp_file /t31/ebaluyut/GMTSAR_ShortCourse/Example_S1A_Stack_CPGF_T173/raw_orig/s1a-aux-cal.xml > ./${mbase_name}.xml
cat ../${msafe_dir}/annotation/${mbase_name}.xml > ./${mbase_name}.xml

# set up symbolic links
ln -s ../${msafe_dir}/measurement/s1a*00${subswath}.tiff .
ln -s ../${msafe_dir}/${mEOFfile} .
while read -r a b; do
safe_dir=$a
EOFfile=$b
echo EOFfile = $b
base_name=`find ../$a/annotation -name "s1a*00${subswath}.xml" | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#awk 'NR>1 {print $0}' < ../$a/manifest.safe > tmp_file
#cat ../$a/annotation/${base_name}.xml tmp_file /t31/ebaluyut/GMTSAR_ShortCourse/Example_S1A_Stack_CPGF_T173/raw_orig/s1a-aux-cal.xml > ./${base_name}.xml
cat ../${safe_dir}/annotation/${base_name}.xml > ./${base_name}.xml

# set up symbolic links
ln -s ../$a/measurement/s1a*00${subswath}.tiff .
ln -s ../${safe_dir}/${EOFfile} .

# record to data.in
# echo "${base_name}:${EOFfile}" >> data.in
align_tops.csh ${mbase_name} ${mEOFfile} ${base_name} $EOFfile dem.grd

done < DV.lst

done < mastDV.lst

while read -r c d; do
msafe_dir=$c
mEOFfile=$d
echo MSAFEDIR = $msafe_dir
mbase_name=`find ../${msafe_dir}/annotation -name "s1a*00${subswath}.xml" | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
echo MBASE_NAME = $mbase_name
#awk 'NR>1 {print $0}' < ../${msafe_dir}/manifest.safe > tmp_file
#cat ../${msafe_dir}/annotation/${mbase_name}.xml tmp_file /t31/ebaluyut/GMTSAR_ShortCourse/Example_S1A_Stack_CPGF_T173/raw_orig/s1a-aux-cal.xml > ./${mbase_name}.xml
cat ../${msafe_dir}/annotation/${mbase_name}.xml > ./${mbase_name}.xml

# set up symbolic links
ln -s ../${msafe_dir}/measurement/s1a*00${subswath}.tiff .
cp ../${msafe_dir}/${mEOFfile} .
while read -r a b; do
safe_dir=$a
EOFfile=$b
echo EOFfile = $b
base_name=`find ../$a/annotation -name "s1a*00${subswath}.xml" | awk -F/ '{print $(NF)}' | awk -F. '{print $1}'`
#awk 'NR>1 {print $0}' < ../$a/manifest.safe > tmp_file
#cat ../$a/annotation/${base_name}.xml tmp_file /t31/ebaluyut/GMTSAR_ShortCourse/Example_S1A_Stack_CPGF_T173/raw_orig/s1a-aux-cal.xml > ./${base_name}.xml
cat ../${safe_dir}/annotation/${base_name}.xml > ./${base_name}.xml

# set up symbolic links
ln -s ../$a/measurement/s1a*00${subswath}.tiff .
cp ../${safe_dir}/${EOFfile} .

# record to data.in
# echo "${base_name}:${EOFfile}" >> data.in
echo MSBASE_NAME = $mbase_name
echo MEOFFILE = ${mEOFfile}
echo BASENAME = ${base_name} 
echo EOFFILE = $EOFfile
align_tops.csh ${mbase_name} ${mEOFfile} ${base_name} $EOFfile dem.grd

done < SV.lst

done < mastSV.lst

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

mv *.LED *.SLC *.PRM ../../preproc

cd ..

#rm -r raw_tmp
