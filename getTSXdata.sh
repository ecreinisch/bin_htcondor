#!/bin/bash
# script that will query and download TSX data from WInSAR
# takes optional inputs and searches for results, saving them to query-(date).txt.  Optional download will save tar.gz files to current directory
# users should set $unavpass (UNAVCO account password) and $unavuser (UNAVCO account username) as environment variables in their setup/login script before use
# Elena C Reinisch
# 20170214
# update ECR 20180319 update for new bin_htcondor repo

if [[ $# -eq 0 ]]
then
  echo "query and download TSX data from WInSAR"
  echo "user should set variables unavpass (UNAVCO account password) and unavuser (UNAVCO account username) as environment variables in their setup/login script before run"
  echo "-s: query for scenes after [date], given in YYYY-MM-DD format"
  echo "-e: query for scenes before [date], given in YYYY-MM-DD format"
  echo "-t: query for scenes from [track], number only"
  echo "-d: download in addition to saving search results (y) or save search results only (n, or don’t specify flag)"
  echo "-c: collection name (optional, default is TSX feigl_RES1236); enter %20 in place of spaces (e.g., TSX%20feigl_RES1236)"
  echo "Example: /usr1/ebaluyut/bin_htcondor/getTSXdata.sh -s2016-10-01 -e2016-12-01 -t53"
  echo "Example: /usr1/ebaluyut/bin_htcondor/getTSXdata.sh -s2016-10-01 -e2016-12-01 -t53 -dy"
  exit 1
fi

# set default collection name
#collection_name=TSX%20feigl_RES1236
collection_name="TSX feigl_RES1236"

# set download status to default 0
download_status=0

# define initial query string
query_string="http://www.unavco.org/SarArchive/SarScene?format=CEOS,ENVISAT,GEOTIFF,HDF5,COSAR,UNSPECIFIED&firstResult=0&status=archived&maxResults=1000"
#query_string="http://www.unavco.org/SarArchive/SarScene?firstResult=0&format=UNSPECIFIED,GEOTIFF,HDF5,CEOS,ENVISAT,COSAR&maxResults=1000&status=archived"

# cycle through optional search parameters and update query string
while getopts ":s:e:t:d:c:" opt; do
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
query_string=$query_string"&collectionName=${collection_name}"

# pull html data for download metadata
wget -O query-`date +%Y%m%d_%H%M`.txt "${query_string}"

# if download_status = 1, pull download URLs from query results and save to download.lst
if [[ "$download_status" == "1" ]]
then
cat query-`date +%Y%m%d_%H%M`.txt | tr , '\n' | grep downloadUrl | awk -Funavco.org '{print $2}' | awk -Ftar.gz '{print $1}' | uniq | awk '{print "https://imaging.unavco.org"$0"tar.gz"}' > download-`date +%Y%m%d_%H%M`.lst
#download everything in list
wget -r -nv -nd -c --http-password=$unavpass --http-user=$unavuser -i download-`date +%Y%m%d_%H%M`.lst
#find www.unavco.org/ -name "*.tar.gz" > tar.lst
#for i in `cat tar.lst`; do
#mv $i .
#done

#untar downloads
find . -max-depth 1 -name "*.tar.gz" > tar.lst
for i in `cat tar.lst`; do
tar -xzvf $i
done

# clean up
rm tar.lst
#rm -r www.unavco.org
fi
