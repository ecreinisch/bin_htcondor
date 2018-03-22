#!/bin/bash
# script that will pull orbital files for S1A data
# 20170109 Elena C Reinisch, based off of notes from S. Tabrez Ali
# edit ECR 20170217 use date function to pull exact orbital information
# edit ECR 20170220 take input of list of new SAFE directories
# edit ECR 20170425 now moves EOF file to SAFE dir
# edit ECR 20180322 automatically runs update_auxpoeorb.sh to make sure file is up to date

# get list of new SAFE directories
SAFElst=$1
> new_raw.lst

# check to see if aux_poeorb exists
touch /s21/insar/S1A/aux_poeorb
if [[ `cat /s21/insar/S1A/aux_poeorb | wc -l` == "0" ]]
then
#wget https://www.unavco.org/data/imaging/sar/lts1/winsar/s1qc/aux_poeorb
  gen_auxpoeorb.sh
else
  update_auxpoeorb.sh
fi

# get epoch date 

# pull orbit file for each epoch
while read -r a; do
# get epoch date 
  epochdate=`echo $a | cut -c34-41`
  echo EPOCH is $epochdate
  orbitdate=`date -d "$epochdate -1 days" +%Y%m%d`
  echo $orbitdate
  orbitfile=`grep V${orbitdate}T /s21/insar/S1A/aux_poeorb | head -1`
  echo ORBITFILE = $orbitfile
  #wget https://www.unavco.org/data/imaging/sar/lts1/winsar/s1qc/aux_poeorb/${orbitfile}
  echo DIR is $a
  if [[ ! -e ${a}/${orbitfile} ]] 
  then
  wget --no-check-certificate https://qc.sentinel1.eo.esa.int/aux_poeorb/${orbitfile} -O $a/${orbitfile}
  # save name to text file
  echo "$a $orbitfile" >> new_raw.lst
  fi
  #echo "$a $orbitfile" >> new_raw.lst
done < $SAFElst

# clean up 
rm -f index.html*
