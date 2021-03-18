#!/bin/bash
# script that will query and download TSX data from WInSAR
# takes optional inputs and searches for results, saving them to query-(date).txt.  Optional download will save tar.gz files to current directory
# users should set $unavpass (UNAVCO account password) and $unavuser (UNAVCO account username) as environment variables in their setup/login script before use
# Elena C Reinisch
# 20170214
# update ECR 20180319 update for new bin_htcondor repo
# update ECR 20180919 update for new WInSAR data layout (parameter names, host site, etc)
# update ECR 20190108 update for new WInSAR portal queries
# update SAB 20210303 fixed the moving and untarring steps and added a check/exit for existing .tar.gz files
# update SAB 20210303 added metadata collection to make database update easier (still does not write directly to the DB)

if [[ $# -eq 0 ]]
then
  echo "query and download TSX data from WInSAR"
  echo "user should set variables unavpass (UNAVCO account password) and unavuser (UNAVCO account username) as environment variables in their setup/login script before run"
  echo "-s: query for scenes after [date], given in YYYY-MM-DD format"
  echo "-e: query for scenes before [date], given in YYYY-MM-DD format"
  echo "-t: query for scenes from [track], number only"
  echo "-d: download in addition to saving search results (y) or save search results only (n, or don't specify flag)"
  echo "-c: collection name (optional, default is TSX feigl_RES1236); enter %20 in place of spaces (e.g., TSX%20feigl_RES1236)"
  echo "Example: /usr1/ebaluyut/bin_htcondor/getTSXdata.sh -s2016-10-01 -e2016-12-01 -t53"
  echo "Example: /usr1/ebaluyut/bin_htcondor/getTSXdata.sh -s2016-10-01 -e2016-12-01 -t53 -dy"
  exit 1
fi

# first check to make sure we have a clean directory without previous downloads
if [ -e *.tar.gz ]; then
	echo "Detecting existing .tar.gz files from previous download."
	echo "Please remove or resolve these before proceeding."
	exit 1
fi

# set default collection name
#collection_name=TSX%20feigl_RES1236
collection_name="TSX feigl_RES1236"

# set download status to default 0
download_status=0

# define initial query string
#query_string="http://www.unavco.org/SarArchive/SarScene?format=CEOS,ENVISAT,GEOTIFF,HDF5,COSAR,UNSPECIFIED&firstResult=0&status=archived&maxResults=1000"
query_string="https://web-services.unavco.org/brokered/ssara/api/sar/search?format=CEOS,ENVISAT,GEOTIFF,HDF5,COSAR,UNSPECIFIED&firstResult=0&status=archived&maxResults=1000&platform=TANDEM-X 1,TERRASAR-X 1"

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
      #capture track number for sorting
      tracknum=$OPTARG
      #query_string=$query_string"&track=$OPTARG"
      query_string=$query_string"&relativeOrbit=$OPTARG"
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
	wget -r -nv -nd --no-check-certificate -c --http-password=$unavpass --http-user=$unavuser -i download-`date +%Y%m%d_%H%M`.lst
	#untar downloads
	echo "moving downloaded files to /s12/insar/TSX/T$tracknum/raw/ and untaring" 
	rm -f tar.lst
	rm -f dbupdates.txt
	touch dbupdates.txt
	ls *.tar.gz > tar.lst
	for i in `cat tar.lst`; do
        	mv $i /s12/insar/TSX/T$tracknum/raw/$i
        	cd /s12/insar/TSX/T$tracknum/raw
		dbfilename=$i
		d="${i%.tar.gz}"
		dbdirname=/s12/insar/TSX/T$tracknum/raw/$d
        	tar -xzvf $i
		rm $i
		XML=`find $dbdirname -name "*.xml" | grep -v ANNOTATION | grep -v iif`
		dbepochdate=`grep startTimeUTC $XML | awk 'NR==1{print substr($1,15,4) substr($1,20,2) substr($1,23,2)}'`
		absorbit=`grep absOrbit $XML | awk 'NR==1{print substr($1,11,5)}'`
		beam=`grep strip_ $XML | awk 'NR==1{print substr($1,33,9)}'`
        	cd /s12/insar/TSX/winsar
                echo "$dbepochdate  ADDME  TSX  T$tracknum    $beam   nan    $absorbit  A       D       dlrdlr  $dbfilename  $dbdirname" >>dbupdates.txt
	done
echo "dont forget to update the database at /s12/insar/TSX/TSX_OrderList.txt with content from ./dbupdates.txt"
cat dbupdates.txt
fi
