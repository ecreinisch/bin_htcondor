#!/bin/bash -vex
#!/usr/bin/env -S bash -x
# 	switches in line above after "bash"
# 	-x  Print commands and their arguments as they are executed.
# 	-e  Exit immediately if a command exits with a non-zero status.
#
# reads a text file containing information on SAR images, forms pairs, writes submit files, and submits the jobs
# Elena C Reinisch, 20160808

# Usage: ~/bin_htcondor/run_pair_DAG_gmtsarv60.sh PAIRSmake.txt <value> ##second argument added for unwrap by batzli 20210308 
# Usage: [the second argument passes through run_pair_gmtsarv60.sh to pair2e.sh]

# edit 20161030 add variables to cut region, change names of output files to include satellite and track
# edit 20170407 add section to copy preproc and dem data from askja if doesn't exist on gluster
# edit 20170425 add check for duplicate preproc data, keep only the correct files based on site
# edit 20170605 add tarring of files and change transfer to home directory on output
# edit 20170616 add tarring of software and change to getting data onto gluster using transfer00
# edit 20170619 add orbits tar for ERS and ENVI
# edit 20170622 add time out allowance for copying from askja to gluster using transfer00; include ssh transfer material; remove file transfer on exit
# edit 20170710 now copy data during directly (no interaction with gluster); add concurrency_limits = SSEC_FTP to submit requirements and add check that cut version of DEM exists on askja
# edit 20171204 add line to require Linux 6 operating systems 
# edit 20180212 no longer require linux 6 OS (not needed)
# edit 20180319 save process.err and process.out for each file
# edit 20180406 update to pull from bin_htcondor repo
# edit 20180510 fix region commands for new get_site_dims.sh
# edit 20200107 port to submit-2:/home/groups/geoscience for sharing 
# edit 20200127 Kurt fix bug that stops run before geocoding
# edit 20200401 Kurt and Sam add switch to submit interactively
# edit 20201106 Sam changed shebang from #!/bin/bash to #!/urs/bin/env -S bash as recommended by TC
# edit 20201202 Sam and Kurt adapt for running on Askja
# edit 20210308 Sam added optional unwrap variable to pass through to pair2e.sh for editing config.tsx.txt file "threshold_snaphu = 0.12" if unset or empty (default = 0)


if [ "$#" -eq 1 ]; then
	unwrap=0
elif [ "$#" -eq 2 ]; then
	unwrap=${2}
else
   echo "usage: this script expects a PAIRSmake.txt file and numerical value for threshold_snaphu"
   echo "$0 PAIRSmake.txt"
   echo "$0 PAIRSmake.txt 0.12"
   exit 0
fi

# set user
user=`echo $HOME | awk -F/ '{print $(NF)}'`

# set filter wavelength
filter_wv=`tail -1 $1 | awk '{print $19}'`

# set cut region in latitude and longitude
site=`tail -1 $1 | awk '{print $12}'`
xmin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $1}'`
xmax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $2}'`
ymin=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $3}'`
ymax=`get_site_dims.sh ${site} 1 | awk -F-R '{print $2}' | awk -F/ '{print $4}'`

### set DEM and make sure cut version of DEM exists on askja
   #echo "check for cut dem on askja"
   #echo ASKJA = $askja
   # get DEM from input file
   demf=`grep dem $1 | tail -1 | awk '{print $18}'`
   echo "demf is $demf"

   #since we are on askja, don't need to ssh to it but just run it. also should current user's bin_htcondor directory -- batzli 20210211 
   #ssh -Y $askja "/home/batzli/bin_htcondor/prepDEMforCondorJob.sh $demf $xmin $xmax $ymin $ymax"  # 20200106 change location to groups folder

   #batzli edited prepDEMforCondorJob.sh for use on Askja 20210211 and set /s12/insar/dem as the main directory
   #~/bin_htcondor/prepDEMforCondorJob.sh $demf $xmin $xmax $ymin $ymax
   prepDEMforCondorJob.sh $demf $xmin $xmax $ymin $ymax

### check variables
   #I believe next will be: 
   #~/bin_htcondor/run_pair_gmtsarv60.sh $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site
   # but some variables are missing: ($satparam) need to find source
   echo "Currently defined Variables:"
   echo "sat=$sat track=$track ref=$ref sec=$sec"
   echo "user=$user" 
   echo "satparam=$satparam"
   echo "dem=$demf"
   echo "filter_wv=$filter_wv"
   echo "xmin=$xmin xmax=$xmax ymin=$ymin ymax=$ymax"
   echo "site=$site"
   echo "unwrap=${unwrap}"
   echo "missing some so lets keep going..."

#the rest of this is for making a .sub file for HTCondor


#if [[ ! -e "/mnt/gluster/feigl/insar/dem/${demf}" ]]
#then
#scp $askja:/s12/insar/condor/feigl/insar/dem/${demf} ${user}@transfer00.chtc.wisc.edu:/mnt/gluster/feigl/insar/dem/
##scp $t31/ebaluyut/scratch/TEST_GMTSAR/insar/dem/${demf} /mnt/gluster/feigl/insar/dem/
#fi

# get software and ssh tar files 
#commented out by batzli 20210211 until we need to move software to htcondor
#tar --exclude='.git' -czf bin_htcondor.tgz -C ${bin_htcondor_home} .
#tar -czf GMT5SAR_v54.tgz -C /home/groups/geoscience GMT5SAR5.4 
#tar -czf ssh.tgz .ssh
#if [[ "$user" != "ebaluyut" ]]
#then
#  cp /home/groups/geoscience/bin_htcondor/setup_gmtsarv54.sh . # ALSO in the tgz
#  cp /home/groups/geoscience/gmtsar_dependencies.tgz .  # 20200106 change location to groups folder
#  cp /home/groups/geoscience/GMT.tgz .                  # 20200106 change location to groups folder
#fi

## check to see that setup_gmtsarv54.sh script exists and has askja login
#if [[ ! -e setup_gmtsarv54.sh ]]
#then
#  echo "Missing setup_gmtsarv54.sh script.  Copy from /home/groups/geoscience and replace askja account name with your own" # 20200106 change location to groups folder
#  exit 1
#elif [[ `grep ${user}@askja.ssec.wisc.edu setup_gmtsarv54.sh | wc -l` -eq 0 ]]
#then
#  subuser=`echo $user | awk '{print substr($1, 3, length($1)-2)}'`
#  if [[ `grep ${subuser}@askja.ssec.wisc.edu setup_gmtsarv54.sh | wc -l` -eq 0 ]]
#  then
#    echo "setup_gmtsarv54.sh is missing your askja account name.  Please update setup_gmtsarv54.sh and re-run script."
#    exit 1
#  else
#    echo "credentials in setup_gmtsarv54.sh script match"
#  fi
#else
#  echo "credentials in setup_gmtsarv54.sh script match"
#fi
#echo subuser now is $subuser

#the following "while read" reads each line and all variables of the PAIRSmake.txt (not all present) to make the .sub file for each pair

# a         b         c      d      e                    f                    g    h    i    j       k          l      m       n      o      p      q    r                       s
# mast      slav      orb1   orb2   doy_mast             doy_slav             dt   nan  trk  orbdir  swath      site   wv      bpar   bperp  burst  sat  dem                     filter_wv   
# 20200415  20210505  54442  60287  105.054610604005006  124.054702444455998  385  NAN  T30  A       strip_004  forge  0.0311  -20.4  6.7    nan    TSX  forge_dem_3dep_10m.grd  80                      


while read -r a b c d e f g h i j k l m n o p q r s; do
# ignore commented lines
    [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
ref=$a
sec=$b
track=$i
filter_wv=$s #added by Kurt and Sam 2021/07/02
sat=$q
if [[ "$sat" == "TDX" ]]
then
  sat="TSX"
fi
satparam=$k
echo "ref=$ref"
echo "sec=$sec"
echo "track=$track"
echo "sat=$sat"
echo "satparam=$satparam"
echo "unwrap=${unwrap}"

echo "we can manually hand-off to:"
echo "now we are running: run_pair_gmtsarv60.sh $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site ${unwrap}"
run_pair_gmtsarv60.sh $sat $track $ref $sec $user $satparam $demf $filter_wv $xmin $xmax $ymin $ymax $site ${unwrap}


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
#while [[ ${tcount} -lt 6 && `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}.tgz | wc -l` -eq 0 ]]
# # ref
# if [[ ! -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}.tgz ]]
# then
#   scp $askja:/s12/insar/${sat}/${track}/preproc/${ref}*.tgz ${user}@transfer00.chtc.wisc.edu:/mnt/gluster/feigl/insar/${sat}/${track}/preproc/
#   # if duplicates, take the one corresponding to this site
#   if [[ `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}*.tgz | wc -l` -gt 1 ]]
#   then
#     # keep file that has correct site identifier if it exists
#     if [[ -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}_${site}.tgz ]]
#      then
#      # make temporary directory to store correct files to and move them to the directory
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}.tgz
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}_${site}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}.tgz
#     else # if file with correct site identifier doesn't exist then take original
#     # keep file that has correct site identifier if it exists
#      mkdir /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep/
#      # remove incorrect files 
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${ref}*.*
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
#  echo "Time out on connection to transfer00.  Please wait and rerun the script in a minute or transfer from askja manually to [username]@transfer00.chtc.wisc.edu"
#  exit 1
#fi
#
# # sece
## allow for 5 time outs before proceeding
#tcount=0
#while [[ ${tcount} -lt 6 && `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}.tgz | wc -l` -eq 0 ]]
# if [[ ! -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}.tgz ]]
# then
#   scp $askja:/s12/insar/${sat}/${track}/preproc/${sec}*.tgz ${user}@transfer00.chtc.wisc.edu:/mnt/gluster/feigl/insar/${sat}/${track}/preproc/
#   # if duplicates, take the one corresponding to this site
#   if [[ `ls /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}*.tgz | wc -l` -gt 1 ]]
#   then
#     # keep file that has correct site identifier if it exists
#     if [[ -e /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}_${site}.tgz ]]
#      then
#      # make temporary directory to store correct files to and move them to the directory
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}.tgz
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}_${site}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}.tgz
#     else # if file with correct site identifier doesn't exist then take original
#     # keep file that has correct site identifier if it exists
#      mkdir /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep
#      mv /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}.tgz /mnt/gluster/feigl/insar/${sat}/${track}/preproc/tmp_keep/
#      # remove incorrect files
#      rm /mnt/gluster/feigl/insar/${sat}/${track}/preproc/${sec}*.*
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
#  echo "Time out on connection to transfer00.  Please wait and rerun the script in a minute or transfer from askja manually to [username]@transfer00.chtc.wisc.edu"
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
   ncpu=1
   memgb=8GB
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

#### build submit script
   ##  IMPORTANT! Require execute servers that have Gluster:
   #Requirements = (Target.HasGluster == true) # OUTDATED AS OF June 2017
   #require linux OS 6 for libnetcdf.so.6 and libhdf5.so.6 # OUTDATED AS OF February 2018
   #requirements = (OpSysMajorVer == 6) # OUTDATED AS OF February 2018

cat > ${sat}_${track}_In${ref}_${sec}.sub << EOF
   universe = vanilla
   # Name the log file:
   log = ${sat}_${track}_In${ref}_${sec}.log

   # Name the files where standard output and error should be saved:
   output = ${sat}_${track}_In${ref}_${sec}.out
   error  = ${sat}_${track}_In${ref}_${sec}.err

   # Specify your executable (single binary or a script that runs several
   #  commands), arguments, and a files for HTCondor to store standard
   #  output (or "screen output").

   #executable = run_pair.sh  
   executable = run_pair_gmtsarv60.sh
   arguments = "${sat} ${track} ${ref} ${sec} ${user} ${satparam} ${demf} ${filter_wv} ${xmin} ${xmax} ${ymin} ${ymax} ${site} ${unwrap}"

   # Pass all environment variables to slot
   getenv = True

   # Specify that HTCondor should transfer files to and from the
   #  computer where each job runs. The last of these lines *would* be
   #  used if there were any other files needed for the executable to run.
   #  This next part needs to be updated to gmtsarv60 and tar commands uncommented above -- batzli 20210211
   transfer_input_files = run_pair_gmtsarv54.sh, bin_htcondor.tgz, setup_gmtsarv54.sh, GMT5SAR_v54.tgz, gmtsar_dependencies.tgz, ssh.tgz, GMT.tgz ${orbittar}

   # additional requirements
   # this will allow us to make sure that you don't have too many jobs transferring data from SSEC at the same time
   concurrency_limits = SSEC_FTP

   # Tell HTCondor what amount of compute resources
   #  each job will need on the computer where it runs.
   #  It's still important to request enough computing resources. The below 
   #  values are a good starting point, but consider your file sizes for an
   #  estimate of "disk" and use any other information you might have
   #  for "memory" and/or "cpus".
   request_cpus = ${ncpu}
   request_memory = ${memgb}
   request_disk = ${ndisk}
   queue
EOF

# cat ${sat}_${track}_In${ref}_${sec}.sub

if [ "$#" -eq 2 ]; then
   echo Now consider running the job interactively by executing the following command 
   echo condor_submit -interactive ${sat}_${track}_In${ref}_${sec}.sub
   echo "Then, once the job has started on the condor slot, issue the following command:"
   echo ./run_pair_gmtsarv60.sh ${sat} ${track} ${ref} ${sec} ${user} ${satparam} ${demf} ${filter_wv} ${xmin} ${xmax} ${ymin} ${ymax} ${site} ${unwrap}
else
   # for no child process
   # edit for running  on askja
   # condor_submit ${sat}_${track}_In${ref}_${sec}.sub
   echo "Created job file named ${sat}_${track}_In${ref}_${sec}.sub for ht_condor "
   ls -l ${sat}_${track}_In${ref}_${sec}.sub
fi

## for child process
## write to DAGMan submit file
#echo "JOB In${ref}_${sec} In${ref}_${sec}.sub" >> run_pair.dag 
done < $1


# end of "while read" loop from above

## for child process
## print every job to DAGMan as a node
#ilist=`ls In*.sub | tr "\n" " " | awk -F. '{print $1}'`
#echo "PARENT $ilist" >> run_pair.dag 
## submit file
#condor_submit_dag run_pair.dag 

#cp In${ref}_${sec}.tgz In_test.tgz 
#scp In_test.tgz ebaluyut@askja.ssec.wisc.edu:/home/ebaluyut/scratch
#rm In_test.tgz

