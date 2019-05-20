#!/bin/bash
# script to copy all pairs in PAIRSmake.txt to maule and setup for post processing
# Elena Reinisch 20190520

if [[ $# -eq 0 ]]; then
  echo "pairs2maule.sh insar/[sat]/[trk]/[site]/[dir name]"
  exit 1
fi

# set variables
ppath=$1
user=`echo $HOME | awk -F/ '{print $(NF)}'`
echo $ppath
site=`cat PAIRSmake_check.txt | tail -1 | awk '{print $12}'`
demf=`cat PAIRSmake_check.txt | tail -1 | awk '{print $18}'`
> maule_pairs.lst
# check that ppath exists and setup directory
ssh -Y $maule "mkdir -p /s21/$ppath; cd /s21/$ppath; cp /home/ebaluyut/bin_htcondor/makefile_condor_maule makefile; make setup"
site=`cat PAIRSmake_check.txt | tail -1 | awk '{print $12}'`
ssh -Y $maule "sed -i "/site=/c\site=${site}" /s21/$ppath/makefile"

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
    echo "/s21/insar/${sat}/${trk}/${site}/In${mast}_${slav}.tgz" >> maule_pairs.lst 

    # wrap ssh commands into dev/null to avoid ssh eating up action list
#       if [[ "$sat" == "S1A" ]]
#       then
#       ssh -Y $ice "cd /mnt/t31/$ppath/intf; tar -xzvf In${mast}_${slav}.tgz; rm In${mast}_${slav}.tgz; cd ../preproc/; ln ../intf/In${mast}_${slav}/S1A${mast}_${satparam}.LED .; ln ../intf/In${mast}_${slav}/S1A${slav}_${satparam}.LED .; ln ../intf/In${mast}_${slav}/S1A${mast}_${satparam}.PRM ${mast}.PRM ; ln ../intf/In${mast}_${slav}/S1A${slav}_${satparam}.PRM ${slav}.PRM; ln ../intf/In${mast}_${slav}/S1A${mast}_${satparam}.LED ${mast}.LED ; ln ../intf/In${mast}_${slav}/S1A${slav}_${satparam}.LED ${slav}.LED"  < /dev/null
#       else
#       ssh -Y $ice "cd /mnt/t31/$ppath/intf; tar -xzvf In${mast}_${slav}.tgz; rm In${mast}_${slav}.tgz; cd ../preproc/; ln ../intf/In${mast}_${slav}/${mast}.PRM . ; ln ../intf/In${mast}_${slav}/${slav}.PRM .; ln ../intf/In${mast}_${slav}/${mast}.LED . ; ln ../intf/In${mast}_${slav}/${slav}.LED ."  < /dev/null
#       fi
       scp ${sat}_${trk}_In${mast}_${slav}.log $maule:/s21/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}.out $maule:/s21/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}.sub $maule:/s21/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}-process.err $maule:/s21/${ppath}/log/
       scp ${sat}_${trk}_In${mast}_${slav}-process.out $maule:/s21/${ppath}/log/
 #   fi
    rm ${sat}_${trk}_In${mast}_${slav}.* ${sat}_${trk}_In${mast}_${slav}-process.*
done < PAIRSmake_check.txt

## remove old data
#ssh -Y ${user}@transfer00.chtc.wisc.edu 'rm -r /mnt/gluster/feigl/insar/${sat}/${trk}/preproc/*'
#ssh -Y ${user}@transfer00.chtc.wisc.edu 'rm /mnt/gluster/feigl/insar/dem/${demf}'

# check that ppath exists and setup directory
#ssh -Y ebaluyut@ice.geology.wisc.edu 'scp ebaluyut@submit-3.chtc.wisc.edu:/home/ebaluyut/PAIRSmake_check.txt /mnt/t31/$ppath/intf/; cd /mnt/t31/$ppath; make untar_in; make plots'
#ssh -Y $ice "scp ${user}@submit-3.chtc.wisc.edu:/home/${user}/PAIRSmake_check.txt /mnt/t31/$ppath/intf/; cd /mnt/t31/$ppath"
scp maule_pairs.lst PAIRSmake_check.txt $maule:/s21/$ppath/intf/
