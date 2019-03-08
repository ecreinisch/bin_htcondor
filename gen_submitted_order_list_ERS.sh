#!/bin/bash
# when run in ERS downloads directory, generates list of orders to date and outputs text file ERS_OrderList.txt
# Elena Reinisch 20161010
# update ECR 20170417 update to incoporate reordering columns, untar new downloads, and update existing epoch list
# update ECR 20170420 update to add in archived scenes
# udpate ECR 20171109 change order list name to ERS*_OrderList.txt
# update ECR 20180327 update for new gmtsar-aux layout
# update ECR 20190108 update for new WInSAR order query layout


# decide if looking through archives or not
if [[ $# -eq 1 ]]
then
  if [[ $1 == winsar ]]
  then
  ftype=w
  else
   echo "Error, unidentified source type. Use either winsar or airbus"
   exit 1
  fi
  arch=0
elif [[ $# -eq 2 ]]
then
  if [[ $2 == "-a" ]]
  then
    arch=1
  else
    echo "unsupported input. See gen_submitted_order_list_airbus.sh -h"
    exit 1
  fi
elif [[ $# -eq 0 ]]
then
    echo "gen_submitted_order_list_ERS.sh"
    echo "when run in a directory containing order receipts, generates list of orders to date"
    echo "outputs ENVI_Orders file with columns of #date site sat track swath frame orbit ascdes status source filename path url"
    echo "Run with 1 argument of source when needing to update epoch list after downloading .gz file to the appropriate downloads directory (e.g., winsar)"
    echo "e.g.: ./gen_submitted_order_list_ERS.sh winsar"
    echo "Run with second -a argument when needing check if archived files are included (and include if needed)"
    echo "e.g.: ./gen_submitted_order_list_ERS.sh winsar -a"
    exit 1
else
  echo "wrong number of inputs. See documentation for help."
  exit 1
fi

# Initialize text files
> OrderList
touch Cancelled_Orders.txt

# Copy TSX Order file to working file if it exists, if not create working file with header
#if [[ `ls -d ../ERS*_*Orders*.txt | wc -l` == 0 ]]
sat0=`pwd | awk -F/ '{print $4}'`
if [[ `ls -d ../${sat0}_OrderList.txt | wc -l` == 0 ]]
then
  touch Submitted_Orders.txt
  echo "#date site sat track swath frame orbit ascdes status source filename path url" > Submitted_Orders.txt
else
  cp `ls -d ../${sat0}_OrderList.txt | tail -1` Submitted_Orders.txt
  mv `ls -d ../${sat0}_OrderList.txt | tail -1` ../Archived_OrderLists/${sat0}_Orders-`date +%Y%m%d_%H%M`.txt
fi

# get list of receipts 
if [[ $ftype == w ]]
then
ls query-2*.txt > OrderList
while read -r a; do
    if [[ `grep startTime $a | grep Z | wc -l` -eq 0 ]]; then
       newstyle=0
       grep startTime $a | awk '{print $1}' | awk -F\" '{print $(NF)}' > scene_id.tmp
    else # new receipt style
       newstyle=1
       grep startTime $a |sed 's/ //g' | awk '{print $1}' | awk -F\" '{print $(NF-1)}' | awk -FT '{print $1}' > scene_id.tmp
    fi
    while read -r b; do
    #pull info for scene id
    epoch=$b
    echo $epoch
    if [[ $newstyle -eq 0 ]]; then
       grep $epoch -A11 $a > scene_info.tmp
    else
       grep $epoch -A11 $a > scene_info.tmp
       grep $epoch -B2 $a | head -1 >> scene_info.tmp # get download URL, which appears before $epoch in new query format
    fi
    # extract information from text file 
    scene_date=`echo $epoch | sed 's/-//g' | sed 's/ //g'`
    orbit=`grep absoluteOrbit scene_info.tmp | awk -F\: '{print $2}' | awk '{print substr($1, 1, 5)}'`
    if [[ $newstyle -eq 0 ]]; then
      trk=`grep relativeOrbit scene_info.tmp | awk -F\: '{print "T"$2}'`
      sat=`grep satelliteName scene_info.tmp | awk -F\: '{print $2}' | sed 's/-//' | sed 's/"//g'`
    else
      trk=`grep relativeOrbit scene_info.tmp | tail -1 | awk -F\: '{print $2}' | awk -F\} '{print "T"$1}' | sed 's/ //g'`
      sat=`grep platform scene_info.tmp | head -1 | awk -F\: '{print $2}' | sed 's/-//' | sed 's/"//g'  | sed 's/ //g'`
    fi
    if [[ $newstyle -eq 0 ]]; then
      frame=`grep firstFrame scene_info.tmp | awk -F\: '{print $2}'`
    else
      frame=`grep frame scene_info.tmp | head -1 |  awk -F\: '{print $2}' | sed 's/ //g'`
    fi
    # check if date is already in the list
    if [[ `grep $scene_date Submitted_Orders.txt | wc -l` -gt 0 ]]
    then # if already in list
    # Check to see if epoch date has passed
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]] 
   then
     # update only if status = P or status = A
     if [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "P" || `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "A" ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`.tar.gz
       if [[ ! -z `grep ${scene_date} Cancelled_Orders.txt` ]]
       then
         estatus=C
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find ../${trk}/raw -name "ER0*${scene_date}*${orbit}*" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "ER0*${scene_date}*${orbit}*" -type d | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc2=/s21/insar/${sat}/${trk}/raw/${dirname}
         data_loc="\/s21\/insar\/${sat}\/${trk}\/raw\/${dirname}"
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find . -name ${filename}` ]]
       then
         estatus=D
         dirname=`ls -d ER0*${scene_date}*${orbit}*`
         mv $dirname /s21/insar/${sat}/${trk}/raw/
         data_loc="\/s21\/insar\/${sat}\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/${sat}/${trk}/raw/${dirname}
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
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`.tar.gz
     #already untarred and put in raw dir
     #grep "Download URL" scene.tmp | awk '{print $4}'
     if [[ ! -z `find ../${trk}/raw -name "ER0*${scene_date}*${orbit}*" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "ER0*${scene_date}*${orbit}*" -type d | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/${sat}\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/${sat}/${trk}/raw/${dirname}
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
      # nor untarred yet
       elif [[ ! -z `find . -name ER0*${scene_date}*${orbit}*` ]]
       then
         estatus=D
         dirname=`ls -d ER0*${scene_date}*${orbit}*`
         mv $dirname /s21/insar/${sat}/${trk}/raw/
         data_loc="\/s21\/insar\/${sat}\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         nline=`grep $scene_date Submitted_Orders.txt | sed -e "s/[^ ]*[^ ]/$estatus/9" | sed -e "s/[^ ]*[^ ]/$data_loc/12" | sed -e "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       fi
     fi
   fi
    

    
   else
    # info for epoch not in list yet; add information
    echo TRACK = $trk
    echo $scene_date
    echo $orbit
    swath=nan #`sed "5q;d" scene_info.tmp | awk '{print $8}'`
    ascdes=`grep flightDirection scene_info.tmp | awk -F\" '{print $4}'`
    esource=winsar
    url=`grep downloadUrl scene_info.tmp | awk -F\" '{print $4}'`
    data_loc=nan
    #filename=
  
    if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 0 ]]
    then
       if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 1 ]]
       then
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $frame | awk '{print $1}'`
       else
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | awk '{print $1}'`
       fi
    else
       site=nan
    fi
   # get order status. P if in future; A if in past
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]]
   then
     if [[ ! -z `grep ${scene_date} Cancelled_Orders.txt` ]]
     then
       estatus=C
     elif [[ ! -z `find ../${trk}/raw -name "ER0*${scene_date}*${orbit}*" ` ]]
     then
         echo THIS CASE 0
         estatus=D
         dirname=`find ../${trk}/raw -name "ER0*${scene_date}*${orbit}*" | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         filename=${dirname}.tar.gz
         data_loc="\/s21\/insar\/${sat}\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/${sat}/${trk}/raw/${dirname}
         if [[ $newstyle -eq 0 ]]; then
           frame=`grep firstFrame scene_info.tmp | awk -F\: '{print $2}'`
         else
           frame=`grep frame scene_info.tmp | head -1 |  awk -F\: '{print $2}'`
         fi
     elif [[ ! -z `find . -name "ER0*${scene_date}*${orbit}*"` ]]
     then
         echo THIS CASE 1
         estatus=D
         dirname=`ls -d ER0*${scene_date}*${orbit}*`
         filename=${dirname}.tar.gz
         echo $dirname
         mv $dirname /s21/insar/${sat}/${trk}/raw/
         data_loc="\/s21\/insar\/${sat}\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/${sat}/${trk}/raw/${dirname}
         if [[ $newstyle -eq 0 ]]; then
           frame=`grep firstFrame scene_info.tmp | awk -F\: '{print $2}'`
         else
           frame=`grep frame scene_info.tmp | head -1 |  awk -F\: '{print $2}'`
         fi
     else 
       echo CASE 2
       estatus=A
       data_loc2=$data_loc
         if [[ $newstyle -eq 0 ]]; then
           frame=`grep firstFrame scene_info.tmp | awk -F\: '{print $2}'`
         else
           frame=`grep frame scene_info.tmp | head -1 |  awk -F\: '{print $2}'`
         fi
     fi
   else
     estatus=P
     data_loc2=$data_loc
         if [[ $newstyle -eq 0 ]]; then
           frame=`grep firstFrame scene_info.tmp | awk -F\: '{print $2}'`
         else
           frame=`grep frame scene_info.tmp | head -1 |  awk -F\: '{print $2}'`
         fi
   fi

    # save information to new text file 
   echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
 fi 
    done < scene_id.tmp
 
 # clean up
   # rm *.tmp

done < OrderList
fi

# if arch = 1 get list of archived dims and ERS directories
if [[ "$arch" == 1 ]]
then
  find ../*/raw -name "ER*.CEOS" -type d > ers.tmp
  while read -r a; do
  data_loc2=$a
  scene_date=`echo $data_loc2 | awk -F_ '{print $5}' | awk -FT '{print $1}'`
  cpwd=`pwd | awk -F\/downloads '{print $1}'`
  path=`echo $data_loc2 | sed 's/../${cpwd}/'`
  if [[ `grep $path Submitted_Orders.txt | wc -l` -eq 0 ]]
    then
    estatus=D
    dirname=`echo $data_loc2 | awk -F/ '{print $(NF)}'`
    orbit=`echo $data_loc2 | awk -F_ '{print $NF}' | awk -F\. '{print $1}'`
    sat=`echo $cpwd | awk -F\/ '{print $(NF)}'`
    trk=`echo $data_loc2 | awk -F/ '{print $(NF - 2)}'`
    swath=nan
    frame=nan
    ascdes=nan
    esource=archvd
    filename=$dirname
    if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 0 ]]
    then
       if [[ `grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | wc -l` -gt 1 ]]
       then
          site=`grep $trk ~ebaluyut/gmtsar-aux/site_sats.txt | grep $sat | grep $frame | awk '{print $1}'`
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
  done < ers.tmp
fi

sat=`echo $sat | sed 's/ //g'`

# clean up output 
#column -t Submitted_Orders.txt | sort | sed '1h;1d;$!H;$!d;G' > ../${sat}_Orders-`date +%Y%m%d_%H%M`.txt
column -t Submitted_Orders.txt | sort | sed '1h;1d;$!H;$!d;G' > ../${sat}_OrderList.txt
