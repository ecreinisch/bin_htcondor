#!/bin/bash
# checks condor job .out files for completed pairs
# Elena Reinisch 20161026
## TO DO ON SUBMIT
# 1a - add line to run_pair_DAG.sh to output job log with sat and track first
# 1b - add line to grdcut files to cut files
# 2 - add line to check for existence of *_ll.grd files; echo binary 1 or 0 for pass/fail 
#  e.g., pair_status = 1 
# 3 - add line to run_pair.sh and run_pair_SNT1A.sh to to find mean arc and print if exist

# set variables
if [[ $# -eq 0 ]]
then
 cp PAIRSmake.txt PAIRSmake_check.txt
 fname=PAIRSmake_check.txt
 fin=PAIRSmake.txt
elif [[ $# -eq 1 ]]
then
 fname=PAIRSmake_check.txt
 fin=$1
 cp $fin PAIRSmake_check.txt
 echo "checking pairs in $1"
else
 echo "too many arguments.  Optional argument for text file name only"
 exit 1
fi
user=`echo $HOME | awk -F/ '{print $(NF)}'`
echo $fname

echo $fin

# loop over PAIRSmake to find successful pairs
while read -r a b c d e f g h i j k l m n o p q r s t u v w x y z; do
   # ignore commented lines
    [[ "$a" =~ ^#.*$ && "$a" != [[:blank:]]  ]] && continue
   # set variables from PAIRSmake
    sat=$q
    if [[ "$sat" == "TDX" ]]
    then
      sat=TSX
    fi
    trk=$i
    filter_wv=$s
    mast=$a
    slav=$b
    fout=`find . -maxdepth 1 -name "${sat}_${trk}_In${mast}_${slav}*.out"`
echo FOUT = $fout
# touch .out file if pair didn't finish and doesn't have one
if [ -z $fout ]
then
# touch ${sat}_${trk}_In${mast}_${slav}.out
  > failedrun.tmp
  fout=failedrun.tmp
  echo "pair_status = 0" >> $fout
  echo "pha_std = nan" >> $fout
  echo "res_mean = nan" >> $fout
  echo "res_std = nan" >> $fout
  echo "res_nu = nan" >> $fout
  echo "t_crit = nan" >> $fout
  echo "t_stat = nan" >> $fout
fi
status=`grep pair_status ${fout} | awk '{print $3}'`
echo $status
# if status undefined, set equal to 0
if [[ -z $status ]]
then
  if [[ `grep unwrap_ll.grd ${fout} | wc -l` -gt 0 ]]
  then
    status=1
  else
    status=0
  fi
fi
#if [[ "status" -ne 0 ]]
#then
    pha_std=`grep pha_std ${fout} | awk '{printf("%#2.2f\n", $3)}'`
    res_mean=`grep res_mean ${fout} | awk '{printf("%#2.2f\n", $3)}'`
    res_std=`grep res_std ${fout} | awk '{printf("%#2.2f\n", $3)}'`
    res_nu=`grep res_nu ${fout} | awk '{printf("%#10d\n", $3)}'`

# get t statistics
t_crit=`grep abs_t_crit ${fout} | awk '{printf("%#2.2f\n", $3)}'`
t_stat=`grep abs_t_obs ${fout} | awk '{printf("%#10.2f\n", $3)}'`


# set any undefined statistics to NaN
#for var in "$pha_std" "$res_mean" "$res_std" "$res_nu"
#do
 if [ -z $pha_std ]
 then
   pha_std=NAN
   echo $var
   #varval=NAN
   #eval "$var=$varval"
   #echo $var ${!var}
 fi
 if [ -z $res_mean ]
 then
   res_mean=NAN
 fi
 if [ -z $res_std ]
 then
   res_std=NAN 
 fi
 if [ -z $res_nu ]
 then
   res_nu=NAN
 fi 
#done

echo $filter_wv
echo $mast
echo $slav

# update text file
#sed -i "/$mast $slav/c\@$(echo $mast $slav $c $d  $e $f $g $h $i $j $k $l $m $n $o $p $q $r $filter_wv 1 $status $pha_std $t_crit $t_stat $res_mean $res_std $res_nu $user | awk '{printf("%#8d %#8d %#5s %#5s %#7.4f %#7.4f %#5d %#5d %#5s %#1s %#10s %#5s %#5.4f %#6.1f %#6.1f %#5s %#5s %#25s %#3d %#1d %#1d %#2.2f %#2.2f %#3.2f %#2.2f %#2.2f %#5.2f %#10s \n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28)}')" $fname
#sed -i "/$mast $slav/c\@${a} $b $c $d $e $f $g $h $i $j $k $l $m $n $o $p $q $r $filter_wv 1 $status $pha_std $t_crit $t_stat $res_mean $res_std $res_nu $user" $fname
fline=`grep $mast $fname | grep $slav`
sed -i "/$fline/c\@$(echo $mast $slav $c $d  $e $f $g $h $i $j $k $l $m $n $o $p $q $r $filter_wv 1 $status $pha_std $t_crit $t_stat $res_mean $res_std $res_nu $user)" $fname
sed -i 's/@//g' $fname
#fi
done < $fin

# make sure text file has header, add one if not
header=`head -1 $fname`

if [[ "$header"  =~ ^#.*$ && "$a" != [[:blank:]]  ]]
then
  sed -i "/$header/c\#mast slav orb1 orb2 doy_mast doy_slav dt nan trk orbdir swath site wv bpar bperp burst sat dem processed unwrapped pha_std t_crit t_stat res_mean res_std res_nu user" $fname
else 
  sed -i '1 i\#mast slav orb1 orb2 doy_mast doy_slav dt nan trk orbdir swath site wv bpar bperp burst sat dem processed unwrapped pha_std t_crit t_stat res_mean res_std res_nu user' $fname
fi

cp $fname file.tmp
column -t file.tmp > $fname
rm file.tmp
