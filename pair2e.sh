#!/usr/bin/env -S bash 
# 	options: -ex
# 	-x  Print commands and their arguments as they are executed.
# 	-e  Exit immediately if a command exits with a non-zero status.
#
# Usage: pair2.sh ERS 12345 67890 /scratch/feigl/dems/bhs.grd [conf.ers.txt]
# TSX Usage: pair2e.sh "$sat" "$ref" "$sec" $satparam dem/${demf} $filter_wv $site $xmin $xmax $ymin $ymax $unwrap
#
# # modifications 
# 20160804 Kurt adapt for CHTC
# 20160806 Elena correct relative path name for DEM
# update ECR 20171114 add variable for site so that p2p_TSX_SLC_airbus.csh is called for tungs and dcamp
# update ECR 20180116 add variable for site so that p2p_TSX_SLC_airbus.csh is called for dixie (as well as tungs and dcamp)
# udpate ECR 20180605 add S1B
# 20200127 KLF try to fix enviroment variables $maule
# 20201130 Sam and Kurt noting necessary changes for migration to 6.0 and Askja
# 20201209 Sam modified for ref/sec and paths for dem and config.tsx.txt
# 20210308 Sam added ${12} unwrap value "y" or empty (passed in from run_pair_gmtsarv60.sh) 
# 20210318 Kurt and Sam added self-documentation.
if [ ! "$#" -eq 12 ]; then
	echo "$0 needs 12 arguments. Found only $#"
   	exit 0
fi

sat=${1}
ref=${2}
sec=${3}
satparam=${4}
demgrd=${5}
filter_wv=${6}
site=${7}
xmin=${8}
xmax=${9}
ymin=${10}
ymax=${11}
unwrap=${12}

if [[ "$sat" == "ERS2" || "$sat" == "ERS1" ]] ; then
	sat=ERS
fi

#regioncut=0 # temporary variable to default to no cutting (for development only)
#orb1=$5
#orb2=$6
orb1a=`expr $ref - 1`
orb1b=`expr $ref + 1`
orb2a=`expr $ref - 1`
orb2b=`expr $ref + 1`
homedir=`pwd`

if [ $# -lt 3 ] ; then
	echo " Usage: pair2.sh ERS 12345 67890 dem/dem.grd [conf.ers.txt]"
	echo "missing arguments"
	exit 1
fi

if [ $# -gt 3 ] ; then
  case "$sat" in 
  ENVI)
    #cnf=$homedir/gmtsar/config/config.envi.txt
    cp $homedir/gmtsar/config/config.envi.txt .
    cnf=$homedir/config.envi.txt 
    ;;
  ERS)
    #cnf=$homedir/gmtsar/config/config.ers.txt
    cp $homedir/gmtsar/config/config.ers.txt .
    cnf=$homedir/config.ers.txt
    ;;
  ERS2)
    #cnf=$homedir/gmtsar/config/config.ers.txt
    cp $homedir/gmtsar/config/config.ers.txt .
    cnf=$homedir/config.ers.txt
    ;;
  ERS1)
    #cnf=$homedir/gmtsar/config/config.ers.txt
    cp $homedir/gmtsar/config/config.ers.txt .
    cnf=$homedir/config.ers.txt
    ;;
  ALOS)
    #cnf=$homedir/gmtsar/config/config.alos.txt
    cp $homedir/gmtsar/config/config.alos.txt .
    cnf=$homedir/config.alos.txt
    ;;
  TSX)
    #cnf=$homedir/gmtsar/config/config.tsx.txt
    # for htcondor
    #cp $homedir/gmtsar/config/config.tsx.txt .
    # for Askja
    cp /opt/gmtsar/6.0/share/gmtsar/csh/config.tsx.txt .
    cnf=$homedir/config.tsx.txt
    ;;
  S1A)
    #cnf=$homedir/gmtsar/config/config.s1a.txt
    cp $homedir/gmtsar/config/config.s1a.txt .
    cnf=$homedir/config.s1a.txt
    ;;
  S1B)
    cp $homedir/gmtsar/config/config.s1a.txt .
    cnf=$homedir/config.s1a.txt
    ;;
  *)
    echo "unknown sat $sat"
    exit 1
    ;;
  esac
else
  #cnf=$5
    cnf=$homedir/gmtsar/config/config.s1a.txt
    cp $homedir/gmtsar/config/config.s1a.txt .
    cnf=$homedir/config.s1a.txt
fi

# Edit configuration file in place (-i) with custom parameters 
if [ $# -gt 5 ] ; then
	# write subregion for cutting to config file
	sed -i "/#region_cut2/c\region_cut2 = $xmin/$xmax/$ymin/$ymax" $cnf
#else
#   	sed -i "/region_cut2/c\region_cut2 = " $cnf
fi

if [ $# -ge 5 ] ; then
	sed -i "/filter_wavelength/c\filter_wavelength = $filter_wv" $cnf
	sed -i "/proc_stage/c\proc_stage = 1" $cnf
fi

# Edit configuration file for unwrapping (default if not edited is "0" meaning "no")
# this test checks to see if the variable is set as an expression that evaluates to nothing if unwrap is unset
if [ -z ${unwrap+x} ]; then 
	sed -i "/threshold_snaphu/c\threshold_snaphu = ${unwrap}" $cnf
fi
	
# construct path to RAW data
#RAWdir=`pwd`/raw
# make relative path name
RAWdir=../../RAW
# should this be ../RAW? probably not
#RAWdir=../RAW

# construct name for In directory
pairdir=In${ref}_${sec}
if [ -d $pairdir ]; then
	echo "removing existing pairdir named $pairdir"
   	rm -rf $pairdir
fi
mkdir $pairdir
cd $pairdir

# This may or may not have changed in v6.0
mkdir raw intf SLC topo

# can use relative path name
# is this broken?
cd topo
ln -s ../../$demgrd dem.grd
cd ..

# set up links to RAW 
cd raw
#ls $RAWdir/*$2*
#ls $RAWdir/*$3*

if [ "$sat" == "ENVI" ] ; then
	cp $RAWdir/$2.* .
	cp $RAWdir/$3.* .
	mv ../../orbits .
elif [[ "$sat" == "ERS"* ]] ; then
	cp $RAWdir/$2.* .
	cp $RAWdir/$3.* .
	mv ../../orbits .
elif [ "$sat" == "ALOS" ] ; then
	cp $RAWdir/IMG*$2* .
	cp $RAWdir/LED*$2* .
	cp $RAWdir/IMG*$3* .
	cp $RAWdir/LED*$3* .
	# cp $RAWdir/IMG*$2* .
	# cp $RAWdir/IMG*$3* .
elif [ "$sat" == "TSX" ] ; then
    # copy the files we want to keep in the tar file
	# cp -v $RAWdir/${ref}.PRM .
	# cp -v $RAWdir/${sec}.PRM .
	# cp -v $RAWdir/${ref}.LED .
	# cp -v $RAWdir/${sec}.LED .
    # # make links for some files
	# ln -s $RAWdir/${ref}.LED ${ref}.LED
	# ln -s $RAWdir/${sec}.LED ${sec}.LED

	ln -s $RAWdir/${ref}.SLC ${ref}.SLC
	ln -s $RAWdir/${sec}.SLC ${sec}.SLC
	longdirname=`grep ${site} /s12/insar/TSX/TSX_OrderList.txt | grep ${ref} | awk '{print $12}'`
	echo "longdirname is $longdirname"
	longbasename=`basename $longdirname`
	echo "longbasename is $longbasename"
	# links for $ref and $sec .cos and .xml with date names for rsynced earlier run_pair_gmtsarv60.sh
	#XMLref=`find $RAWdir/TDX1_SM_091_strip_005_20201023014507 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	XMLref=`find $RAWdir/$longbasename -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	ln -s $XMLref ${ref}.xml
	#COSref=`find $RAWdir/TDX1_SM_091_strip_005_20201023014507 -name "*.cos"`
	COSref=`find $RAWdir/$longbasename -name "*.cos"`
	ln -s $COSref ${ref}.cos
	#XMLsec=`find $RAWdir/TDX1_SM_091_strip_005_20201114014508 -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	XMLsec=`find $RAWdir/$longbasename -name "*.xml" | grep -v ANNOTATION | grep -v iif`
	ln -s $XMLsec ${sec}.xml
	#COSsec=`find $RAWdir/TDX1_SM_091_strip_005_20201114014508 -name "*.cos"`
	COSsec=`find $RAWdir/$longbasename -name "*.cos"`
	ln -s $COSsec ${sec}.cos
elif [[ "$sat" == "S1"* ]] ; then
	subswath=$satparam
	ln -s $RAWdir/${sat}*${2}_${subswath}.* .
	ln -s $RAWdir/${sat}*${3}_${subswath}.* .
	##  ln -s $RAWdir/S1A*$2*.SAFE/annotation/*.xml .
	##  ln -s $RAWdir/S1A*$2*.SAFE/measurement/*.tiff .
	##  ln -s $RAWdir/S1A*$3*.SAFE/annotation/*.xml .
	##  ln -s $RAWdir/S1A*$3*.SAFE/measurement/*.tiff .
	## ln -s $RAWdir/S1A*$2*.xml .
	##  ln -s $RAWdir/S1A*$2*.tiff .
	##  ln -s $RAWdir/S1A*$3*.xml .
	##  ln -s $RAWdir/S1A*$3*.tiff .
	##  ln -s $RAWdir/S1A*$orb1a*.EOF .
	##  ln -s $RAWdir/S1A*$orb2a*.EOF .
	#  ln -s $RAWdir/*.xml .
	#  ln -s $RAWdir/*.tiff .
	#  ln -s $RAWdir/*.xml .
	#  ln -s $RAWdir/*.tiff .
	#  ln -s $RAWdir/*.EOF .
	#  ln -s $RAWdir/*.EOF .
	#  orb1=`ls S1A*$orb1a*.EOF`
	#  orb2=`ls S1A*$orb2a*.EOF` 
	#  orb1=`ls S1A*$orb1a*.EOF`
	#  orb2=`ls S1A*$orb2a*.EOF`
	#ln -s ../../$demgrd .
	## refdir=`ls S1A*$2*.xml | awk -F1.xml '{print $1}'`
	## secdir=`ls S1A*$3*.xml | awk -F1.xml '{print $1}'`
	##echo $refdir
	##echo $secdir
	#echo "PASS"
else
	echo "unknown sat $sat"
	exit 1
fi
cd ..

# can use relative path name
#cd topo
#ln -s ../../$demgrd dem.grd
#cd ..

# start to write the commands for the run script with sebang
# for htcondor
echo "#!/bin/sh" > run.sh
# for Askja
#echo '#!/usr/bin/env -S bash -v' > run.sh

echo '#This is a test. In a real run, the next line would not be here.' >> run.sh
echo 'exit 0' >> run.sh

## for ACI HPC cluster jobs to be submitted with batch run.sh
#echo "#SBATCH --partition=geoscience" >> run.sh
#echo "#SBATCH --nodes=1" >> run.sh
#echo "#SBATCH --ntasks-per-node=1" >> run.sh
#echo "#SBATCH --mem-per-cpu=4000" >> run.sh
#echo "#SBATCH --time=0-02:30:00" >> run.sh

## for CHTC jobs to be submitted with condor_submit run.sh
#echo "request_cpus = 1" >> run.sh
#request_memory = 1GB
#request_disk = 10GB
#queue

# find reference and secondary for ALOS
if [[ "$sat" == "ALOS" ]] ; then
	ref=`ls -l raw/IMG-HH-*${ref}* | awk -Fraw/ '{print $2}' | head -1`
	sec=`ls -l raw/IMG-HH-*${sec}* | awk -Fraw/ '{print $2}' | head -1`
fi

# include subswaths for SNT1A
#if [ "$sat" == "SNT1A" ]
#then
 # cd raw
 # echo "cd raw" >> ../run.sh
 # for i in 1 ; do a=`basename *$ref*$i.xml .xml`; b=`basename *$sec*$i.xml .xml`; echo align_tops.csh $a $orb1 $b $orb2 `echo $demgrd | awk -F/ '{print $2}'` >> ../run.sh; done
 # echo "cd .." >> ../run.sh
 # cd ..
  #echo "mkdir F1 F2 F3
#echo "mkdir F1
#cd F1
#ln -s $cnf .
#mkdir raw topo intf SLC
#cd raw
#ln -s ../../raw/*F1* .
#cd ..
#ln -s ../../$demgrd topo/dem.grd
#p2p_S1A_TOPS.csh S1A"$ref"_F1 S1A"$sec"_F1 config.s1a.txt
#cd ..
#cd F2
#ln -s $cnf .
#mkdir raw topo intf SLC
#cd raw
#ln -s ../../raw/*F2* .
#cd ..
#ln -s ../../$demgrd topo/
#p2p_S1A_TOPS.csh S1A"$ref"_F2 S1A"$sec"_F2 config.s1a.txt
#cd ..
#cd F3
#ln -s $cnf .
#mkdir raw topo intf SLC
#cd raw
#ln -s ../../raw/*F3* .
#cd ..
#ln -s ../../$demgrd topo/
#p2p_S1A_TOPS.csh S1A"$ref"_F3 S1A"$sec"_F3 config.s1a.txt
#cd ..">> run.sh
#fi


echo SAT = $sat

# build the command [p2p_processing.csh now handles TSX and other sats that don't have their own scripts, but order of args has probably changed]
if [[ "$sat" == "TSX" ]] ; then
	if [[ "$site" == "dcamp" || "$site" == "tungs" || "$site" == "dixie" || "$site" == "tusca" ]] ; then #special case for Airbus not urgent
		echo "USING AIRBUS VERSION OF P2P FOR TSX"
		echo p2p_TSX_SLC_airbus.csh $ref $sec $cnf >> run.sh
  	else
		#this script is now p2p_processing.csh  
		#echo p2p_TSX_SLC.csh $ref $sec $cnf >> run.sh
		echo p2p_processing.csh ${sat} ${ref} ${sec} ${cnf} >> run.sh
	fi
elif [[ "$sat" == "S1"* ]] ; then
	echo p2p_S1A_TOPS.csh ${sat}${ref}_${subswath} ${sat}${sec}_${subswath} $cnf >> run.sh
elif [[ "$sat" == "ALOS" ]] ; then
	if [[ $ref == *"1.1"* ]] ; then
		echo $ref $sec
		echo p2p_ALOS2_SLC.csh $ref $sec $cnf >> run.sh
	else
		echo p2p_ALOS.csh $ref $sec $cnf >> run.sh
	fi
else
	echo p2p_$sat.csh $ref $sec $cnf >> run.sh
fi

# make run.sh executable and actually run the script run.sh (output from pair2e.sh)
chmod +x run.sh

#cd ..
echo "print working directory:"
pwd
echo "Consider running the following command"
echo "cd $pairdir; ./run.sh"
#exit 0
