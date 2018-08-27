#!/bin/bash
# script to generate list of all possible pairs with GMTSAR workflow format
# run in raw directory with RAW subdirectory containing .PRM, .SLC, and .LED files
# Elena C Reinisch 20170119
# edit ECR 20170216 add orbits for TSX, format for easy reading, fix so only new scenes are added
# edit ECR 20170221 change site variable to input because some tracks are shared by separate sites
# edit ECR 20170228 add lines of documentation to be output if no arguments are given
# edit ECR 20170306 incorporate change from raw/RAW to raw, preproc
# edit ECR 20170724 add sorting to creation of RAW.tmp to make sure duplicate data is counted twice for pairlist
# edit ECR 20170828 add frame option for ALOS
# edit ECR 20171109 change inputs from [site] [trk] [epoch list path] [optional frame] to [site] [sat] [trk] [optional frame]; now copies appropriate OrderList from maule to /t31/insar/[sat]/ and pulls relevant information
# edit ECR 20171205 change to S1A steps for newly downloaded data
# edit ECR 20180327 update for new gmtsar-aux layout
# edit ECR 20180604 update for S1A (don't count pairs that are too recent and don't have EOF files yet)
# edit ECR 20180604 add S1B
# edit ECR 20180605 updates for S1B naming convention 
# edit ECR 20180802 allow twins to be recorded
# edit ECR 20180803 make script able to be run on maule
# edit ECR 20180807 add catch for files that don't pre-process successfully
# edit ECR 20180827 clear bline.tmp for each pair to ensure that no measurements get carried over to successive pairs

if [[ $# -eq 0 ]]
then
 echo "Script for generating master pairlist for sat/track/site."
 echo "Args: egenerate_pairlist.sh [site] [sat] [trk] [ALOS optional - frame number]"
 echo "Example:"
 echo "egenerate_pairlist.sh brady TSX T53"
 echo "Example: ALOS from frame 1190"
 echo "egenerate_pairlist.sh malas ALOS T244 1190"
 exit 1
fi

# Initialize arguments and text files
cpwd=`pwd`
site=$1
sat=$2
trk=$3
frame=$4
> RAW.tmp
> missing_preproc.tmp

# determine host machine
servername=$(echo $HOSTNAME | awk -F. '{print $1}')
if [[ ${servername} == "ice" ]]; then
   echo "Currently on ice server. Please log in to porotomo and re-source your setup.sh script before proceeding."
   exit 1
fi

echo "host machine is: " ${servername}

# get epoch list for site, keeping only the scenes that have been downloaded
if [[ ${servername} == "porotomo" ]]; then
   scp $maule:/s21/insar/${sat}/${sat}_OrderList.txt /t31/insar/${sat}/
   elist="/t31/insar/${sat}/${sat}_OrderList.txt"
   rsync -avu --ignore-existing $maule:/s21/insar/${sat}/${trk}/preproc/ .
 #  rsync -avu $maule:/s21/insar/${sat}/${trk}/preproc/${sat}_${trk}_${site}_pairs.txt .
elif [[ ${servername} == "maule" ]]; then
   elist="/s21/insar/${sat}/${sat}_OrderList.txt"
   rsync -avu --ignore-existing $t31/insar/${sat}/${trk}/preproc/ .
 #  rsync -avu $t31/insar/${sat}/${trk}/preproc/${sat}_${trk}_${site}_pairs.txt .
else
   echo "Unrecognize host server name.  Please make sure you are using maule or porotomo servers."
   exit 1
fi 

grep $site $elist | grep $trk | awk '$9 == "D"'| sort -u -k1,1 -k2,2  > RAW.tmp
first_epoch=`head -1 RAW.tmp | awk '{print $1}'`
subswath=`head -1 RAW.tmp | awk '{print $5}'`

# first check that all downloaded data has been preprocessed
while read line; do
 epoch=`echo $line | awk '{print $1}'`
 dirname=`echo $line | awk '{print $12}'`
 if [[ ! -e "${epoch}.PRM" && ! -e "S1A${epoch}_${subswath}.PRM" && ! -e "S1B${epoch}_${subswath}.PRM" ]]
 then
   if [[ $sat == "S1A" ]]; then
     if [[ ${servername} == "porotomo" ]]; then
       scp $maule:/s21/insar/${sat}/aux_poeorb .
       auxepoch=`head -1 aux_poeorb | awk -F_ '{print $8}' | awk -FT '{print $1}'`
       rm aux_poeorb
     else
       auxepoch=`head -1 /s21/insar/${sat}/aux_poeorb | awk -F_ '{print $8}' | awk -FT '{print $1}'`
     fi
     if [[ $epoch -lt $auxepoch ]]; then
        echo "$epoch $dirname" >> missing_preproc.tmp
     else
        sed -i "/${epoch}/d" RAW.tmp
     fi
   elif [[ $sat == "S1B" ]]; then
     if [[ ${servername} == "porotomo" ]]; then
       scp $maule:/s21/insar/${sat}/aux_poeorb_S1B .
       auxepoch=`head -1 aux_poeorb_S1B | awk -F_ '{print $8}' | awk -FT '{print $1}'`
       rm aux_poeorb_S1B
     else
       auxepoch=`head -1 /s21/insar/${sat}/aux_poeorb_S1B | awk -F_ '{print $8}' | awk -FT '{print $1}'`
     fi
     if [[ $epoch -lt $auxepoch ]]; then
        echo "$epoch $dirname" >> missing_preproc.tmp
     else
        sed -i "/${epoch}/d" RAW.tmp
     fi
   else
     echo "$epoch $dirname" >> missing_preproc.tmp
   fi
 fi
done < RAW.tmp

if [[ `cat missing_preproc.tmp | wc -l` -gt 0 ]]
then
  # prepare newdims.lst in ../raw
  > ../raw/newdims.lst
  > ../raw/newraw.lst
  while read -r a b; do
    echo $b >> ../raw/newraw.lst
    echo `echo $b | awk -F/ '{print $(NF)}'` >> ../raw/newdims.lst 
  done < missing_preproc.tmp

  echo "Some data has not been preprocessed yet.  See missing_preproc.tmp for scenes."
  echo "Missing directories are listed in ../raw/newraw.lst. Consider doing the following:"
  case $sat in 
    "S1A")
         echo "For S1A Data:"
         echo "cd ../raw"
         echo "raw2prmslc_S1A.sh [trk] [site]  preproc_porotomo.lst"
         ;;
    "S1B")
         echo "For S1B Data:"
         echo "cd ../raw"
         echo "raw2prmslc_S1B.sh [trk] [site]  preproc_porotomo.lst"
         ;;
     "TSX")
         echo "For TSX Data:"
         echo "cd ../raw"
         if [[ ${servername} == "porotomo" ]]; then
           echo "for i in ""\`""cat"" newraw.lst""\`"";"" do  scp -r""  $""maule:""$""i .; done"
         fi
         echo "raw2prmslc_TSX.sh newdims.lst [site]"
         ;;
     "ALOS")
         echo "For ALOS Data:"
         echo "cd ../raw"
         if [[ ${servername} == "porotomo" ]]; then
           echo "for i in ""\`""cat"" newraw.lst""\`"";"" do  scp -r""  $""maule:""$""i .; done"
         fi
         echo "raw2prmslc_ALOS.sh preproc_porotomo.lst"
         ;;
     "ERS1")
         echo "For ERS1 Data:"
         echo "cd ../raw"
	 #if [[ ${servername} == "porotomo" ]]; then
         #  echo "for i in ""\`""cat"" newraw.lst""\`"";"" do  scp -r""  $""maule:""$""i .; done"
	 #fi
         echo "raw2prmslc_ERS.sh preproc_porotomo.lst"
         ;;
     "ERS2")
         echo "For ERS2 Data:"
         echo "cd ../raw"
         #if [[ ${servername} == "porotomo" ]]; then
         #  echo "for i in ""\`""cat"" newraw.lst""\`"";"" do  scp -r""  $""maule:""$""i .; done"
         #fi
         echo "raw2prmslc_ERS.sh preproc_porotomo.lst"
         ;;
     "ENVI")
         echo "For ENVI Data:"
         echo "cd ../raw"
	 if [[ ${servername} == "porotomo" ]]; then
           echo "for i in ""\`""cat"" newraw.lst""\`"";"" do  scp -r""  $""maule:""$""i .; done"
	 fi
         echo "raw2prmslc_ENVI.sh preproc_porotomo.lst"
         ;;
  esac
  exit 1
else
  rm missing_preproc.tmp
fi

# get environment variables
sat=`head -1 RAW.tmp | awk '{print $3}'`

if [[ $sat == *"ALOS"* ]]
then
  if [[ -z $frame ]]
  then
     echo "optional parameter frame is not defined. Assuming frame is:"
     subswath=`head -1 RAW.tmp | awk '{print $6}'` # assign frame to subswath variable (really satparam)
     echo $subswath
   else 
     echo "forming pair list for frame" $frame
     subswath=$frame
   fi
fi

if [[ $sat == "S1"* ]]
then
  wv=`grep radar_wavelength ${sat}${first_epoch}_${subswath}.PRM | awk '{printf("%0.4f\n", $3)}'`
else
  wv=`grep radar_wavelength $first_epoch.PRM | awk '{printf("%0.4f\n", $3)}'`
fi
if [[ $sat == "ENVI" ]]
then
  wv=0.0562356424
fi
orbdir=`head -1 RAW.tmp | awk '{print $8}'`
dem=`grep $site ~ebaluyut/gmtsar-aux/site_dems.txt | awk '{print $2}'`
## cut down S1A file names to epoch and subswath only
#if [[ "$sat" == "S1A" ]]
#then
 #subswath=`grep $site ~ebaluyut/gmtsar-aux/txt_files/site_sats.txt | grep $sat | grep $trk | awk '{print $4}'`
 #sed -i 's/...$//g' RAW.tmp
 #echo $subswath
 #burst="TBD"
#elif [[ "$sat" == "TSX" ]]
#then
 #odir=`find ../raw -name TSX1_SAR__SSC______*${mast}*.xml | head -1`
 #subswath=`grep beamID= $odir | head -1 | awk -FbeamID= '{print $2}' | sed 's/^.//' | sed 's/..$//'`
 #burst=NAN
#else
 #subswath="NAN"
 #burst="NAN" 
#fi
# initialize pair file if doesn't exist
touch ${sat}_${trk}_${site}_pairs.txt

if [[ `cat ${sat}_${trk}_${site}_pairs.txt | wc -l` == "0" ]]
then
echo "#mast slav orb1 orb2 doy_mast doy_slav dt nan trk orbdir subswath/strip site wv bpar bperp burst sat dem filter_wv processed unwrapped pha_std t_crit t_stat res_mean res_std res_rms user" > ${sat}_${trk}_${site}_pairs.txt
fi

# initialize list of new epochs
> new_epochs.tmp

# get list of epochs not paired yet
while read line; do
 epoch=`echo $line | awk '{print $1}'`
 if [[ `grep $epoch ${sat}_${trk}_${site}_pairs.txt | wc -l` == 0 ]]
 then
   echo $line >> new_epochs.tmp
 fi
# # check to see if data exists; if not, fill in and record pair to tmp list for new slaves
# if [[ `grep $epoch ${sat}_${trk}_${site}_epochs.txt | wc -l` == 0 ]]
# then
#  if [[ "$sat" == "S1A" ]]
#  then
#   depoch=`grep clock_start S1A${epoch}_${subswath}.PRM | awk '{print $3}' |tail -1`
#   orb=`find ../raw -name S1A*${epoch}*.SAFE | awk -F${epoch}T '{print $3}' | awk -F_ '{print $2}'`
#  elif [[ "$sat" == "TSX" ]]
#  then
#   odir=`find ../raw -name T*X1_SAR__SSC______*${epoch}*.xml | head -1`
#   orb=`grep absOrbit $odir | head -1 | awk -FabsOrbit '{print $2}' | sed 's/>//g' | sed 's/..$//'`
#   depoch=`grep clock_start $epoch.PRM | awk '{print $3}' |tail -1`
#  else
#   orb=orb
#   depoch=`grep clock_start $epoch.PRM | awk '{print $3}' |tail -1`
#  fi
#  echo "$epoch $depoch $orb" >> ${sat}_${trk}_${site}_epochs.txt
#  echo $epoch >> new_epochs.tmp
# fi
done < RAW.tmp

#loop through each epoch in list
while read line; do
 mast=`echo $line | awk '{print $1}'`
 if [[ $sat == "S1"* ]]
 then
   mode=`echo $line | awk '{print $11}' | awk -F_ '{print $5}'`
 fi
 # finds all new epochs that are suitable slaves
 awk -v var="$mast" '$(1) >= var' new_epochs.tmp > slav.tmp
 if [[ $sat == "S1"* ]]
 then
   grep $mode slav.tmp > slav_s1.tmp
   mv slav_s1.tmp slav.tmp
 fi

 # pull master epoch ddoy information from PRM files
 if [[ "$sat" == "S1"* ]]
  then
   ddoy_mast=`grep clock_start ${sat}${mast}_${subswath}.PRM | awk '{print $3}' |tail -1 | awk '{printf("%3.12f\n", $1)}'` 
   burst=nan
 else
   ddoy_mast=`grep clock_start $mast.PRM | awk '{print $3}' |tail -1 | awk '{printf("%3.12f\n", $1)}'`
   burst=nan
 fi

 if [[ -z $ddoy_mast ]]; then
   ddoy_mast=nan
 fi

 # get orbit info from epoch list
 orb1=`echo $line | awk '{print $7}'` 
 if [[ -z "$orb1" ]]
 then
  orb1="orb1"
 fi

 # loop through slave epochs
 while read line; do
  slav=`echo $line | awk '{print $1}'`
  # pull slave epoch ddoy information from PRM files
  if [[ "$sat" == "S1"* ]]
   then
    ddoy_slav=`grep clock_start ${sat}${slav}_${subswath}.PRM | awk '{print $3}' |tail -1 | awk '{printf("%3.12f\n", $1)}'`
  else
    ddoy_slav=`grep clock_start $slav.PRM | awk '{print $3}' |tail -1 | awk '{printf("%3.12f\n", $1)}'`
  fi

 if [[ -z $ddoy_slav ]]; then
   ddoy_slav=nan
 fi

  # get orbit info from epoch list
  orb2=`echo $line | awk '{print $7}'`
  if [[ -z "$orb2" ]]
  then
   orb2="orb2"
  fi  

  #get delta days
  ddays=`echo $(( ( $(date -ud "${slav}" +'%s') - $(date -ud "${mast}" +'%s') )/60/60/24 ))`
  echo ddays = $ddays

  # get pair baseline information
  if [[ "${mast}" != "${slav} " ]]; then
    if [[ "$sat" == "S1A" ]]
   then
    SAT_baseline ${sat}${mast}_${subswath}.PRM ${sat}${slav}_${subswath}.PRM > bline.tmp
   elif [[ "$sat" == "S1B" ]]
   then
    ln -s ${sat}${mast}_${subswath}.PRM S1A${mast}_${subswath}.PRM
    ln -s ${sat}${slav}_${subswath}.PRM S1A${slav}_${subswath}.PRM
    ln -s ${sat}${slav}_${subswath}.LED S1A${slav}_${subswath}.LED
    ln -s ${sat}${slav}_${subswath}.LED S1A${slav}_${subswath}.LED
    ln -s ${sat}${slav}_${subswath}.SLC S1A${slav}_${subswath}.SLC
    ln -s ${sat}${slav}_${subswath}.SLC S1A${slav}_${subswath}.SLC
    SAT_baseline ${sat}${mast}_${subswath}.PRM ${sat}${slav}_${subswath}.PRM > bline.tmp
   elif [[ "$sat" == "T"*"X" ]]
   then
     eTSX_baseline.csh $mast.PRM $slav.PRM > bline.tmp
  # elif [[ "$sat" == "ALOS"* ]]
  # then
  #   ALOS_baseline $mast.PRM $slav.PRM > bline.tmp
   else
    SAT_baseline $mast.PRM $slav.PRM > bline.tmp
   fi
  else
    > bline.tmp
  fi
  if [[ `cat bline.tmp | grep B_perpendicular | wc -l` == 0 ]]
  then 
   bpar=nan
   bperp=nan
  else
   bpar=`grep B_parallel bline.tmp | awk '{printf("%#3.1f\n",$3)}'`
   bperp=`grep B_perpendicular bline.tmp | awk '{printf("%#3.1f\n",$3)}'`
  fi

  # print to outfile
  echo $mast $slav $orb1 $orb2 $ddoy_mast $ddoy_slav $ddays NAN $trk $orbdir $subswath $site $wv $bpar $bperp $burst $sat $dem | awk '{printf("%#8d %#8d %#5s %#5s %#3.15f %#3.15f %#5d %#3s %#5s %#1s %#10s %#5s %#5.4f %#6.1f %#6.1f %#5s %#5s %#25s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)}' >> ${sat}_${trk}_${site}_pairs.txt  
  rm bline.tmp
 done < slav.tmp
done < RAW.tmp

# sort file
cat ${sat}_${trk}_${site}_pairs.txt | awk 'NR<2{print $0;next}{print $0| "sort"}' > lst.tmp
column -t lst.tmp > ${sat}_${trk}_${site}_pairs.txt

if [[ "$sat" == "TDX"* ]]
then
  mv ${sat}_${trk}_${site}_pairs.txt TSX_${trk}_${site}_pairs.txt
  sed -i 's/TDX/TSX/g' TSX_${trk}_${site}_pairs.txt
#  mv ${sat}_${trk}_${site}_epochs.txt TSX_${trk}_${site}_epochs.txt 
fi

# clean up 
#rm *.tmp  
