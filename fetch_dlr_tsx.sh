#!/bin/bash
#
# Use this script to fetch the "delivered" DLR TSX files when
# notified by email.  This requires an argument to be added for 
# the desiered filename (cut and paste from email)
#
# Sam Batzli 2017-03-15 original Airbus script
# Sam Batzli 2019-01-05 modified Airbus script for DLR data
#
# things to add: modify the nohup output
#                check to see if file already downloaded
#                warn if file already exists offer -f to force overwrite (necessary?)
#                make one script with argument to do Airbus or DLR
#


# if no argument is supplied, display usage 
display_usage() {
        echo "Please provide a file name to download from DLR." 
        echo "Example: fetch_dlr_tsx.sh dims_op_oc_dfd2_578204172_1.tar.gz" 
        }

if [  $# -le 0 ] 
	then 
	display_usage
	exit 1
fi

echo "Downloading $1"
# create a placeholder for the new file
touch $1
# make the new file group writable
chmod 664 $1
# download the new file
nohup curl -v -o $1 --ftp-ssl --user feigl_RES1236:Winter2023! --insecure ftp://cassiopeia.caf.dlr.de/$1 &
# nohup curl -v -o $1 --ftp-ssl --user feigl_RES1236:140b68b8 --insecure ftp://cassiopeia.caf.dlr.de/$1 &
