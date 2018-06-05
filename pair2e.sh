#!/bin/bash
#
# Usage: pair2.sh ERS 12345 67890 /scratch/feigl/dems/bhs.grd [conf.ers.txt]
#
# # modifications 
# 20160804 Kurt adapt for CHTC
# 20160806 Elena correct relative path name for DEM
# update ECR 20171114 add variable for site so that p2p_TSX_SLC_airbus.csh is called for tungs and dcamp
# update ECR 20180116 add variable for site so that p2p_TSX_SLC_airbus.csh is called for dixie (as well as tungs and dcamp)
# udpate ECR 20180605 add S1B

sat=$1
mst=$2
slv=$3
satparam=$4
demgrd=$5
filter_wv=$6
site=$7
xmin=$8
xmax=$9
ymin=${10}
ymax=${11}

if [[ "$sat" == "ERS2" || "$sat" == "ERS1" ]]
then
 sat=ERS
fi


#regioncut=0 # temporary variable to default to no cutting (for development only)
#orb1=$5
#orb2=$6
orb1a=`expr $mst - 1`
orb1b=`expr $mst + 1`
orb2a=`expr $mst - 1`
orb2b=`expr $mst + 1`
homedir=`pwd`

if [ $# -lt 3 ] 
   then
   echo " Usage: pair2.sh ERS 12345 67890 dem/dem.grd [conf.ers.txt]"
   echo "missing arguments"
   exit 1
fi

if [ $# -gt 3 ] 
  then
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
    cp $homedir/gmtsar/config/config.tsx.txt .
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

if [ $# -gt 5 ]
  then
# write subregion for cutting to config file
   sed -i "/#region_cut2/c\region_cut2 = $xmin/$xmax/$ymin/$ymax" $cnf
#else
#   sed -i "/region_cut2/c\region_cut2 = " $cnf
fi

if [ $# -ge 5 ]
then
sed -i "/filter_wavelength/c\filter_wavelength = $filter_wv" $cnf
fi

# construct path to RAW data
#RAWdir=`pwd`/raw
# make relative path name
RAWdir=../../RAW

# construct name for In directory
pairdir=In$2_$3
mkdir $pairdir 
cd $pairdir

mkdir raw intf SLC topo

# can use relative path name
cd topo
ln -s ../../$demgrd dem.grd
cd ..

# set up links to RAW 
cd raw
ls $RAWdir/*$2*
ls $RAWdir/*$3*

if [ "$sat" == "ENVI" ] 
  then
  cp $RAWdir/$2.* .
  cp $RAWdir/$3.* .
  mv ../../orbits .
elif [[ "$sat" == "ERS"* ]] 
  then
  cp $RAWdir/$2.* .
  cp $RAWdir/$3.* .
  mv ../../orbits .
elif [ "$sat" == "ALOS" ] 
  then
  cp $RAWdir/IMG*$2* .
  cp $RAWdir/LED*$2* .
  cp $RAWdir/IMG*$3* .
  cp $RAWdir/LED*$3* .
#  cp $RAWdir/IMG*$2* .
#  cp $RAWdir/IMG*$3* .
elif [ "$sat" == "TSX" ] 
  then
  cp $RAWdir/$2.PRM .
  cp $RAWdir/$3.PRM .
  ln -s $RAWdir/$2.LED .
  ln -s $RAWdir/$3.LED .
  ln -s $RAWdir/$2.SLC .
  ln -s $RAWdir/$3.SLC .
elif [[ "$sat" == "S1"* ]]
  then
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
# ln -s $RAWdir/*.xml .
#  ln -s $RAWdir/*.tiff .
#  ln -s $RAWdir/*.xml .
#  ln -s $RAWdir/*.tiff .
#  ln -s $RAWdir/*.EOF .
#  ln -s $RAWdir/*.EOF .
#  orb1=`ls S1A*$orb1a*.EOF`
#  orb2=`ls S1A*$orb2a*.EOF` 
# orb1=`ls S1A*$orb1a*.EOF`
#  orb2=`ls S1A*$orb2a*.EOF`
#ln -s ../../$demgrd .
# # mastdir=`ls S1A*$2*.xml | awk -F1.xml '{print $1}'`
# # slavdir=`ls S1A*$3*.xml | awk -F1.xml '{print $1}'`
##echo $mastdir
##echo $slavdir
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

# start to write the commands for the run script
echo "#!/bin/sh" > run.sh

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

# find master and slave for ALOS
if [ "$sat" == "ALOS" ]
then
  mst=`ls -l raw/IMG-HH-*${mst}* | awk -Fraw/ '{print $2}' | head -1`
  slv=`ls -l raw/IMG-HH-*${slv}* | awk -Fraw/ '{print $2}' | head -1`
fi

# include subswaths for SNT1A
#if [ "$sat" == "SNT1A" ]
#then
 # cd raw
 # echo "cd raw" >> ../run.sh
 # for i in 1 ; do a=`basename *$mst*$i.xml .xml`; b=`basename *$slv*$i.xml .xml`; echo align_tops.csh $a $orb1 $b $orb2 `echo $demgrd | awk -F/ '{print $2}'` >> ../run.sh; done
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
#p2p_S1A_TOPS.csh S1A"$mst"_F1 S1A"$slv"_F1 config.s1a.txt
#cd ..
#cd F2
#ln -s $cnf .
#mkdir raw topo intf SLC
#cd raw
#ln -s ../../raw/*F2* .
#cd ..
#ln -s ../../$demgrd topo/
#p2p_S1A_TOPS.csh S1A"$mst"_F2 S1A"$slv"_F2 config.s1a.txt
#cd ..
#cd F3
#ln -s $cnf .
#mkdir raw topo intf SLC
#cd raw
#ln -s ../../raw/*F3* .
#cd ..
#ln -s ../../$demgrd topo/
#p2p_S1A_TOPS.csh S1A"$mst"_F3 S1A"$slv"_F3 config.s1a.txt
#cd ..">> run.sh
#fi


echo SAT = $sat

# build the command
if [ "$sat" == "TSX" ]
then
  if [[ "$site" == "dcamp" || "$site" == "tungs" || "$site" == "dixie" ]]
  then
    echo p2p_TSX_SLC_airbus.csh $mst $slv $cnf >> run.sh
  else
    echo p2p_TSX_SLC.csh $mst $slv $cnf >> run.sh
  fi
elif [[ "$sat" == "S1"* ]]
then
  echo p2p_S1A_TOPS.csh ${sat}${mst}_${subswath} ${sat}${slv}_${subswath} $cnf >> run.sh
elif [ "$sat" == "ALOS" ]
then
  if [[ $mst == *"1.1"* ]]
  then
    echo $mst $slv
    echo p2p_ALOS2_SLC.csh $mst $slv $cnf >> run.sh
  else
    echo p2p_ALOS.csh $mst $slv $cnf >> run.sh
  fi
else
  echo p2p_$sat.csh $mst $slv $cnf >> run.sh
fi

cd ..
echo "Consider the following"
echo "   cd $pairdir; bash run.sh"
exit 0
