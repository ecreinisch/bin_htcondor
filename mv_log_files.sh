#!/bin/bash
# Elena C Reinisch 20180319
# moves CHTC job log files from log folder to specific pair folder after pairs have been copied and untarred from maule. Run using makefile using after untar_in 

# get location
cwd=$(pwd | awk -F/log '{print $1}')

# get list of interferogram directories
ls -d ../intf/In*/ | awk -F/ '{print $(NF-1)}' > InList.tmp

while read -r pair; do
  # check if files exist for pair, ignoring sym links
  if [[ `find . -type f -name "*${pair}*" | wc -l` -gt 0 ]]; then
    find . -type f -name "*${pair}*" | awk -F/ '{print $(NF)}'  > files.tmp
    #move each file separately and make symbolic link from file in pair dir to log dir
    while read -r filet; do
      mv ${filet} ../intf/${pair}/
      #ln -s ${cwd}/intf/${pair}/${filet} .
      # use relative path name
      ln -s ../intf/${pair}/${filet} .
    done < files.tmp 
    rm files.tmp
   # if files don't exist
   else
     echo "no log files exist in log directory for pair ${pair}.  Check if log files are already in ../intf/${pair}"
   fi
done < InList.tmp

# clean up
rm InList.tmp 
