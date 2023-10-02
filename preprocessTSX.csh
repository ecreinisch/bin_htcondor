#!/bin/csh -vex 
#       $Id$
#
#  Xiaohua Xu, Jan, 2018 -- original author
#
#  Perform UW Geoscience workflow preprocessing on raw TSX data from DLR and/or Winsar
#
#  20210125 edit batzli: This copy (preprocessTSX.csh)  is only for pre-processing (Stage-1) with GMTSAR 6.  added "exit"
#  20210216 edit batzli: this will now only copy .xml and make .PRM for each epoch to go in the preproc directory.  
#  20210301 edit batzli: added date extraction and validation from database and xml file

  if ($#argv != 1) then
    echo ""
    echo "Usage: preprocessTSX.csh foldername"
    echo "Single epoch example: preprocessTSX.csh "
    echo "Multiple epoch in 'newdims.lst': preprocessTSX.csh all"
    echo ""
    exit 1
  endif
    
# start
if (${1} == "all") then
	echo "processing all"
	set v = `cat newdims.lst`
	@ i = 1
	while ( $i <= $#v )
    		#echo $v[$i]
		set infolder = $v[$i]
		set yyyymmdd = `grep $infolder ../../TSX_OrderList.txt | awk '{print $1}'`
		set XML = `find ./$infolder -name "*.xml" | grep -v ANNOTATION | grep -v iif`
		set yyyymmdd_validate = `grep startTimeUTC $XML | awk 'NR==1{print substr($1,15,4) substr($1,20,2) substr($1,23,2)}'`
		if ($yyyymmdd != $yyyymmdd_validate) then
        		echo "Database date does not match date in XML file."
        		echo "Check for errors in the database or issues with data availability for XML parsing."
        		exit 1
		else
        		echo "The date is valid!"
		endif
		set COS = `find ./$infolder -name "*.cos"`
		cp $XML ../preproc/$yyyymmdd.xml
		echo looking for make_slc_tsx
		which make_slc_tsx
		# 2023/06/22 add full path for Kurt - should not have to do this
		/opt/gmtsar/6.0/bin/make_slc_tsx $XML $COS $yyyymmdd
		mv $yyyymmdd.* ../preproc/.
		#rm ../preproc/$yyyymmdd.SLC
    		@ i = $i + 1
	end
	echo "Done processing files in newdims.lst"
else

set infolder = ${1}

# set date as extracted date from database
set yyyymmdd = `grep $infolder ../../TSX_OrderList.txt | awk '{print $1}'`

# set validation date as extracted from XML file
set XML = `find ./$infolder -name "*.xml" | grep -v ANNOTATION | grep -v iif`
set yyyymmdd_validate = `grep startTimeUTC $XML | awk 'NR==1{print substr($1,15,4) substr($1,20,2) substr($1,23,2)}'`

# validate date
if ($yyyymmdd != $yyyymmdd_validate) then
	echo "Database date does not match date in XML file."
	echo "Check for errors in the database or issues with data availability for XML parsing."
	exit 1
else 
	echo "The date is valid!"
endif
  
# Find .cos for TSX processing
set COS = `find ./$infolder -name "*.cos"`

# Make a copy and rename .xml
cp $XML ../preproc/$yyyymmdd.xml

# Make and move the SLC, LED, and PRM
make_slc_tsx $XML $COS $yyyymmdd
mv $yyyymmdd.* ../preproc/.       
#rm ../preproc/$yyyymmdd.SLC

endif
