#!/bin/bash
# when run in S1A downloads directory, generates list of orders to date and outputs text file S1A_OrderList.txt
# Elena Reinisch 20161010
# update ECR 20170417 update to incoporate reordering columns, untar new downloads, and update existing epoch list
# update ECR 20170420 update to add in archived scenes
# update ECR 20180327 update for new gmtsar-aux layout


# decide if looking through archives or not
if [[ $# -eq 1 ]]
then
#  if [[ $1 == winsar ]]
#  then
#  
 # if [[ $1 == esa ]]
 # then
 #  ftype=a
 # else
 #  echo "Error, unidentified source type. Use esa."
 #  exit 1
 # fi
  site=$1
  arch=0
elif [[ $# -eq 2 ]]
then
  site=$1
  if [[ $2 == "-a" ]]
  then
    arch=1
  else
    echo "unsupported input. See gen_submitted_order_list_airbus.sh -h"
    exit 1
  fi
elif [[ $# -eq 0 ]]
then
    echo "gen_submitted_order_list_S1A.sh"
    echo "when run in a directory containing order receipts, generates list of orders to date"
    echo "outputs S1A_Orders file with columns of #date site sat track swath frame orbit ascdes status source filename path url"
    echo "Run with 1 argument of site when needing to update epoch list after downloading .gz file to the appropriate downloads directory (e.g., brady)"
    echo "e.g.: ./gen_submitted_order_list_S1A.sh brady"
    echo "Run with second -a argument when needing check if archived files are included (and include if needed)"
    echo "e.g.: ./gen_submitted_order_list_S1A.sh brady -a"
    exit 1
else
  echo "wrong number of inputs. See documentation for help."
  exit 1
fi

ftype=a

# Initialize text files
> OrderList
touch Cancelled_Orders.txt

# Copy TSX Order file to working file if it exists, if not create working file with header
if [[ `ls -d ../S1A_OrderList.txt | wc -l` == 0 ]]
then
  touch Submitted_Orders.txt
  #echo "#date site sat track swath frame orbit ascdes status source filename path url" > Submitted_Orders.txt
else
  cp `ls -d ../S1A_OrderList.txt | tail -1` Submitted_Orders.txt
  cp ../S1A_OrderList.txt ../Archived_OrderLists_tmp/S1A_Orders-`date +%Y%m%d_%H%M`.txt
  sed -i '/#date/d' Submitted_Orders.txt
fi

# get list of receipts 
if [[ $ftype == a ]]
then
ls ssara_search*.kml > OrderList
while read -r a; do
   echo READING FILE $a
    grep \<Placemark\>\<name\> $a | awk -F name\> '{print $2}' | awk '{print $1}' > scene_id.tmp
    while read -r b; do
    #pull info for scene id
    epoch=$b
    echo EPOCH = $epoch
    grep $epoch -A9 $a > scene_info.tmp
    #count number of different data with same epoch (e.g., different frames)
    ncounts=`grep $epoch scene_id.tmp | wc -l`
    echo NCOUNTS = $ncounts 
    for ncount in $(seq 1 $ncounts); do
    echo NCOUNT = $ncount
    # extract information from text file 
    scene_date=`echo $epoch | sed "s/-//g"`
    trk=`grep "Relative orbit" scene_info.tmp | head -${ncount} | tail -1 | awk '{print "T"$3}'`
    sat=S1A
    # make track directory if doesn't exist
    mkdir -p ../${trk}
    mkdir -p ../${trk}/raw
    #site=`grep $sat ~ebaluyut/gmtsar-aux/site_sats.txt | grep $trk | awk '{print $1}'`
    orbit=`grep "Absolute orbit" scene_info.tmp | head -${ncount} | tail -1 | awk '{print $3}'`
    frame=`grep "First Frame" scene_info.tmp  | head -${ncount} | tail -1 | awk '{print $4}'`
    swath=`grep $site ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $trk | awk '{print $4}'`
    url=nan
    echo ORBIT = $orbit
    echo FRAME = $frame
    echo SITE = $site
    echo TRACK = $trk
    echo SWATH = $swath
    # check if date is already in the list
    if [[ `grep $scene_date Submitted_Orders.txt | grep $orbit | grep $frame | wc -l` -gt 0 ]]
    then # if already in list
    echo "ALREADY IN LIST"
    # Check to see if epoch date has passed
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]] 
   then
     # update only if status = P or status = A
     if [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "P" || `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "A" ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
       if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt` ]]
       then
         estatus=C
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find ../${trk}/raw -name "S1A*${scene_date}*${orbit}*" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -maxdepth 1 -name "S1A*${scene_date}*${orbit}*" -type d | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc2=/s21/insar/S1A/${trk}/raw/${dirname}
         data_loc="\/s21\/insar\/S1A\/${trk}\/raw\/${dirname}"
        # orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt |  sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find . -maxdepth 0 -name ${filename}` ]]
       then
         estatus=D
         tar -xzvf ${filename} > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         mv $dirname /s21/insar/S1A/${trk}/raw/
         data_loc="\/s21\/insar\/S1A\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred/
         data_loc2=/s21/insar/S1A/${trk}/raw/${dirname}
        # orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       else 
         estatus=A
        # orbit=nan
       fi
    # check to see if downloaded but metadata missing
     elif [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "D" && (`grep $scene_date Submitted_Orders.txt | awk '{print $12}'` == "nan" || `grep $scene_date Submitted_Orders.txt | awk '{print $7}'` == "nan") ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
     #already untarred and put in raw dir
     #grep "Download URL" scene.tmp | awk '{print $4}'
     if [[ ! -z `find ../${trk}/raw -name "*S1A*${scene_date}*${orbit}*" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -maxdepth 1 -name "*S1A*${scene_date}*${orbit}*" -type d | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/S1A\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/S1A/${trk}/raw/${dirname}
        # orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` 
         nline=`grep $scene_date Submitted_Orders.txt | grep $site | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
      # nor untarred yet
       elif [[ ! -z `find . -maxdepth 0 -name ${filename}` ]]
       then
         estatus=D
         tar -xzvf ${filename} > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/S1A/${trk}/raw/
         data_loc="\/s21\/insar\/S1A\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         #orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`  # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | grep $site | sed -e "s/[^ ]*[^ ]/$estatus/9" | sed -e "s/[^ ]*[^ ]/$data_loc/12" | sed -e "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       fi
     fi
   fi
    

    
   else
    # info for epoch not in list yet; add information
    sat=S1A
    echo NEW TRACK = $trk
    echo ORBIT = $orbit
    #trk=T$(sed "5q;d" scene_info.tmp | awk '{print $1}')
    #frame=
    #orbit=nan
    ascdes=`grep "Flight Direction" scene_info.tmp | awk '{print substr($4,1,1)}'`
    esource=esa
    url=`grep "Download URL" scene_info.tmp | awk '{print $4}'`
    data_loc=nan
  
   # if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 0 ]]
   # then
   #    if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 1 ]]
   #    then
   #       site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $swath | awk '{print $1}'`
   #    else
   #       site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | awk '{print $1}'`
   #    fi
   # else
   #    site=nan
   # fi
   # get order status. P if in future; A if in past
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]]
   then
     if [[ ! -z `grep ${scene_date} Cancelled_Orders.txt` ]]
       then
       estatus=C
         dirname=nan
         data_loc2=nan
         filename=nan
     elif [[ ! -z `find ../${trk}/raw -name "*S1A*${scene_date}*${orbit}*" ` ]]
       then
         echo "Data already in raw directory"
         estatus=D
         dirname=`find ../${trk}/raw -maxdepth 1 -name "*S1A*${scene_date}*${orbit}*" | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         filename=${dirname}.zip
         data_loc="\/s21\/insar\/S1A\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/S1A/${trk}/raw/${dirname}
         #frame=`echo $dirname | awk -F- '{print substr($1, length($1)-3, 4)}'`
        # orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
     elif [[ ! -z `find . -maxdepth 0 -name "S1A*${scene_date}*${orbit}*.zip"` ]]
       then
         echo "data in zip file"
         filename=`find . -maxdepth 0 -name "S1A*${scene_date}*${orbit}*.zip" | awk -F/ '{print $2}'`
         echo FILENAME=$filename
         estatus=D
         unzip ${filename}
         dirname=`echo $filename | awk -F\.zip '{print $1".SAFE"}'`
         mv $dirname /s21/insar/S1A/${trk}/raw/
         data_loc="\/s21\/insar\/S1A\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred/
         data_loc2=/s21/insar/S1A/${trk}/raw/${dirname}
         #frame=`echo $dirname | awk -F- '{print substr($1, length($1)-3, 4)}'`
         #orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
     else 
      estatus=A
     data_loc2=$data_loc
     #frame=nan
     fi
   else
     estatus=P
     data_loc2=$data_loc
     #frame=nan
   fi
    # add line for each site using this data
   grep $sat ~ebaluyut/gmtsar-aux/site_sats.txt | grep $trk > site_sat.tmp
    while read line; do
      site=`echo $line | awk '{print $1}'`
      echo SITE = $site
      swath=`echo $line | awk '{print $4}'`
      echo swath = $swath
      # save information to new text file 
      echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
   done < site_sat.tmp
   rm site_sat.tmp
 fi
  done 
    done < scene_id.tmp
 
 # clean up
   # rm *.tmp

# move kml to Archived_searches
mv $a Archived_searches/
done < OrderList
fi


# if arch = 1 get list of archived dims and TSX directories
if [[ "$arch" == 1 ]]
then
  find /s21/insar/S1A/*/raw -name "S1A*" -type d > s1a.tmp
  while read -r a; do
  data_loc2=$a
  scene_date=`echo $data_loc2 | awk -F/ '{print $(NF)}' | awk -F_  '{print $6}' | awk -FT '{print $1}'`
  path=`echo $data_loc2 | sed 's/../\/s21\/insar\/S1A/'`
  if [[ `grep $path Submitted_Orders.txt | wc -l` -eq 0 ]]
    then
    estatus=D
    dirname=`echo $data_loc2 | awk -F/ '{print $(NF)}'`
    orbit=`echo $data_loc2 | awk -F/ '{print $(NF)}' | awk -F_ '{print $(NF-2)}'`
    sat=S1A
    trk=`echo $data_loc2 | awk -F/ '{print $(NF - 2)}'`
    #frame=`echo $data_loc2 | awk -F/ '{print $(NF)}' | awk -FALPSRP '{print substr($2, 6, 4)}'`
    frame=nan
    ascdes=`grep SCENDING $data_loc2/manifest.safe | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}' | awk '{print substr($1, 1, 1)}'`
    if [[ -z $ascdes ]]
    then
       ascdes=nan
    fi
    esource=esa
    filename=$dirname
    path=`echo $data_loc2 | sed 's/../\/s21\/insar\/S1A/'`
    # add line for each site using this data
   grep $sat ~ebaluyut/gmtsar-aux/site_sats.txt | grep $trk > site_sat.tmp
    while read line; do
      site=`echo $line | awk '{print $1}'`
      echo SITE = $site
      swath=`echo $line | awk '{print $4}'`
      echo swath = $swath
      # save information to new text file
      echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
   done < site_sat.tmp
   rm site_sat.tmp
   fi
  done < s1a.tmp
fi

## remove 1SDV from database for the moment
#sed -i '/_1SDV_/d' Submitted_Orders.txt

# clean up output 
#sort Submitted_Orders.txt | sed '1s/^/#date site sat track swath frame orbit ascdes status source filename path url/' | column -t  > ../S1A_Orders-`date +%Y%m%d_%H%M`.txt
#head -1 Submitted_Orders.txt ; tail -n +2 Submitted_Orders.txt | sort -t : -k1,1 -k2,2n | column -t  > ../S1A_Orders-`date +%Y%m%d_%H%M`.txt
sort Submitted_Orders.txt -o Submitted_Orders.txt
sed -i '1s/^/#date site sat track swath frame orbit ascdes status source filename path url \n/' Submitted_Orders.txt
#column -t Submitted_Orders.txt > ../S1A_Orders-`date +%Y%m%d_%H%M`.txt
column -t Submitted_Orders.txt > ../S1A_OrderList.txt


# change permissions of files for future users
chmod a+r+w+x Submitted_Orders.txt
chmod a+r+w+x OrderList
#chmod a+r+w+x ../S1A_Orders-`date +%Y%m%d_%H%M`.txt
chmod a+r+w+x ../S1A_OrderList.txt
