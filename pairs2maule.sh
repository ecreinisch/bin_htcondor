#!/bin/bash
# script to copy all pairs in PAIRSmake.txt to maule
# Elena Reinisch 20161026
# edit ECR 20170724 update; comment out removing data from gluster via transfer00 because we no longer use gluster

# set variables
user=`echo $HOME | awk -F/ '{print $(NF)}'`
demf=`cat PAIRSmake_check.txt | tail -1 | awk '{print $18}'`

# loop over PAIRSmake to find successful pairs
while read -r line; do
   # ignore commented lines
    [[ "$line" =~ ^#.*$ && "$line" != [[:blank:]]  ]] && continue
   # set variables from PAIRSmake
    sat=`echo $line | awk '{print $17}'`
    trk=`echo $line | awk '{print $9}'`
    mast=`echo $line | awk '{print $1}'`
    slav=`echo $line | awk '{print $2}'`
    fout=`find . -maxdepth 1 -name "${sat}_${trk}_In${mast}_${slav}*.out"`
    site=`echo $line | awk '{print $12}'`
    status=`grep pair_status ${fout} | awk '{print $3}'`
#    if [[ "$status" == "1" ]]
#    then
      #scp /mnt/gluster/${user}/${sat}/${trk}/In${mast}_${slav}.tgz $maule:/s21/insar/${sat}/${trk}/${site}
      scp In${mast}_${slav}.tgz $maule:/s21/insar/${sat}/${trk}/${site}
      scp ${sat}_${trk}_In${mast}_${slav}.* $maule:/s21/insar/${sat}/${trk}/${site}
#    fi
    rm ${sat}_${trk}_In${mast}_${slav}.*
    rm In${mast}_${slav}.tgz
done < PAIRSmake_check.txt

## remove old data
#ssh -Y ${user}@transfer00.chtc.wisc.edu 'rm -r /mnt/gluster/feigl/insar/${sat}/${trk}/preproc/*'
#ssh -Y ${user}@transfer00.chtc.wisc.edu 'rm /mnt/gluster/feigl/insar/dem/${demf}'

scp PAIRSmake_check.txt $maule:/s21/insar/${sat}/${trk}/${site}/PAIRSmake-`date +%Y%m%d_%H%M`.txt
