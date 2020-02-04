#!/bin/bash -evx
# reads a text file containing information on SAR images, forms pairs, writes submit files, and submits the jobs
# Elena C Reinisch, 20160808
# edit 20161030 add variables to cut region, change names of output files to include satellite and track
# edit 20170407 add section to copy preproc and dem data from maule if doesn't exist on gluster
# edit 20170425 add check for duplicate preproc data, keep only the correct files based on site
# edit 20170605 add tarring of files and change transfer to home directory on output
# edit 20170616 add tarring of software and change to getting data onto gluster using transfer00
# edit 20170619 add orbits tar for ERS and ENVI
# edit 20170622 add time out allowance for copying from maule to gluster using transfer00; include ssh transfer material; remove file transfer on exit
# edit 20170710 now copy data during directly (no interaction with gluster); add concurrency_limits = SSEC_FTP to submit requirements and add check that cut version of DEM exists on maule
# edit 20171204 add line to require Linux 6 operating systems 
# edit 20180212 no longer require linux 6 OS (not needed)
# edit 20180319 save process.err and process.out for each file
# edit 20180406 update to pull from bin_htcondor repo
# edit 20180510 fix region commands for new get_site_dims.sh
# edit 20200107 port to submit-2:/home/groups/geoscience for sharing 
# edit 20200127 Kurt fix bug that stops run before geocoding

# ** 20200127 Tricky stuff: save account name for maule
#if [[ $USER == "sabatzli" ]]
#then
#    echo "Sams case"
#    # login name is different on remote machine
#    maule="batzli@maule.ssec.wisc.edu"
#else
#    # login name is the same on both machines
#    maule=${USER}'@maule.ssec.wisc.edu'
#fi
#echo maule is: $maule
#export maule
#
#s21=$maule:/s21
#export s21
#
echo bin_htcondor_home is $bin_htcondor_home
source $bin_htcondor_home/setup_gmtsarv54.sh
# ** end of tricky stuff


# set path save pairs to
user=`echo $HOME | awk -F/ '{print $(NF)}'`
echo user is $user

# set filter wavelength
filter_wv=`tail -1 $1 | awk '{print $19}'`

# set cut region
site=`tail -1 $1 | awk '{print $12}'`
xmin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $1}'`
xmax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $2}'`
ymin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $3}'`
ymax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $4}'`

# set DEM and make sure cut version of DEM exists on maule
echo "check for cut dem on maule"
echo MAULE = $maule
demf=`tail -1 $1 | awk '{print $18}'`
ssh -Y $maule "/home/batzli/bin_htcondor/prepDEMforCondorJob.sh $demf $xmin $xmax $ymin $ymax"  # 20200106 change location to groups folder

#echo stopping here to debug faster
#exit 0


#if [[ ! -e "/mnt/gluster/feigl/insar/dem/${demf}" ]]
#then
#scp $maule:/s21/insar/condor/feigl/insar/dem/${demf} ${user}@transfer00.chtc.wisc.edu:/mnt/gluster/feigl/insar/dem/
##scp $t31/ebaluyut/scratch/TEST_GMTSAR/insar/dem/${demf} /mnt/gluster/feigl/insar/dem/
#fi

# get software and ssh tar files
tar --exclude='.git' -czf bin_htcondor.tgz -C ${bin_htcondor_home} .
tar -czf GMT5SAR_v54.tgz -C /home/groups/geoscience GMT5SAR5.4 
tar -czf ssh.tgz .ssh
if [[ "$user" != "ebaluyut" ]]
then
cp /home/groups/geoscience/bin_htcondor/setup_gmtsarv54.sh . # ALSO in the tgz
cp /home/groups/geoscience/gmtsar_dependencies.tgz .  # 20200106 change location to groups folder
cp /home/groups/geoscience/GMT.tgz .                  # 20200106 change location to groups folder
fi

## check to see that setup_gmtsarv54.sh script exists and has maule login
#if [[ ! -e setup_gmtsarv54.sh ]]
#then
#  echo "Missing setup_gmtsarv54.sh script.  Copy from /home/groups/geoscience and replace maule account name with your own" # 20200106 change location to groups folder
#  exit 1
#elif [[ `grep ${user}@maule.ssec.wisc.edu setup_gmtsarv54.sh | wc -l` -eq 0 ]]
#then
#  subuser=`echo $user | awk '{print substr($1, 3, length($1)-2)}'`
#  if [[ `grep ${subuser}@maule.ssec.wisc.edu setup_gmtsarv54.sh | wc -l` -eq 0 ]]
#  then
#    echo "setup_gmtsarv54.sh is missing your maule account name.  Please update setup_gmtsarv54.sh and re-run script."
#    exit 1
#  else
#    echo "credentials in setup_gmtsarv54.sh script match"
#  fi
#else
#  echo "credentials in setup_gmtsarv54.sh script match"
#fi
#echo subuser now is $subuser

while read -r a b c d e f g h i j k l m n o p q r; do
# ignore commented lines
    [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
mast=$a
slav=$b
track=$i
sat=$q
if [[ "$sat" == "TDX" ]]
then
  sat="TSX"
fi
satparam=$k
echo $mast
echo $slav
echo $track
echo $sat

# add orbits.tgz if ENVI data
if [[ "$sat" == "ENVI"* ]]
then
  orbittar=", orbits_ENVI.tgz"
  cp /home/groups/geoscience/orbits_ENVI.tgz .   # 20200106 change location to groups folder
elif [[ "$sat" == "ERS"* ]]
then
  orbittar=", orbits_ERS.tgz"
  cp /home/groups/geoscience/orbits_ERS.tgz .   # 20200106 change location to groups folder
else
  orbittar=
fi

## check to see if raw data is on gluster; pull from porotomo if needed
## allow for 5 time outs before proceeding
#tcount=0
#while [[ ${tcount} -lt 6 && `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}.tgz | wc -l` -eq 0 ]]
# # mast
# if [[ ! -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}.tgz ]]
# then
#   scp $maule:/s21/insar/${sat}/${track}/preproc/${mast}*.tgz ${user}@transfer00.chtc.wisc.edu:/mnt/gluster/feigl/insar/${sat}/${track}/preproc/
#   # if duplicates, take the one corresponding to this site
#   if [[ `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}*.tgz | wc -l` -gt 1 ]]
#   then
#     # keep file that has correct site identifier if it exists
#     if [[ -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}_${site}.tgz ]]
#      then
#      # make temporary directory to store correct files to and move them to the directory
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}.tgz
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}_${site}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}.tgz
#     else # if file with correct site identifier doesn't exist then take original
#     # keep file that has correct site identifier if it exists
#      mkdir /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep/
#      # remove incorrect files 
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${mast}*.*
#      # move correct files back and remove temporary directory
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep/* /mnt/gluster/feigl/insar/${sat}/${track}/preproc/
#      rm -r /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep
#     fi
#   fi
#   let tcount=tcount+1
# fi
#
## kill process if ssh transfer is timing out
#if [[ ${tcount} -gt 5 ]]
#then
#  echo "Time out on connection to transfer00.  Please wait and rerun the script in a minute or transfer from maule manually to [username]@transfer00.chtc.wisc.edu"
#  exit 1
#fi
#
# # slave
## allow for 5 time outs before proceeding
#tcount=0
#while [[ ${tcount} -lt 6 && `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}.tgz | wc -l` -eq 0 ]]
# if [[ ! -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}.tgz ]]
# then
#   scp $maule:/s21/insar/${sat}/${track}/preproc/${slav}*.tgz ${user}@transfer00.chtc.wisc.edu:/mnt/gluster/feigl/insar/${sat}/${track}/preproc/
#   # if duplicates, take the one corresponding to this site
#   if [[ `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}*.tgz | wc -l` -gt 1 ]]
#   then
#     # keep file that has correct site identifier if it exists
#     if [[ -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}_${site}.tgz ]]
#      then
#      # make temporary directory to store correct files to and move them to the directory
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}.tgz
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}_${site}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}.tgz
#     else # if file with correct site identifier doesn't exist then take original
#     # keep file that has correct site identifier if it exists
#      mkdir /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep/
#      # remove incorrect files
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${slav}*.*
#      # move correct files back and remove temporary directory
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep/* /mnt/gluster/feigl/insar/${sat}/${track}/preproc/
#      rm -r /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep
#     fi
#   fi
#   let tcount=tcount+1
# fi
#
## kill process if ssh transfer is timing out
#if [[ ${tcount} -gt 5 ]]
#then
#  echo "Time out on connection to transfer00.  Please wait and rerun the script in a minute or transfer from maule manually to [username]@transfer00.chtc.wisc.edu"
#  exit 1
#fi

# determine satellite type to select appropriate cpu and memory
if [[ "$sat" == "S1A" ]]
then
   ncpu=5
   memgb=10GB
   ndisk=18GB
elif [[ "$sat" == "TSX" ]]
then
#   if [[ "$track" == "T144" ]]
#   then
#     memgb=8GB
#   else
     memgb=8GB
#   fi
   ncpu=1
   ndisk=15GB
elif [[ "$sat" == "ALOS"* ]]
then
   ncpu=1
   memgb=8GB
   ndisk=18GB
else 
   ncpu=1
   memgb=8GB
   ndisk=15GB
fi

# build submit script
##  IMPORTANT! Require execute servers that have Gluster:
#Requirements = (Target.HasGluster == true) # OUTDATED AS OF June 2017
#require linux OS 6 for libnetcdf.so.6 and libhdf5.so.6 # OUTDATED AS OF February 2018
#requirements = (OpSysMajorVer == 6) # OUTDATED AS OF February 2018

cat > ${sat}_${track}_In${mast}_${slav}.sub << EOF
universe = vanilla
# Name the log file:
log = ${sat}_${track}_In${mast}_${slav}.log

# Name the files where standard output and error should be saved:
output = ${sat}_${track}_In${mast}_${slav}.out
error  = ${sat}_${track}_In${mast}_${slav}.err

# Specify your executable (single binary or a script that runs several
#  commands), arguments, and a files for HTCondor to store standard
#  output (or "screen output").

#executable = run_pair.sh  
executable = run_pair_gmtsarv54.sh
arguments = "$sat $track $mast $slav $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site"
# 201200127 next line is redundant
#output = ${sat}_${track}_In${mast}_${slav}.out

# Pass all environment variables to slot
getenv = True

# Specify that HTCondor should transfer files to and from the
#  computer where each job runs. The last of these lines *would* be
#  used if there were any other files needed for the executable to run.
transfer_input_files = run_pair_gmtsarv54.sh, bin_htcondor.tgz, setup_gmtsarv54.sh, GMT5SAR_v54.tgz,  gmtsar_dependencies.tgz, ssh.tgz,  GMT.tgz ${orbittar}

# additional requirements
# this will allow us to make sure that you don't have too many jobs transferring data from SSEC at the same time
concurrency_limits = SSEC_FTP

# Tell HTCondor what amount of compute resources
#  each job will need on the computer where it runs.
# It's still important to request enough computing resources. The below 
#  values are a good starting point, but consider your file sizes for an
#  estimate of "disk" and use any other information you might have
#  for "memory" and/or "cpus".
request_cpus = ${ncpu}
request_memory = ${memgb}
request_disk = ${ndisk}
queue
EOF
cat ${sat}_${track}_In${mast}_${slav}.sub

# for no child process
condor_submit ${sat}_${track}_In${mast}_${slav}.sub
# 
#echo Now consider running the job interactively by executing the following command 
#echo condor_submit -interactive ${sat}_${track}_In${mast}_${slav}.sub

## for child process
## write to DAGMan submit file
#echo "JOB In${mast}_${slav} In${mast}_${slav}.sub" >> run_pair.dag 
done < $1

## for child process
## print every job to DAGMan as a node
#ilist=`ls In*.sub | tr "\n" " " | awk -F. '{print $1}'`
#echo "PARENT $ilist" >> run_pair.dag 
## submit file
#condor_submit_dag run_pair.dag 

#cp In${mast}_${slav}.tgz In_test.tgz 
#scp In_test.tgz ebaluyut@maule.ssec.wisc.edu:/home/ebaluyut/scratch
#rm In_test.tgz



