#!/bin/bash
# when run in a directory containing order receipts, generates list of orders to date and prints to TSX_OrderList.txt
# Elena Reinisch 20161010
# update ECR 20170417 update to incoporate reordering columns, untar new downloads, and update existing epoch list
# update ECR 20170420 update to add in archived scenes
# update ECR 20171109 change name of Order List to TSX_OrderList.txt
# update ECR 20180327 update for new gmtsar-aux layout
# update ECR 20180802 check for missing prepended 0s for order IDs in receipts, adjust as necessary 
# update ECR 20190104 update to incorporate new geoportal receipts 


# decide if looking through archives or not
if [[ $# -eq 1 ]]
then
  if [[ $1 == winsar ]]
  then
  ftype=w
  elif [[ $1 == airbus ]]
  then
   ftype=a
  else
   echo "Error, unidentified source type. Use either winsar or airbus"
   exit 1
  fi
elif [[ $# -eq 2 ]]
then
  if [[ $1 == winsar ]]
  then
  ftype=w
  elif [[ $1 == airbus ]]
  then
   ftype=a
  else
   echo "Error, unidentified source type. Use either winsar or airbus"
   exit 1
  fi
  if [[ $2 == "-a" ]]
  then
    arch=1
  else
    echo "unsupported input. See gen_submitted_order_list_airbus.sh -h"
    exit 1
  fi
elif [[ $# -eq 0 ]]
then
    echo "gen_submitted_order_list_TSX.sh"
    echo "when run in a directory containing order receipts, generates list of orders to date"
    echo "outputs TSX_Orders file with columns of #date site sat track swath frame orbit ascdes status source filename path url"
    echo "Run with 1 argument of source when needing to update epoch list after downloading .gz file to the appropriate downloads directory (e.g., airbus or winsar)"
    echo "Output will include content of most recent ../TSX_Orders*.txt file"
    echo "e.g.: ./gen_submitted_order_list_TSX.sh airbus"
    echo "Run with second -a argument when needing check if archived files are included (and include if needed)"
    echo "e.g.: ./gen_submitted_order_list_TSX.sh winsar -a"
    exit 1
else
  echo "wrong number of inputs. See documentation for details."
  exit 1
fi

# Initialize text files
> OrderList

# Copy TSX Order file to working file if it exists, if not create working file with header
if [[ `ls -d ../TSX_OrderList.txt | wc -l` == 0 ]]
then
  touch Submitted_Orders.txt
  #echo "#date site sat track swath frame orbit ascdes status source filename path url" > Submitted_Orders.txt
else
  cp `ls -d ../TSX_OrderList.txt | tail -1` Submitted_Orders.txt
  mv `ls -d ../TSX_OrderList.txt | tail -1` ../Archived_OrderLists/TSX_Orders-`date +%Y%m%d_%H%M`.txt
  sed -i '/#date/d' Submitted_Orders.txt
fi

## AIRBUS ORDERS
# get list of receipts 
if [[ $ftype == a ]]
then
ls A*.pdf > OrderList
while read -r a; do
    # convert pdf of receipt to text file
    pdftotext -raw "$a" order.tmp
    order_number=`grep "Sales Order Number"  order.tmp | awk '{print $4}'`

    # get list of scene ids
    # get scene ids based on order number, remove -- lines, empty lines, and Page number lines
    grep $order_number -A1 order.tmp | sed "/$order_number/d" | sed "/--/d" | sed '1d' | sed '/^\s*$/d' | sed '/Page/d' > scene_id.tmp

    while read -r b; do

    #pull info for scene id
    echo $b
    grep $order_number -A 5 order.tmp | grep "\<$b\>" -A 4 > scene_info.tmp
    full_order_number=`grep ${order_number}_ order.tmp | head -1`
    # pad filename with zeros if needed for new Airbus orders
    if [[ $(echo $full_order_number | wc -c) -eq 7 ]]; then
       full_order_number="0000"${full_order_number}
    fi 

    filename=SO_${full_order_number}${b}_1.tar.gz

    # extract information from text file 
    scene_date=`sed "3q;d" scene_info.tmp | sed "s/-//g"`
    trk=T$(sed "5q;d" scene_info.tmp | awk '{print $1}')
    swath=`sed "5q;d" scene_info.tmp | awk '{print $8}'`
    if [[ `grep $scene_date Submitted_Orders.txt | grep $filename |wc -l` -gt 0 ]]
    then
    # make sure that source says winsar
    sed -i 's/[^ ]*[^ ]/airbus/10' Submitted_Orders.txt
    # Update Order status. P if in future; A if in past
    # Check to see if epoch date has passed
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]] 
   then
     # update only if status = P or status = A
     if [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "P" || `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "A" ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
       if [[ `grep ${scene_date} ../Cancelled_Orders.txt | grep $(echo $trk | awk -FT '{print $2}') | grep $( echo ${swath} | sed 's/D//' | sed 's/R//') | wc -l` -gt 0 ]]
       then
         estatus=C
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find ../${trk}/raw -name "*${scene_date}*.xml" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find . -name ${filename}` ]]
       then
         estatus=D
         tar -xzvf ${filename} > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred/
         mv ${filename} untarred/        #changed file_name to filename and added / to fix mv error -- sab 11/10/2017
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       else 
         estatus=A
         orbit=nan
       fi
    # check to see if downloaded but metadata missing
     elif [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "D" && (`grep $scene_date Submitted_Orders.txt | awk '{print $12}'` == "nan" || `grep $scene_date Submitted_Orders.txt | awk '{print $7}'` == "nan") ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
     #already untarred and put in raw dir
     if [[ ! -z `find ../${trk}/raw -name "*${scene_date}*.xml" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | head -1 |  awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` 
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
      # nor untarred yet
       elif [[ ! -z `find . -name ${filename}` ]]
       then
         estatus=D
         tar -xzvf ${filename} > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred/  #changed file_name to filename and added / to fix mv error -- sab 11/10/2017
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`  # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed -e "s/[^ ]*[^ ]/$estatus/9" | sed -e "s/[^ ]*[^ ]/$data_loc/12" | sed -e "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       fi
     fi
   fi
    


   else
    # info for epoch not in list yet; add information
    echo SCENE_DATE = $scene_date
    sat=TSX
    trk=T$(sed "5q;d" scene_info.tmp | awk '{print $1}')
    swath=`sed "5q;d" scene_info.tmp | awk '{print $8}'`
    frame=nan
    orbit=nan
    ascdes=`sed "5q;d" scene_info.tmp | awk '{print $5}'`
    esource=airbus
    url=nan
    data_loc=nan
    filename=SO_${full_order_number}${b}_1.tar.gz
  
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
     if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt | grep $(echo $trk | awk -FT '{print $2}') | grep $( echo ${swath} | sed 's/D//' | sed 's/R//')` ]]
     then
       estatus=C
     elif [[ ! -z `find ../${trk}/raw -name "*${scene_date}*.xml" ` ]]
     then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | head -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
     elif [[ ! -z `find . -name ${filename}` ]]
       then
         estatus=D
         tar -xzvf ${filename} > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv ${filename} untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
     else 
      estatus=A
     data_loc2=$data_loc
     fi
   else
     estatus=P
     data_loc2=$data_loc
   fi

    # save information to new text file 
   echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
 fi 
    done < scene_id.tmp
 
 # clean up
    rm *.tmp

done < OrderList
fi

## WINSAR ORDERS
# for winsar scenes
if [[ $ftype == w ]]
then
 ls Order*.pdf > OrderList
 while read -r a; do

    # convert pdf of receipt to text file
    pdftotext "$a" order.tmp

   # check to see if from geoportal or not based on whether address info is in pdf
   if [[ `grep Address order.tmp | wc -l` -eq 0 ]]
   then
      is_geoportal=1
   else
      is_geoportal=0
   fi
   
    if [[ $is_geoportal -eq 0 ]]; then
    # extract information from text file
    scene_date=`grep "\<Temporal Selection\>" order.tmp | awk '{print $3}' | awk -FT '{print $1}' | sed  's/-//g'`
    
    # check if needs fixed for new formatting
    if [[ -z $scene_date ]]; then
       scene_date=`grep "Temporal" order.tmp | awk -F: '{print $2}' | awk -FT '{print $1}' | awk '{printf("%s%s%s", substr($1, 3, 4), substr($1, 9, 2), substr($1, 13, 2))}' `

    fi
    echo $scene_date

    # check to see if already in epoch list
    if [[ `grep $scene_date Submitted_Orders.txt | grep winsar | wc -l` -gt 0 || `grep $scene_date Submitted_Orders.txt | grep archvd | wc -l` -gt 0 ]]
    then
    # make sure that source says winsar
    #sed -i 's/[^ ]*[^ ]/winsar/10' Submitted_Orders.txt
    # get metadata
    trk=`grep $scene_date Submitted_Orders.txt | grep winsar | awk '{print $4}'`
    swath=`grep $scene_date Submitted_Orders.txt | grep winsar | awk '{print $5}'`
    if [[ -z $trk ]]
    then
      trk=`grep $scene_date Submitted_Orders.txt | grep archvd | awk '{print $4}'`
    fi
    if [[ -z $swath ]]
    then
      swath=`grep $scene_date Submitted_Orders.txt | grep  archvd | awk '{print $5}'`
    fi     
  
    # Update Order status. P if in future; A if in past
    # Check to see if epoch date has passed
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]]
   then
     # update only if status = P or status = A
     if [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "P" || `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "A" ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
       if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt | grep $(echo $trk | awk -FT '{print $2}') | grep $( echo ${swath} | sed 's/D//' | sed 's/R//')` ]]
       then
         estatus=C
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[  ! -z `grep ${scene_date} Missing_Orders.txt` ]]
       then
       estatus=M
       nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
       sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
       sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find ../${trk}/raw -name "*${scene_date}*.xml" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw/T* -name "*${scene_date}*.xml" | tail -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find . -name "T*${scene_date}*.gz"` ]]
       then
         estatus=D
         tar -xzvf `find . -name "T*${scene_date}*.gz"` > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
        #mkdir -p untarred
         mv `find . -name "*${scene_date}*.gz"` untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       else
         estatus=N
         orbit=nan
       fi
    # check to see if downloaded but metadata missing
     elif [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "D" && (`grep $scene_date Submitted_Orders.txt | awk '{print $12}'` == "nan" || `grep $scene_date Submitted_Orders.txt | awk '{print $7}'` == "nan") ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
     #already untarred and put in raw dir
     if [[ ! -z `find ../${trk}/raw/T* -name "*${scene_date}*.xml" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | tail -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
      # not untarred yet
       elif [[ ! -z `find . -name "*${scene_date}*.gz"` ]]
       then
         estatus=D
         tar -xzvf `find . -name "*${scene_date}*.gz"` > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv `find . -name "*${scene_date}*.gz"` untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`  # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed -e "s/[^ ]*[^ ]/$estatus/9" | sed -e "s/[^ ]*[^ ]/$data_loc/12" | sed -e "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       fi
     fi
   fi


   else
    # info for epoch not in list yet; add information
    sat=TSX

    # if not future scene, pull info differently
    if [[ `grep FutureScene order.tmp | wc -l` == 0 ]]
    then
      trk=`grep "\<Orbit\>" order.tmp | head -1 | awk '{print "T"$10}' | sed 's/.$//g'`
      swath=`grep "\<Beam\>" order.tmp | head -1 | awk '{print $12}' | sed 's/.$//g'`
      ascdes=nan

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
    else
      trk=`grep "\<Orbit\>" order.tmp | head -1 |awk '{print "T"$2}'`
      swath=`grep "\<Beam\>" order.tmp | awk '{print $2}'`
      ascdes=`grep "\<Pass Direction\>" order.tmp | awk '{print $3}'| awk '{print substr($1,1,1)}'`
    fi
    frame=nan
    orbit=nan
    esource=winsar
    url=nan
    data_loc=nan
    filename=`grep "Order Name" order.tmp | awk '{print $3}'`
    #data_loc=$data_loc2

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
     if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt | grep $(echo $trk | awk -FT '{print $2}') | grep $( echo ${swath} | sed 's/D//' | sed 's/R//')` ]]
     then
       estatus=C
       url=nan
       data_loc2=nan
       orbit=nan
     elif [[  ! -z `grep ${scene_date} Missing_Orders.txt` ]]
     then
       estatus=M
       url=nan
       data_loc2=nan
       orbit=nan
     elif [[ ! -z `find ../${trk}/raw/T* -name "*${scene_date}*.xml" ` ]]
     then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | tail -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         getTSXdata.sh -s`date -d "$scene_date -1 days" +'%Y-%m-%d'` -e`date -d "$scene_date +1 days" +'%Y-%m-%d'` -t`echo $trk | awk -FT '{print $2}'` -dn
         url=`cat $(ls query*.txt | tail -1) | tr , '\n' | grep downloadUrl | awk -F\" '{print $4}'`
         echo "URL IS" $url
     elif [[ ! -z `find . -name "*${scene_date}*.gz"` ]]
     then
         estatus=D
         tar -xzvf `find . -name "*${scene_date}*.gz"` > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv_tar_file=`find . -name "*${scene_date}*.gz"`
         mv $mv_tar_file untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         getTSXdata.sh -s`date -d "$scene_date -1 days" +'%Y-%m-%d'` -e`date -d "$scene_date +1 days" +'%Y-%m-%d'` -t`echo $trk | -FT '{print $2}'` -dn
         url=`cat $(ls query*.txt | tail -1) | tr , '\n' | grep downloadUrl | awk -F\" '{print $4}'`
     else
      estatus=A
      data_loc2=nan
      url=nan
      orbit=nan
     fi
   else
     estatus=P
     data_loc2=nan
     url=nan
     orbit=nan
   fi

    # save information to new text file
   echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
 fi

else # geoportal case
   echo "GEOPORTAL CASE"
   # loop through text file for multiple orders
   grep "Start Time" -A2 order.tmp | grep 201  > scene_id.tmp
   while read -r b; do
      #pull info for scene id
      epoch=$b
      grep $epoch -B47 order.tmp > scene_info.tmp
      # select information from text file
    scene_date=`echo $epoch | awk -FT '{printf("%s-%s\n", substr($1, 1,7),substr($1, 8, 2))}' | sed "s/-//g"`
    trk=`grep Orbit -A2 scene_info.tmp | tail -1 | awk '{print "T"$1}'`
    orbit=nan
    sat=TSX
    echo $scene_date

    # check to see if already in epoch list
    if [[ `grep $scene_date Submitted_Orders.txt | grep winsar | wc -l` -gt 0 || `grep $scene_date Submitted_Orders.txt | grep archvd | wc -l` -gt 0 ]]
    then
    # make sure that source says winsar
    #sed -i 's/[^ ]*[^ ]/winsar/10' Submitted_Orders.txt
    # get metadata
    trk=`grep $scene_date Submitted_Orders.txt | grep winsar | awk '{print $4}'`
    swath=`grep $scene_date Submitted_Orders.txt | grep winsar | awk '{print $5}'`
    if [[ -z $trk ]]
    then
      trk=`grep $scene_date Submitted_Orders.txt | grep archvd | awk '{print $4}'`
    fi
    if [[ -z $swath ]]
    then
      swath=`grep $scene_date Submitted_Orders.txt | grep  archvd | awk '{print $5}'`
    fi

    # Update Order status. P if in future; A if in past
    # Check to see if epoch date has passed
   if [[ `echo $(( ( $(date +'%s') - $(date -ud $scene_date +'%s') )/60/60/24 ))` -gt 0 ]]
   then
     # update only if status = P or status = A
     if [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "P" || `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "A" ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
       if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt | grep $(echo $trk | awk -FT '{print $2}') | grep $( echo ${swath} | sed 's/D//' | sed 's/R//')` ]]
       then
         estatus=C
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[  ! -z `grep ${scene_date} Missing_Orders.txt` ]]
       then
       estatus=M
       nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9"`
       sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
       sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find ../${trk}/raw -name "*${scene_date}*.xml" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | tail -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       elif [[ ! -z `find . -name "T*${scene_date}*.gz"` ]]
       then
         estatus=D
         tar -xzvf `find . -name "T*${scene_date}*.gz"` > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
        #mkdir -p untarred
         mv `find . -name "*${scene_date}*.gz"` untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       else
         estatus=N
         orbit=nan
       fi
    # check to see if downloaded but metadata missing
     elif [[ `grep $scene_date Submitted_Orders.txt | awk '{print $9}'` == "D" && (`grep $scene_date Submitted_Orders.txt | awk '{print $12}'` == "nan" || `grep $scene_date Submitted_Orders.txt | awk '{print $7}'` == "nan") ]]
     then
        filename=`grep $scene_date Submitted_Orders.txt | awk '{print $11'}`
     #already untarred and put in raw dir
     if [[ ! -z `find ../${trk}/raw/T* -name "*${scene_date}*.xml" ` ]]
       then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | tail -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         nline=`grep $scene_date Submitted_Orders.txt | sed "s/[^ ]*[^ ]/$estatus/9" | sed "s/[^ ]*[^ ]/$data_loc/12" | sed "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
      # not untarred yet
       elif [[ ! -z `find . -name "*${scene_date}*.gz"` ]]
       then
         estatus=D
         tar -xzvf `find . -name "*${scene_date}*.gz"` > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv `find . -name "*${scene_date}*.gz"` untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`  # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         nline=`grep $scene_date Submitted_Orders.txt | sed -e "s/[^ ]*[^ ]/$estatus/9" | sed -e "s/[^ ]*[^ ]/$data_loc/12" | sed -e "s/[^ ]*[^ ]/${orbit}/7"`
         sed -i "/${scene_date}/c\@${nline}" Submitted_Orders.txt
         sed -i 's/@//g' Submitted_Orders.txt
       fi
     fi
   fi


   else
    # info for epoch not in list yet; add information
    sat=TSX

    # if not future scene, pull info differently
    if [[ `grep FutureScene order.tmp | wc -l` == 0 ]]
    then
      trk=`grep Orbit -A2 scene_info.tmp | tail -1 | awk '{print "T"$1}'`
      swath=`grep Beam -A2 scene_info.tmp | tail -1`
      ascdes=`grep "Pass Direction" -A2 scene_info.tmp | tail -1 | awk '{print substr($1, 1, 1)}'`

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
    else
      trk=`grep Orbit -A2 scene_info.tmp | tail -1 | awk '{print "T"$1}'`
      swath=`grep Beam -A2 scene_info.tmp | tail -1`
      ascdes=`grep "Pass Direction" -A2 scene_info.tmp | tail -1 | awk '{print substr($1, 1, 1)}'`
    fi
    frame=nan
    orbit=nan
    esource=winsar
    url=nan
    data_loc=nan
    filename=`grep "Order name" -A2 order.tmp | tail -1`
    #data_loc=$data_loc2

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
     if [[ ! -z `grep ${scene_date} ../Cancelled_Orders.txt | grep $(echo $trk | awk -FT '{print $2}') | grep $( echo ${swath} | sed 's/D//' | sed 's/R//')` ]]
     then
       estatus=C
       url=nan
       data_loc2=nan
       orbit=nan
     elif [[  ! -z `grep ${scene_date} Missing_Orders.txt` ]]
     then
       estatus=M
       url=nan
       data_loc2=nan
       orbit=nan
     elif [[ ! -z `find ../${trk}/raw -name "*${scene_date}*.xml" ` ]]
     then
         estatus=D
         dirname=`find ../${trk}/raw -name "*${scene_date}*.xml" | tail -1 | awk -Fraw/ '{print $2}' | awk -F/ '{print $1}'`
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'` # consider adding lines to untar filename and move directory to specified location, so we can update url and data_loc, and then we can grep for orbit
         getTSXdata.sh -s`date -d "$scene_date -1 days" +'%Y-%m-%d'` -e`date -d "$scene_date +1 days" +'%Y-%m-%d'` -t`echo $trk | awk -FT '{print $2}'` -dn
         url=`cat $(ls query*.txt | tail -1) | tr , '\n' | grep downloadUrl | awk -F\" '{print $4}'`
         echo "URL IS" $url
     elif [[ ! -z `find . -name "*${scene_date}*.gz"` ]]
     then
         estatus=D
         tar -xzvf `find . -name "*${scene_date}*.gz"` > tar.tmp
         dirname=`head -1 tar.tmp | awk -F/ '{print $1}'`
         rm tar.tmp
         mv $dirname /s21/insar/TSX/${trk}/raw/
         data_loc="\/s21\/insar\/TSX\/${trk}\/raw\/${dirname}"
         mkdir -p untarred
         mv_tar_file=`find . -name "*${scene_date}*.gz"`
         mv $mv_tar_file untarred/
         data_loc2=/s21/insar/TSX/${trk}/raw/${dirname}
         orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
         getTSXdata.sh -s`date -d "$scene_date -1 days" +'%Y-%m-%d'` -e`date -d "$scene_date +1 days" +'%Y-%m-%d'` -t`echo $trk | -FT '{print $2}'` -dn
         url=`cat $(ls query*.txt | tail -1) | tr , '\n' | grep downloadUrl | awk -F\" '{print $4}'`
     else
      estatus=A
      data_loc2=nan
      url=nan
      orbit=nan
     fi
   else
     estatus=P
     data_loc2=nan
     url=nan
     orbit=nan
   fi 

    # save information to new text file
   echo "$scene_date $site $sat $trk $swath $frame $orbit $ascdes $estatus $esource $filename $data_loc2 $url"  >> Submitted_Orders.txt
 fi # check for new scene
 done < scene_id.tmp
 fi # check for geoportal case
# from new eoweb geoportal

 # clean up
    rm *.tmp

done < OrderList
fi # check for winsar orders

## ARCHIVED FILES
# if arch = 1 get list of archived dims and TSX directories
if [[ "$arch" == 1 ]]
then
  find ../*/raw -name "dims*" > archdims.tmp
  ls -d ../*/raw/T*X*strip* > archtsx.tmp
  while read -r a; do
  data_loc2=$a
  scene_date=`ls $data_loc2/T*B | awk -F_ '{print $(NF)}' | awk -FT '{print $1}'`
  path=`echo $data_loc2 | sed 's/../\/s21\/insar\/TSX/'`
  if [[ `grep $path Submitted_Orders.txt | wc -l` -eq 0  && `find $a -name T*B | wc -l` -gt 0 ]]
    then
    estatus=D
    dirname=`echo $data_loc2 | awk -F/ '{print $(NF)}'`
    orbit=`grep absOrbit ${data_loc2}/T*B/T*${epoch_date}*/T*${epoch_date}*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
    sat=`ls $data_loc2/T*B | awk '{print substr($1, 1, 3)}'`
    trk=`grep relOrbit $data_loc2/T*B/T*/T*.xml | awk -F\> '{print $2}' | awk -F\< '{print "T"$1}'`
    swath=`grep strip_ $data_loc2/T*B/T*/T*.xml | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
    frame=nan
    ascdes=`grep orbitDirection $data_loc2/T*B/T*/T*.xml | awk -F\> '{print $2}' | awk -F\< '{print substr($1, 1, 1)}'`
    esource=archvd
    filename=$dirname
    path=`echo $data_loc2 | sed 's/../\/s21\/insar\/TSX/'`
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
  done < archdims.tmp

  while read -r a; do
  data_loc2=$a
  path=`echo $data_loc2 | sed 's/../\/s21\/insar\/TSX/'`
  scene_date=`echo $data_loc2 | awk -F_ '{print $(NF)}' | awk '{print substr($1, 1, 8)}'`
  if [[ `grep $path Submitted_Orders.txt | wc -l` -eq 0   && `find $a -name T*B | wc -l` -gt 0 ]]
    then
    estatus=D
    dirname=`echo $data_loc2 | awk -F/ '{print $(NF)}'`
    orbit=`grep absOrbit ${data_loc2}/T*B/T*/T*.xml | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
    sat=`ls $data_loc2/T*B | awk '{print substr($1, 1, 3)}'`
    trk=`grep relOrbit $data_loc2/T*B/T*/T*.xml | awk -F\> '{print $2}' | awk -F\< '{print "T"$1}'`
    swath=`grep strip_ $data_loc2/T*B/T*/T*.xml | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
    frame=nan
    ascdes=`grep orbitDirection $data_loc2/T*B/T*/T*.xml | awk -F\> '{print $2}' | awk -F\< '{print substr($1, 1, 1)}'`
    esource=archvd
    filename=$dirname
    path=`echo $data_loc2 | sed 's/../\/s21\/insar\/TSX/'`
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
  done < archtsx.tmp
fi

# clean up output 
#column -t Submitted_Orders.txt | sort | sed '1h;1d;$!H;$!d;G' > ../TSX_Orders-`date +%Y%m%d_%H%M`.txt
sort Submitted_Orders.txt -o Submitted_Orders.txt
sed -i '1s/^/#date site sat track swath frame orbit ascdes status source filename path url \n/' Submitted_Orders.txt
column -t Submitted_Orders.txt > ../TSX_OrderList.txt

# change permissions of files for future users.  (Not necessary now that we use groups.  Commented out -- sab 11/10/2017)
#chmod a+r+w+x Submitted_Orders.txt
#chmod a+r+w+x OrderList
#chmod a+r+w+x ../TSX_OrderList.txt
