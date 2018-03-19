#!/bin/bash
# script for automatically querying S1A data
# 20170218 Elena C Reinisch

#get site id
site=$1
trk=$2

rm aux_poeorb*

# get most recent date of orbit files
wget https://www.unavco.org/data/imaging/sar/lts1/winsar/s1qc/aux_poeorb
tend=`more aux_poeorb | tail -5 | head -1 | awk -F.EOF '{print $1}' | awk -F_ '{print $(NF)}' | awk -FT '{print $1}' | awk '{printf("%s-%s-%s\n",substr($1, 1, 4), substr($1, 5, 2), substr($1, 7, 2))}'`

# get most recent downloaded date
lastepoch=`tail -1 ../preproc/*_pairs.txt | awk '{print $2}'`
echo $lastepoch
t1=`echo $lastepoch | awk '{printf("%s-%s-%s\n", substr($1, 1, 4), substr($1, 5, 2), substr($1, 7, 2))}'`
tstart=`date -d "$lastepoch +1 days" +%Y-%m-%d` 
echo $tstart

# get polygon info
if [[ "$site" == "brady" ]] 
then
# poly="POLYGON((-119.01911973953247 39.8040915261595,-118.99873495101929 39.8040915261595,-118.99873495101929 39.789088908334485,-119.01911973953247 39.789088908334485,-119.01911973953247 39.8040915261595))"
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-119.01911973953247 39.8040915261595,-118.99873495101929 39.8040915261595,-118.99873495101929 39.789088908334485,-119.01911973953247 39.789088908334485,-119.01911973953247 39.8040915261595))" -s $tstart --download
# echo "skip download"
elif [[ "$site" == "tungs" ]]
then
#  poly="POLYGON((-117.6862733369275 39.67244569755783, -117.6919090194407 39.66776355092392, -117.6906027275874 39.66684680613911, -117.6849326882351 39.67153401886861, -117.6862733369275 39.67244569755783))"
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-117.6862733369275 39.67244569755783, -117.6919090194407 39.66776355092392, -117.6906027275874 39.66684680613911, -117.6849326882351 39.67153401886861, -117.6862733369275 39.67244569755783))" -s $tstart --download
elif [[ "$site" == "dixie" ]]
then
# poly="POLYGON((-118.1375544666061 39.76728909273659, -117.9726034519923 39.76155907198107, -117.9661583795073 39.83590474090825, -118.1384607218144 39.83892561603565, -118.1375544666061 39.76728909273659))"
  ssara_federated_query.py --platform=SENTINEL-1A --intersectsWith="POLYGON((-118.1375544666061 39.76728909273659, -117.9726034519923 39.76155907198107, -117.9661583795073 39.83590474090825, -118.1384607218144 39.83892561603565, -118.1375544666061 39.76728909273659))" -s $tstart --download
else
  echo "undefined polygon for site. Please udpate script"
  exit 1
fi

# unzip downloads

> newSAFE.lst

for i in `ls *.zip`; do
  if [[ ! -d `echo $i | awk -F.zip '{print $1".SAFE"}'`  ]]
  then
    echo $i
    unzip $i
    echo "`echo $i | awk -F.zip '{print $1".SAFE"}'` " >> newSAFE.lst
  fi 
done

# get orbital info
sentinel_orb.sh newSAFE.lst 

# transfer data
paste newSAFE.lst newEOF.lst > newTransfer.lst
preS1A_htc.sh $trk newTransfer.lst
mv tmp transfer-`date +%Y%m%d_%H%M`

# get initial PRM files for egenerate_pairlist
tmp_preproc_S1A.sh $trk newTransfer.lst

# update pairlist 
cd ../preproc
egenerate_pairlist.sh ${site}
cd ../raw

# make PAIRSmake.txt and transfer to submit-3
newestepoch=`tail -1 ../preproc/*_pairs.txt | awk '{print $2}'`
generate_PAIRSmake.sh -f../preproc/S1A_${trk}_${site}_pairs.txt -p${last_epoch}/${newestepoch} -w50
mv PAIRSmake.txt PAIRSmake-`date +%Y%m%d_%H%M`.txt
scp PAIRSmake-`date +%Y%m%d_%H%M`.txt ebaluyut@submit-3.chtc.wisc.edu:/home/ebaluyut/
scp PAIRSmake-`date +%Y%m%d_%H%M`.txt ebaluyut@submit-3.chtc.wisc.edu:/home/ebaluyut/PAIRSmake.txt
scp ../preproc/S1A_${trk}_${site}_pairs.txt ebaluyut@submit-3.chtc.wisc.edu:/mnt/gluster/feigl/insar/S1A/${trk}/preproc/

# submit jobs 
ssh ebaluyut@submit-3.chtc.wisc.edu 'make run'
