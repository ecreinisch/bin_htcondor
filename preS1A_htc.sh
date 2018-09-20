#!/bin/bash
# 20170217 Elena C Reinisch copy necessary data to submit-3 for preprocessing
#20170220 ECR make SAFE.lst and EOF.lst input files
#20170425 ECR text file input now needs only SAFEdir list because EOF files are contained in SAFEdir
#20170425 ECR optional -c flag to copy to maule
#20180919 ECR add S1B

if [[ $# -eq 0 ]]
then
  echo "prepare directories for HTC pair processing with option to copy to maule"
  echo "e.g.: preS1A_htc.sh [track] [site id] [list of SAFE dirs with EOF files included] [optional -c to copy to maule]"
  exit 1
elif [[ $# -eq 4 ]]
then 
  if [[ $4 == "-c" ]]
  then 
   copy2maule=1
  else
   "unrecongized option. To copy to maule, use -c"
   exit 1
  fi
elif [[ $# -gt 4 ]]
then
  "incorrect number of arguments. see preS1A_htc.sh for usage"
  exit 1
else
  copy2maule=0
fi

# get variables
trk=$1
site=$2
sat=S1A
#site=`grep $sat ~ebaluyut/gmtsar-aux/txt_files/site_sats.txt | grep $trk | awk '{print $1}'`
#subswath=`grep $sat ~ebaluyut/gmtsar-aux/txt_files/site_sats.txt | grep $site | awk '{print $3}' | awk -FF '{print $2}'`
subswath=`grep $site ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $trk | awk '{print $4}' | awk -FF '{print $2}'`

#ls -d *.SAFE > SAFE.lst
#ls *EOF > EOF.lst
#paste $SAFElst $EOFlst > raw.lst

#mkdir tmp
cp $3 raw.lst

while read -r a b; do
 epoch=`echo $a | awk -FT '{print $1}' | awk -F_ '{print $(NF)}'`
 pair_sat=`echo $a | awk '{print substr($1, 1, 3)}'`
# mkdir tmp/S1A${epoch}_F${subswath}
# cp $a/annotation/*${subswath}.xml tmp/S1A${epoch}_F${subswath}/
# cp $a/measurement/*${subswath}.tiff tmp/S1A${epoch}_F${subswath}/
# cp $a/$b tmp/S1A${epoch}_F${subswath}/
# cd tmp
# tar -czvf S1A${epoch}_${subswath}.tgz S1A${epoch}_F${subswath}
 #tar -czvf S1A${epoch}_${subswath}.tgz $a/annotation/*${subswath}.xml $a/measurement/*${subswath}.tiff $a/$b
 xmlname=`find $a/annotation -maxdepth 1 -name "s1*${subswath}.xml"`
 tiffname=`find $a/measurement -maxdepth 1 -name "s1*${subswath}.tiff"`
 tar -czvf ${pair_sat}${epoch}_${subswath}.tgz $xmlname $tiffname $a/$b
 mv ${pair_sat}${epoch}_${subswath}.tgz ../preproc/
done < raw.lst

#rm -rf raw.lst tmp
