#!/bin/bash
# when run in the ALOS downloads directory, generates list of orders to date outputs text file ALOS_OrderList.txt 
# Elena Reinisch 20161010
# update ECR 20170417 update to incoporate reordering columns, untar new downloads, and update existing epoch list
# update ECR 20170420 update to add in archived scenes
# update ECR 20170913 update to work with scenes that have abs orbit numbers with less than 5 digits
# update ECR 20171109 change order list name to ALOS_OrderList.txt
# update KLF 20171211 delete temp files before starting
# update ECR 20180327 update for new gmtsar-aux layout



# decide if looking through archives or not
if [[ $# -eq 1 ]]
then
  if [[ $1 == asf ]]
  then
   ftype=a
  else
   echo "Error, unidentified source type. Use asf."
   exit 1
  fi
  arch=0
elif [[ $# -eq 2 ]]
then
  if [[ $2 == "-a" ]]
  then
    arch=1
  else
    echo "unsupported input. See gen_submitted_order_list_ALOS.sh -h"
    exit 1
  fi
elif [[ $# -eq 0 ]]
then
    echo "gen_submitted_order_list_ALOS.sh"
    echo "when run in a directory containing order receipts, generates list of orders to date"
    echo "outputs ALOS_Orders file with columns of #date site sat track swath frame orbit ascdes status source filename path url"
    echo "Run with 1 argument of source when needing to update epoch list after downloading .gz file to the appropriate downloads directory (e.g., asf)"
    echo "e.g.: ./gen_submitted_order_list_ALOS.sh asf"
    echo "Run with second -a argument when needing check if archived files are included (and include if needed)"
    echo "e.g.: ./gen_submitted_order_list_ALOS.sh asf -a"
    exit 1
else
  echo "wrong number of inputs. See documentation for help."
  exit 1
fi

# Initialize text files
> OrderList
touch Cancelled_Orders.txt

# Copy TSX Order file to working file if it exists, if not create working file with header
if [[ `ls -d ../ALOS_OrderList.txt | wc -l` == 0 ]]
then
  touch Submitted_Orders.txt
  #echo "#date site sat track swath frame orbit ascdes status source filename path url" > Submitted_Orders.txt
else
  #cp `ls -d ../ALOS_*Orders*.txt | tail -1` Submitted_Orders.txt
  cp `ls -d ../ALOS_OrderList.txt | tail -1` Submitted_Orders.txt
  mv `ls -d ../ALOS_OrderList.txt | tail -1` ../Archived_OrderLists/ALOS_Orders-`date +%Y%m%d_%H%M`.txt
  sed -i '/#date/d' Submitted_Orders.txt
fi

# get list of receipts 
#if [[ $ftype == a ]]
#then
if [[ -e scene_info.tmp ]] 
   then
   rm scene_info.tmp
fi
if [[ -e OrderList ]] 
   then
   rm OrderList      
fi

ls ssara_search*.kml > OrderList
while read -r a; do
    grep \<Placemark\>\<name\> $a | awk -F name\> '{print $2}' |awk -FT '{print $1}' | awk '{print $1}' > scene_id.tmp
    chmod a+w scene_id.tmp
    while read -r b; do
    #pull info for scene id
    epoch=$b
    echo EPOCH = $epoch
    grep $epoch -A9 $a > scene_info.tmp
    chmod a+w scene_info.tmp
    #count number of different data with same epoch (e.g., different frames)
    ncounts=`grep $epoch scene_id.tmp | wc -l`
    echo NCOUNTS = $ncounts 
    for ncount in $(seq 1 $ncounts); do
    echo NCOUNT = $ncount
    # extract information from text file 
    scene_date=`echo $epoch | sed "s/-//g"`
    trk=`grep "Relative orbit" scene_info.tmp | head -${ncount} | tail -1 | awk '{print "T"$3}'`
    # make track directory if doesn't exist
    mkdir -p ../${trk}
    mkdir -p ../${trk}/raw
    orbit=`grep "Absolute orbit" scene_info.tmp | head -${ncount} | tail -1 | awk '{print $3}'`
    frame=`grep "First Frame" scene_info.tmp  | head -${ncount} | tail -1 | awk '{print $4}'`
    echo ORBIT = $orbit
    echo FRAME = $frame
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
       elif [[ ! -z `find ../${trk}/raw -name "ALPSRP*${orbit}*${frame}*" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -maxdepth 1 -name "ALPSRP*${orbit}*${frame}*" -type d | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc2=/s21/insar/ALOS/${trk}/raw/${dirname}
         data_loc="\/s21\/insar\/ALOS\/${trk}\/raw\/${dirname}"
        # orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find . -name ${filename}` ]]
       then
         echo FILENAME=$filename
         estatus=D
         unzip ${filename}
         dirname=`echo $filename | awk -F\.zip '{print $1}'`
         mv $dirname /s21/insar/ALOS/${trk}/raw/
         data_loc="\/s21\/insar\/ALOS\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${file_name} untarred
         data_loc2=/s21/insar/ALOS/${trk}/raw/${dirname}
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
     if [[ ! -z `find ../${trk}/raw -name "*ALPSRP*${orbit}*${frame}*" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -maxdepth 1 -name "*ALPSRP*${orbit}*${frame}*" -type d | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/ALOS\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/ALOS/${trk}/raw/${dirname}
        # orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` 
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
      # nor untarred yet
       elif [[ ! -z `find . -name ${filename}` ]]
       then
         echo FILENAME=$filename
         estatus=D
         unzip ${filename}
         dirname=`echo $filename | awk -F\.zip '{print $1}'`
         mv $dirname /s21/insar/ALOS/${trk}/raw/
         data_loc="\/s21\/insar\/ALOS\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         #orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`  # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed -e "s/[^ ]*[^ ]/$estatus/9" | sed -e "s/[^ ]*[^ ]/$data_loc/12" | sed -e "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       fi
     fi
   fi
    

    
   else
    # info for epoch not in list yet; add information
    sat=ALOS
    echo NEW TRACK = $trk
    echo ORBIT = $orbit
    #trk=T$(sed "5q;d" scene_info.tmp | awk '{print $1}')
    swath=nan #`sed "5q;d" scene_info.tmp | awk '{print $8}'`
    #frame=
    #orbit=nan
    ascdes=`grep "Flight Direction" scene_info.tmp | head -${ncount} | tail -1 | awk '{print substr($4,1,1)}'`
    esource=asf
    url=`grep "Download URL" scene_info.tmp | head -${ncount} | tail -1 | awk '{print $4}'`
    data_loc=nan
    #filename=
  
    if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 0 ]]
    then
       if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 1 ]]
       then
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $swath | awk '{print $1}'`
       else
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | awk '{print $1}'`
       fi
    else
       site=nan
    fi
   # get order status. P if in future; A if in past
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]]
   then
     if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt` ]]
     then
       estatus=C
       dirname=nan
       data_loc2=nan
       filename=nan
      elif [[ ! -z `find ../${trk}/raw -maxdepth 1 -name "ALPSRP*${orbit}*${frame}*" ` ]]
      then
         echo "already in raw directory"
         estatus=D
         dirname=`find ../${trk}/raw -maxdepth 1 -name "ALPSRP*${orbit}*${frame}*" | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         filename=${dirname}.zip
         data_loc="\/s21\/insar\/ALOS\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/ALOS/${trk}/raw/${dirname}
      elif [[ ! -z `find . -name "ALPSRP*${orbit}*${frame}*.zip"` ]]
      then
         filename=`find . -name "ALPSRP*${orbit}*${frame}*.zip" | awk -F/ '{print $2}'`
         echo FILENAME=$filename
         estatus=D
         unzip ${filename}
         dirname=`echo $filename | awk -F\.zip '{print $1}'`
         mv $dirname /s21/insar/ALOS/${trk}/raw/
         data_loc="\/s21\/insar\/ALOS\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred/
         data_loc2=/s21/insar/ALOS/${trk}/raw/${dirname}
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

    # save information to new text file 
   echo SCENEDATE = $scene_date 
   echo SITE = $site
   echo SAT = $sat
   echo tRK = $trk
   echo SWATH = $swath
   echo FRAME = $frame
   echo ORBIT = $orbit
   echo ASCDES = $ascdes
   echo ESTATUS = $estatus
   echo ESOURCE = $esource
   echo FILENAME = $filename
   echo data_loc2 = $data_loc2
   echo URL = $url
   echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
 fi
  done 
    done < scene_id.tmp
 
 # clean up
   # rm *.tmp

done < OrderList
#fi

# if arch = 1 get list of archived dims and TSX directories
if [[ "$arch" == 1 ]]
then
  find ../*/raw -name "ALPSRP*" -type d > alos.tmp
  while read -r a; do
  data_loc2=$a
  scene_date=`grep Img_SceneStartDateTime $data_loc2/*.workreport | awk -F\" '{print $2}' | awk '{print $1}'`
  path=`echo $data_loc2 | sed 's/../\/s21\/insar\/ALOS/'`
  if [[ `grep $path Submitted_Orders.txt | wc -l` -eq 0 ]]
    then
    estatus=D
    dirname=`echo $data_loc2 | awk -F/ '{print $(NF)}'`
    orbit=`echo $data_loc2 | awk -F/ '{print $(NF)}' | awk -FALPSRP '{print substr($2, 1, 5)}'`
    sat=ALOS
    trk=`echo $data_loc2 | awk -F/ '{print $(NF - 2)}'`
    swath=nan
    frame=`echo $data_loc2 | awk -F/ '{print $(NF)}' | awk -FALPSRP '{print substr($2, 6, 4)}'`
    ascdes=`ls $data_loc2/LED* | awk -F_ '{print $(NF)}'`
    esource=asf
    filename=${dirname}.zip
    path=`echo $data_loc2 | sed 's/../\/s21\/insar\/ALOS/'`
    #if [[ $trk == "T53" && $swath == *"008"* ]]
    #then
    #  site=brady
    #else
    #  site=nan
    #fi  
    if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 0 ]]
    then
       if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 1 ]]
       then
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $swath | awk '{print $1}'`
       else
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | awk '{print $1}'`
       fi
    else
       site=nan
    fi
    url=nan
        # save information to new text file
    echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $path $url"  >> Submitted_Orders.txt
   fi
  done < alos.tmp
fi

# clean up output 
#column -t Submitted_Orders.txt | sort | sed '1h;1d;$!H;$!d;G' > ../ALOS_Orders-`date +%Y%m%d_%H%M`.txt
sort Submitted_Orders.txt -o Submitted_Orders.txt
sed -i '1s/^/#date site sat track swath frame orbit ascdes status source filename path url \n/' Submitted_Orders.txt
column -t Submitted_Orders.txt > ../ALOS_OrderList.txt

#rm scene_id.tmp scene_info.tmp alos.tmp

# change permissions of files for future users
chmod a+r+w+x Submitted_Orders.txt
chmod a+r+w+x OrderList
chmod a+r+w+x ../ALOS_OrderList.txt
