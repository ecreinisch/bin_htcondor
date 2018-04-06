#!/bin/bash
#
# Usage: pair2.sh ERS 12345 67890 /scratch/feigl/dems/bhs.grd [conf.ers.txt]
#
# # modifications 
# 20160804 Kurt adapt for CHTC
# 20160806 Elena correct relative path name for DEM
sat=$1
mst=$2
slv=$3
demgrd=$4
wv=$5
#orb1=$5
#orb2=$6
orb1a=`expr $mst - 1`
orb1b=`expr $mst + 1`
orb2a=`expr $mst - 1`
orb2b=`expr $mst + 1`


if [ $# -lt 3 ] 
   then
   echo " Usage: pair2.sh ERS 12345 67890 dem/dem.grd [conf.ers.txt]"
   echo "missing arguments"
   exit 1
fi

if [ $# -eq 4 ] 
  then
  case "$sat" in 
  ENVI)
    cnf=/mnt/gluster/feigl/GMT5SAR5.2/config/config.envi.txt
    ;;
  ERS)
    cnf=/mnt/gluster/feigl/GMT5SAR5.2/config/config.ers.txt
    ;;
  ALOS)
    cnf=/mnt/gluster/feigl/GMT5SAR5.2/config/config.alos.txt
    ;;
  TSX)
    cnf=/mnt/gluster/feigl/GMT5SAR5.2/config/config.tsx.txt
    ;;
  SNT1A)
    cnf=/mnt/gluster/feigl/GMT5SAR5.2/config/config.s1a.txt
    ;;
  *)
    echo "unknown sat $sat"
    exit 1
    ;;
  esac
else
  #cnf=$5
    cnf=/mnt/gluster/feigl/GMT5SAR5.2/config/config.s1a.txt
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

# set up links to RAW 
cd raw
ls $RAWdir/*$2*
ls $RAWdir/*$3*

if [ "$sat" == "ENVI" ] 
  then
  ln -s $RAWdir/$2.* .
  ln -s $RAWdir/$3.* .
elif [ "$sat" == "ERS" ] 
  then
  ln -s $RAWdir/$2.* .
  ln -s $RAWdir/$3.* .
elif [ "$sat" == "ALOS" ] 
  then
  ln -s $RAWdir/IMG*$2*0__A .
  ln -s $RAWdir/LED*$2*0__A .
  ln -s $RAWdir/IMG*$3*0__A .
  ln -s $RAWdir/LED*$3*0__A .
  ln -s $RAWdir/IMG*$2*0__A.* .
  ln -s $RAWdir/IMG*$3*0__A.* .
elif [ "$sat" == "TSX" ] 
  then
  ln -s $RAWdir/$2.* .
  ln -s $RAWdir/$3.* .
elif [ "$sat" == "SNT1A" ]
  then
  ln -s $RAWdir/S1A*${2}_F2.* .
  ln -s $RAWdir/S1A*${3}_F2.* .
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
cd topo
ln -s ../../$demgrd dem.grd
cd ..

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
  mst=`ls -l raw/IMG-HH-ALPSR*0__A | awk '{print $9}' | sed 's/raw\///g' | head -1`
  slv=`ls -l raw/IMG-HH-ALPSR*0__A | awk '{print $9}' | sed 's/raw\///g' | tail -1`
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




# build the command
if [ "$sat" == "TSX" ]
then
  echo p2p_TSX_SLC_filter.csh $mst $slv $cnf $wv >> run.sh
elif [ "$sat" == "SNT1A" ]
then
  echo p2p_S1A_TOPS.csh S1A${mst}_F2 S1A${slv}_F2 $cnf >> run.sh
else
  echo p2p_$sat.csh $mst $slv $cnf >> run.sh
fi

cd ..
echo "Consider the following"
echo "   cd $pairdir; bash run.sh"
exit 0
