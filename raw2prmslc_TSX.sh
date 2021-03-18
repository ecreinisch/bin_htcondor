#!/bin/bash -vex
# compiles TSX raw data and submits gmtsar preprocess command to get SLC and PRM files.  Outputs in calendar date naming scheme
# MAKE SURE TO RUN SOURCE /home/batzli/setup.sh AND ARE IN BASH SHELL
# edit 20170216 ECR remove dimlist option
# edit 20170425 ECR change to one list regardless of directory naming convention
# edit 20170504 ECR and Kurt Feigl
# update ECR 20180803 update to run on maule server
# update ECR 20180813 fix definition of maule_path for maule server
# update ECR 20190520 update ice to hengill
# update SAB 20201102 added askja as server name
# update Sam and Kurt 20201214 reworking for GMTSARv6 (comments and considering selection of events) 

if [[ $# -eq 0 ]]
then
 echo "compiles TSX raw data and submits gmtsar preprocess command to get SLC and PRM files.  Outputs in calendar date naming scheme"
 echo "run in raw directory; outputs to ../preproc. Files are also copied to maule"
 echo "raw2prmslc_TSX.sh [list of directories] [site] [w (optional to overwrite existing files)]" 
 exit 1
fi

#rawlst is a list of directory names (e.g. /s12/insar/TSX/T91/raw/TDX1_SM_091_strip_005_20201114014508)
rawlst=$1
#site is a five lowercase letter code needed here to differentate different sites that may be in the same track
site=$2
#overwrite = "w" will overwrite existing data
overwrite=$3

# determine host machine
servername=$(echo $HOSTNAME | awk -F. '{print $1}')
if [[ ${servername} == "hengill" ]]; then
   echo "Currently on hengill server. Please log in to porotomo and re-source your setup.sh script before proceeding."
   exit 1
elif [[ ${servername} != "porotomo" && ${servername} != "maule" && ${servername} != "askja" ]]; then
   echo "Unrecognized host server name.  Please make sure you are on maule, askja or porotomo."
   exit 1
fi

# get track information to copy to appropriate directory on maule
if [[ ${servername} == "porotomo" ]]; then
   maule_path=`echo $(pwd) | awk -F/t31/ '{print "/s21/"$2}' | awk -Fraw '{print $1"preproc/"}'` 
elif [[ ${servername} == "maule" ]]; then
   maule_path=`echo $(pwd) | awk -F/raw '{print $1"/preproc/"}'`
elif [[ ${servername} == "askja" ]]; then
   maule_path=`echo $(pwd) | awk -F/raw '{print $1"/preproc/"}'`
fi
echo $maule_path

#while read -r i; do
# a=`ls $i/T*-1.SAR.L1B/T*/*.xml`
# b=`ls $i/T*-1.SAR.L1B/T*/IMAGEDATA/*.cos`
# c=`echo "${a}" | cut -c71-78`
# make_slc_tsx $a $b $c 
## scp -r $i $maule:${maule_path}
#done < $dimList

# loop over list of data directories ($rawlst)
while read -r i; do
 # get name of xml file
 a=`ls $i/T*-1.SAR.L1B/T*/*.xml`
 # get name of  image data
 b=`ls $i/T*-1.SAR.L1B/T*/IMAGEDATA/*.cos`
# c=`echo "${a}" | cut -c80-87`
 # assign name of preprocessed dat to epoch date unless there is duplicate data (then add site name)
 c=`echo "${a}" | awk -F/ '{print $(NF)}' | awk -FT '{print $2}' | awk -F_ '{print $(NF)}'`
 c_tar=$c
 # check to see if epoch exists from different source. If it does, name this one with site id
 if [[ -e ../preproc/${c}.PRM ]]
 then
   if [[ -z $site ]]
   then
     echo "Preprocessed data already exists for this date.  Rerun script with second argument of site"
     exit 1
   elif [[ $overwrite = *"w"* ]]
   then
     c_tar=`echo "${a}" | awk -F/ '{print $(NF)}' | awk -FT '{print $2}' | awk -F_ '{print $(NF)}'`
   else
     c_tar=${c}_${site}
   fi
 fi

# run binary exicutible
#Usage: make_slc_tsx name_of_xml_file name_of_image_file name_output
#Example: make_slc_s1a TSX1_SAR__SSC______SM_S_SRA_20120615T162057_20120615T162105.xml IMAGE_HH_SRA_strip_007.cos TSX_HH_20120615
#Output: TSX_HH_20120615.SLC TSX_HH_20120615.PRM TSX_HH_20120615.LED
echo "xml file is " $a
echo "image data is " $b
echo "name of output is " $c
make_slc_tsx $a $b $c

# $a is the XML full file name
tar -czvf ${c_tar}.tgz $c.PRM $c.SLC $c.LED $a

if [[ ${servername} == "porotomo" ]]; then
  scp ${c_tar}.tgz $maule:${maule_path}
  #  rm ${c_tar}.tgz 
  #  rm -r $i
else
  mv ${c_tar}.tgz ${maule_path}
fi

done < $rawlst #$TList

mkdir -p ../preproc

# copy new files to maule
#scp *.LED *.SLC *.PRM $maule:${maule_path}
\mv -fv *.LED *.SLC *.PRM ../preproc
