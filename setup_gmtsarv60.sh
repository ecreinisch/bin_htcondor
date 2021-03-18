#!/usr/bin/env -S bash
# this file: setup_gmtsarv60.sh
# edit 20201106 - Sam added shebang.  Not sure if this is necessary but this is a .sh file

#GMT and GMTSAR
umask 002

#turn off OpenMP multi-threading, so each processe remains single-threaded
export OMP_NUM_THREADS=1

# The following is commented-out because these paths are part of setup.sh that should get sourced by the user prior to this script.
# Setup paths to bin_htcondor, GMT and GMTSAR 
# if this is run on maule or askja, should already be done with >source setup.sh
# if this is run on HTCondor, needs relative paths added?
#export PATH=`pwd`/bin_htcondor:$PATH                    # workflow scripts from Kurt Feigl et al.
#export PATH=`pwd`/this_gmt/bin:$PATH                   # GMT    points to a symbolic link
#export PATH=`pwd`/this_gmt/bin:$PATH                   # GMT    points to a symbolic link
#export PATH=`pwd`/gmtsar/bin:$PATH                     # GMTSAR points to a symbolic link
#export PATH=`pwd`/GMT5SAR5.4/bin:$PATH                 # GMTSAR points to a symbolic link
#export PATH=`pwd`/gmtsar_dependencies/bin:$PATH        # needed for libraries
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/this_gmt/lib64
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`pwd`/gmtsar_dependencies/lib

# For compilation only
#export LIBRARY_PATH=$LIBRARY_PATH:`pwd`/this_gmt/lib64
#export LIBRARY_PATH=$LIBRARY_PATH:`pwd`/gmtsar_dependencies/lib

# save account name for askja
if [[ $USER == "sabatzli" ]]
then
    echo "Sams case"
    # login name is different on remote machine
    askja="batzli@askja.ssec.wisc.edu"
else
    # login name is the same on both machines
    askja=${USER}'@askja.ssec.wisc.edu'
fi
echo askja is: $askja
export askja
#
s12=$askja:/s12
export s12

