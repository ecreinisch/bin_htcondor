#!/bin/bash
# run a check for duplicate pairs and  suggest reorganization scheme
# run in site directory (e.g., /t31/insar/TSX/brady/)
# Elena C Reinisch 20180320
# update ECR 20180327 update for new gmtsar-aux layout

if [[ $# -eq 0 ]]; then
  echo "script to run a check for duplicate pairs and  suggest reorganization scheme"
  echo "searches for most recent version of successful run (existence of drhomaskd_utm.grd)  based on filter wavelength and DEM (currently specified in site_dems.txt)"
  echo "names of pairs that do not match in processing filter wavelength or DEM are saved to ignoredfiles.tmp and not considered further"
  echo "paths to most recent successful pairs are saved to pairs_keep.txt and corresponding PAIRSmake_check data are saved to PAIRSmake_check_keep.txt"
  echo "paths to older versions of successful pairs are saved to pairs_dupl.txt"
  echo "run in site directory (e.g., /t31/insar/TSX/brady/)"
  echo "usage: check_for_dupl_pairs.sh [filter wavelength] [sat in lowercase letters] [site]" 
  echo "e.g.: check_for_dupl_pairs.sh 80 tsx brady" 
  exit 1
fi

# set variables
wavelength=$1
sat=$2 # enter in lowercase
site=$3
demf=`grep $site ~ebaluyut/gmtsar-aux/site_dems.txt | awk '{print $2}'`

# get list of all files which match directory order, wavelength, and DEM
#find . -name drhomaskd_utm.grd > allfiles.tmp # consider all files regardless of directory level
#find . -maxdepth 4 -name drhomaskd_utm.grd > allfiles.tmp # consider only files at [dir]/[intf]/[pair] level
> ignoredfiles.tmp
> checkedfiles.tmp
for file in $(find . -maxdepth 4 -name drhomaskd_utm.grd); do
  pairdir=$(echo ${file} | awk -F/drho '{print $1}')
  intfdir=$(echo ${pairdir} | awk -F/In '{print $1}')
  mast=$(echo $pairdir | awk -F/In '{print $(NF)}' | awk -F_ '{print $1}')
  slav=$(echo $pairdir | awk -F/In '{print $(NF)}' | awk -F_ '{print $2}')
  # check that appropriate files exist and wavelength and DEM match
  if [[ -e ${pairdir}/config.${sat}.txt && -e ${intfdir}/PAIRSmake_check.txt && $(grep $mast ${intfdir}/PAIRSmake_check.txt | grep $slav | awk '{print $18}') == $demf && $(grep $mast ${intfdir}/PAIRSmake_check.txt | grep $slav | awk '{print $19}') == $wavelength ]]; then
    echo ${file} >> checkedfiles.tmp
  else
    echo ${file} >> ignoredfiles.tmp
  fi
done

# get unique pairs
cat checkedfiles.tmp | awk -F/drho '{print $1}' | awk -F/ '{print $(NF)}' | sort -u > pairs.tmp 

# for each pair, find the most recent unique file and save 
echo "#mast slav orb1 orb2 dmast dslav jdmast jdslav trk orbdir swath site wv bpar bperp burst sat dem processed unwrapped pha_std t_crit t_stat res_mean res_std res_nu user" > PAIRSmake_check_keep.tmp
> pairs_keep.txt
> pairs_dupl.txt

while read -r pair; do
  echo PAIR is $pair
  mast=$(echo $pair | awk -F_ '{print $1}' | awk -FIn '{print $2}')
  slav=$(echo $pair | awk -F_ '{print $2}')
  # keep most recent file
  ls -tl $(cat checkedfiles.tmp | grep ${pair}) | head -1 | awk '{print $NF}' | awk -F/drho '{print $1}' >> pairs_keep.txt
  # print older files to dupl list
  ls -tl $(cat checkedfiles.tmp | grep ${pair}) | tail -n+2 | awk '{print $NF}' | awk -F/drho '{print $1}' >> pairs_dupl.txt  
  # print pairs check info for saved pair to new PAIRSmake_check 
  #more $(ls -tl $(cat checkedfiles.tmp | grep ${pair}) | head -1 | awk '{print $NF}' | awk -F/intf '{print $1"/intf/PAIRSmake_check.txt"}') | grep $mast | grep $slav >> PAIRSmake_check_keep.txt
  pairsmakefile=$(tail -1 pairs_keep.txt | awk -FIn '{print $1"PAIRSmake_check.txt"}')
  cat ${pairsmakefile} |  grep $mast | grep $slav >> PAIRSmake_check_keep.tmp
done < pairs.tmp

# clean up
column -t PAIRSmake_check_keep.tmp > PAIRSmake_check_keep.txt

rm pairs.tmp PAIRSmake_check_keep.tmp
