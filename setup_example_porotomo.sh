# Make files readable and writable to others using workflow
umask 002

# set location of Workflow repo
export bin_htcondor_home='~ebaluyut/bin_htcondor'

#GMT and GMTSAR
export OMP_NUM_THREADS=1

# define alias for Matlab 2017b
alias matlab17='/usr/local/matlab.r2017b/bin/matlab'

# add shell scripts and metdata for workflow to path
export PATH=/t31/ebaluyut/gmtsar-aux:$PATH
export PATH=/t31/ebaluyut/SSARA-master:$PATH

# add GMT/GMTSAR to path
export PATH=/t31/stali/gmt/bin:$PATH
export PATH=/t31/stali/gmtsar/bin:$PATH
export PATH=/t31/stali/gmtsar_dependencies/bin:$PATH
export PATH=/t31/stali/gmt/lib64:$PATH
export PATH=/t31/stali/gmtsar_dependencies/lib:$PATH
export LD_LIBRARY_PATH=/t31/stali/gmt/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/t31/stali/gmtsar_dependencies/lib:$LD_LIBRARY_PATH

# For compilation only
export LIBRARY_PATH=/t31/stali/gmt/lib64:$LIBRARY_PATH
export LIBRARY_PATH=/t31/stali/gmtsar_dependencies/lib:$LIBRARY_PATH

# For Elena's scripts
export PATH=/usr/bin:$PATH
export PATH=/usr/sbin:$PATH
export PATH=${bin_htcondor_home}:$PATH

# Environment variables set for each user of HTCondor workflow
export submit3='' #'feigl@submit-3.chtc.wisc.edu'
export maule='' # 'feigl@maule.ssec.wisc.edu'

# export SAR credentials
export unavuser=''
export unavpass=''

export asfuser=''
export asfpass=''

export eossouser=''
export eossopass=''

#set Python Path
export PYTHONPATH=/home/ebaluyut/SSARA-master:$PYTHONPATH
export PYTHONPATH=${bin_htcondor_home}:$PYTHONPATH

#MPI and/or Defmod
export PETSC_DIR=/t31/stali/petsc
