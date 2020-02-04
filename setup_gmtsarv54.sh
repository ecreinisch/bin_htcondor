#GMT and GMTSAR
umask 002

export OMP_NUM_THREADS=1
export PATH=`pwd`/bin_htcondor:$PATH                   # scripts from Kurt Feigl
#export PATH=/mnt/gluster/feigl/dtools:$PATH                   # scripts from Kurt Feigl
#export PATH=/mnt/gluster/feigl/templates:$PATH                # scripts from Kurt Feigl
export PATH=`pwd`/this_gmt/bin:$PATH            # GMT    points to a symbolic link
#export PATH=/mnt/gluster/feigl/this_gmt/bin:$PATH            # GMT    points to a symbolic link
export PATH=`pwd`/this_gmt/bin:$PATH            # GMT    points to a symbolic link
export PATH=`pwd`/gmtsar/bin:$PATH              # GMTSAR points to a symbolic link
#export PATH=/mnt/gluster/feigl/gmtsar/bin:$PATH              # GMTSAR points to a symbolic link
#export PATH=/mnt/gluster/feigl/GMT5SAR5.2/bin:$PATH              # GMTSAR points to a symbolic link
export PATH=`pwd`/GMT5SAR5.4/bin:$PATH              # GMTSAR points to a symbolic link
#export PATH=/mnt/gluster/feigl/gmtsar_dependencies/bin:$PATH # needed for libraries
export PATH=`pwd`/gmtsar_dependencies/bin:$PATH # needed for libraries
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/gluster/feigl/this_gmt/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/this_gmt/lib64
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mnt/gluster/feigl/gmtsar_dependencies/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/gmtsar_dependencies/lib

# For compilation only
#export LIBRARY_PATH=$LIBRARY_PATH:/mnt/gluster/feigl/this_gmt/lib64
export LIBRARY_PATH=$LIBRARY_PATH:`pwd`/this_gmt/lib64
#export LIBRARY_PATH=$LIBRARY_PATH:/mnt/gluster/feigl/gmtsar_dependencies/lib
export LIBRARY_PATH=$LIBRARY_PATH:`pwd`/gmtsar_dependencies/lib

#MPI and/or Defmod
#export PATH=/mnt/gluster/feigl/petsc/bin:$PATH
#export PETSC_DIR=/mnt/gluster/feigl/petsc

# save account name for maule
if [[ $USER == "sabatzli" ]]
then
    echo "Sams case"
    # login name is different on remote machine
    maule="batzli@maule.ssec.wisc.edu"
else
    # login name is the same on both machines
    maule=${USER}'@maule.ssec.wisc.edu'
fi
echo maule is: $maule
export maule
#
s21=$maule:/s21
export s21

    
