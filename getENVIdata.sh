#!/bin/bash
# script that will query and download TSX data from WInSAR
# takes optional inputs and searches for results, saving them to query-(date).txt.  Optional download will save tar.gz files to current directory
# users should set $unavpass (UNAVCO account password) and $unavuser (UNAVCO account username) as environment variables in their setup/login script before use
# Elena C Reinisch
# 20170214
# update ECR 20180319 update for new bin_htcondor repo

if [[ $# -eq 0 ]]
then
  echo "query and download ENVI data from WInSAR"
  echo "user should set variables unavpass (UNAVCO account password) and unavuser (UNAVCO account username) as environment variables in their setup/login script before run"
  echo "-s: query for scenes after [date], given in YYYY-MM-DD format"
  echo "-e: query for scenes before [date], given in YYYY-MM-DD format"
  echo "-t: query for scenes from [track], number only"
  echo "-f: query for scenes from [frame], number only"
  echo "-p: query for scenes which intersect with [site] polygon (enter site ID only)"
  echo "-d: download in addition to saving search results (y) or save search results only (n, or don't specify flag)"
  echo "Example: /usr1/ebaluyut/bin_htcondor/getENVIdata.sh -s2016-10-01 -e2016-12-01 -t53"
  echo "Example: /usr1/ebaluyut/bin_htcondor/getENVIdata.sh -s2016-10-01 -e2016-12-01 -t53 -dy"
  exit 1
fi

# set default collection name
#collection_name=TSX%20feigl_RES1236
#collection_name="TSX feigl_RES1236"

# set download status to default 0
download_status=0

# define initial query string
query_string="http://www.unavco.org/SarArchive/SarScene?format=CEOS,ENVISAT,GEOTIFF,HDF5,COSAR,UNSPECIFIED&firstResult=0&status=archived&satellite=ENV1&maxResults=1000"
#query_string="http://www.unavco.org/SarArchive/SarScene?firstResult=0&format=UNSPECIFIED,GEOTIFF,HDF5,CEOS,ENVISAT,COSAR&maxResults=1000&status=archived"

# cycle through optional search parameters and update query string
while getopts ":s:e:t:f:d:p:c:" opt; do
  case $opt in
    s)
      echo "querying for scenes after $OPTARG" >&2
      query_string=$query_string"&start=$OPTARG"
      ;;
    e)
      echo "querying for scenes before $OPTARG" >&2
      query_string=$query_string"&end=$OPTARG"
      ;;
    t)
      echo "querying for scenes from track $OPTARG" >&2
      query_string=$query_string"&track=$OPTARG"
      ;;
    f)
      echo "querying for scenes from frame $OPTARG" >&2
      query_string=$query_string"&frame=$OPTARG"
      ;;
   p)
      echo "querying for scenes which intersect with polygon $OPTARG" >&2
      query_string=$query_string"&intersectsWith=`get_site_polygon.sh $OPTARG`"
      ;;
    d)
      if [[ "$OPTARG" == *"y"* ]]
      then
        echo "downloading successful queries" >&2
        download_status=1
      elif [[ "$OPTARG" == *"n"* ]]
      then
        echo "skipping download, saving successful queries to query txt file" >&2
        download_status=0
      else
        echo "please specify y or n for downloading"
        exit 1
      fi
      ;;
    c)
      echo "querying for scenes in collection $OPTARG" >&2
      collection_name=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# save collection name to query string
collection_name=`echo '&collectionName=WInSAR%20ESA'`
echo COLLECTION_NAME = $collection_name
query_string=${query_string}${collection_name}
echo QUERY_STRING =  $query_string

# pull html data for download metadata
wget -O query-tmp.txt "${query_string}"

# if download_status = 1, pull download URLs from query results and save to download.lst
if [[ "$download_status" == "1" ]]
then
#cat query-`date +%Y%m%d_%H%M`.txt | tr , '\n' | grep downloadUrl | awk -Funavco.org '{print $2}' | awk -Ftar.gz '{print $1}' | uniq | awk '{print "https://imaging.unavco.org"$0"tar.gz"}' > download-`date +%Y%m%d_%H%M`.lst
cat query-tmp.txt | sed 's/,/\n/g' | grep downloadUrl | awk -Funavco.org '{print $2}' | sed 's/"//g' | uniq | sed '/^\s*$/d'  |  awk '{print "https://imaging.unavco.org"$0}' > download-`date +%Y%m%d_%H%M`.lst
cat query-tmp.txt | sed 's/,/\n/g' > query-`date +%Y%m%d_%H%M`.txt
#cat query-`date +%Y%m%d_%H%M`.txt | sed 's/,/\n/g' | grep downloadUrl | awk -Funavco.org '{print $2}' | sed 's/"//g' | uniq | sed '/^\s*$/d' | tail -1 |  awk '{print "https://eo-virtual-archive4.esa.int/supersites/"$0}' > download-`date +%Y%m%d_%H%M`.lst
#download everything in list
wget -r -nv -c  --http-password=$unavpass --http-user=$unavuser -i download-`date +%Y%m%d_%H%M`.lst

find imaging.unavco.org/ -name "ASA*N1" > tar.lst
for i in `cat tar.lst`; do
mv $i .
done

#untar downloads
#find . -max-depth 1 -name "*.tar.gz" > tar.lst
#for i in `cat tar.lst`; do
#tar -xzvf $i
#done

# clean up
rm tar.lst
rm -r imaging.unavco.org
rm query-tmp.txt
fi
