#!/bin/bash
# script to copy all pairs in PAIRSmake.txt to porotomo.  Argument for path from t31
# Elena Reinisch 20170227
# Edit ECR 20170302 fix links for S1A case 
# edit ECR 20170622 update to work with pairs now copied directly to maule during jobs
# edit ECR 20170724 update; comment out removing data from gluster via transfer00 because we no longer use gluster
# edit ECR 20180319 transfer process.err and process.out for each pair

# set variables
ppath=$1
user=`echo $HOME | awk -F/ '{print $(NF)}'`
echo $ppath
site=`cat PAIRSmake_check.txt | tail -1 | awk '{print $12}'`
demf=`cat PAIRSmake_check.txt | tail -1 | awk '{print $18}'`
> maule_pairs.lst
# check that ppath exists and setup directory
ssh -Y $ice "mkdir -p /mnt/t31/$ppath; cd /mnt/t31/$ppath; cp /usr1/ebaluyut/bin_htcondor/makefile_condor makefile; make setup"
site=`cat PAIRSmake_check.txt | tail -1 | awk '{print $12}'`
ssh -Y $ice "sed -i "/site=/c\site=${site}" /mnt/t31/$ppath/makefile"

# loop over PAIRSmake to find successful pairs
while read -r line; do
   echo $line
   # ignore commented lines
    [[ "$line" =~ ^#.*$ && "$line" != [[:blank:]]  ]] && continue
   # set variables from PAIRSmake
    sat=`echo $line | awk '{print $17}'`
    trk=`echo $line | awk '{print $9}'`
    if [[ "$sat" == "TDX" ]]
    then
      sat=TSX
    fi
    mast=`echo $line | awk '{print $1}'`
    slav=`echo $line | awk '{print $2}'`
    satparam=`echo $line | awk '{print $11}'`
    fout=`find . -maxdepth 1 -name "${sat}_${trk}_In${mast}_${slav}*.out"`
    status=`grep pair_status ${fout} | awk '{print $3}'`
    echo $status
    echo "$maule:/s21/insar/${sat}/${trk}/${site}/In${mast}_${slav}.tgz" >> maule_pairs.lst 

    # wrap ssh commands into dev/null to avoid ssh eating up action list
#       if [[ "$sat" == "S1A" ]]
#       then
#       ssh -Y $ice "cd /mnt/t31/$ppath/intf; tar -xzvf In${mast}_${slav}.tgz; rm In${mast}_${slav}.tgz; cd ../preproc/; ln ../intf/In${mast}_${slav}/S1A${mast}_${satparam}.LED .; ln ../intf/In${mast}_${slav}/S1A${slav}_${satparam}.LED .; ln ../intf/In${mast}_${slav}/S1A${mast}_${satparam}.PRM ${mast}.PRM ; ln ../intf/In${mast}_${slav}/S1A${slav}_${satparam}.PRM ${slav}.PRM; ln ../intf/In${mast}_${slav}/S1A${mast}_${satparam}.LED ${mast}.LED ; ln ../intf/In${mast}_${slav}/S1A${slav}_${satparam}.LED ${slav}.LED"  < /dev/null
#       else
#       ssh -Y $ice "cd /mnt/t31/$ppath/intf; tar -xzvf In${mast}_${slav}.tgz; rm In${mast}_${slav}.tgz; cd ../preproc/; ln ../intf/In${mast}_${slav}/${mast}.PRM . ; ln ../intf/In${mast}_${slav}/${slav}.PRM .; ln ../intf/In${mast}_${slav}/${mast}.LED . ; ln ../intf/In${mast}_${slav}/${slav}.LED ."  < /dev/null
#       fi
       scp ${sat}_${trk}_In${mast}_${slav}.log $t31/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}.out $t31/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}.sub $t31/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}-process.err $t31/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}-process.out $t31/${ppath}/log/
 #   fi
    rm ${sat}_${trk}_In${mast}_${slav}.* ${sat}_${trk}_In${mast}_${slav}-process.*
done < PAIRSmake_check.txt

## remove old data
#ssh -Y ${user}@transfer00.chtc.wisc.edu 'rm -r /mnt/gluster/feigl/insar/${sat}/${trk}/preproc/*'
#ssh -Y ${user}@transfer00.chtc.wisc.edu 'rm /mnt/gluster/feigl/insar/dem/${demf}'

# check that ppath exists and setup directory
#ssh -Y ebaluyut@ice.geology.wisc.edu 'scp ebaluyut@submit-3.chtc.wisc.edu:/home/ebaluyut/PAIRSmake_check.txt /mnt/t31/$ppath/intf/; cd /mnt/t31/$ppath; make untar_in; make plots'
#ssh -Y $ice "scp ${user}@submit-3.chtc.wisc.edu:/home/${user}/PAIRSmake_check.txt /mnt/t31/$ppath/intf/; cd /mnt/t31/$ppath"
scp maule_pairs.lst PAIRSmake_check.txt $t31/$ppath/intf/
