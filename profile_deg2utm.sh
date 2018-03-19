#!/bin/bash
# reads profile.rsp file and converts to utm
# requires utm python package https://pypi.python.org/pypi/utm
# Elena C Reinisch 20170518
# update ECR 20180319 update for new bin_htcondor repo

# define location of python utm package
pythonutmpath=~ebaluyut/binECR

> profile_utm.rsp
while read line; do
   lon=`echo $line | awk '{print $1}'`
   lat=`echo $line | awk '{print $2}'`
   echo $lat $lon
   v=`echo $line | awk '{print $3}'`
   python ${pythonutmpath}/python2deg2utm.py $lat $lon > out.tmp
   easti=`grep Easting out.tmp | awk '{print $3}'`
   northi=`grep Northing out.tmp | awk '{print $3}'`
   #line=`echo $line | sed 's/${lat}/${northi}/'`
   #line=`echo $line | sed 's/${lon}/${easti}/'`
   #echo $line >> utm.rsp
    echo $easti $northi $v >> profile_utm.rsp
fi

done < $1

