#!/bin/bash
# Script to form PAIRSmake.txt for HTCondor GMTSAR workflow
# Takes Pairs list formed by egenerate_pairlist.sh
# Elena C Reinisch 20170123
# edit ECR 20170831 fix to -l and -g options; just take arg $7 
# edit ECR 20171128 add -o and -q options for month matching
# edit ECR 20180406 remove duplicate lines
# edit ECR 20180514 fix sed line for replacing outdated header

if [[ $# -eq 0 ]]
then
 echo "script to form PAIRSmake.txt for HTCondor GMTSAR workflow"
 echo "Required parameters are as follows:"
 echo "-f[val]: name of pair list (e.g., TSX_T53_brady_pairs.txt; see egenerate_pairlist.sh)"
 echo "-w[val] : assign a filter wavelength of [val] in m"
 echo "Optional parameters are defined as follows:"
 echo "-b[val] : print pairs with abs. perpendicular baseline <= [val]"
 echo "-M[val] : print pairs with master equal to [val] in yyyymmdd format"
 echo "-S[val] : print pairs with slave equal to [val]  in yyyymmdd format"
 echo "-m[val] : print pairs with master greater than or equal to [val] in yyyymmdd format"
 echo "-s[val] : print pairs with slave less than or equal to [val] in yyyymmdd format"
 echo "-d[val] : print pairs with time interval equal to [val] in days"
 echo "-l[val] : print pairs with time interval less than [val] in days"
 echo "-g[val] : print pairs with time interval greater than [val] in days"
 echo "-e[val] : print pairs designated in file [val]; format of [val] should have a column of master epochs in yyyymmdd format and a column of slave epochs in yyymmdd format"
 echo "-n[val] : print pairs that are NOT designated in file [val]; format of [val] should have a column of master epochs in yyyymmdd format and a column of slave epochs in yyymmdd format.  This is most likely to be used on submit-3 to re-run some pairs of the dataset."
 echo "-o[val] : print pairs with master month equal to [val] (e.g., 09, 10, etc)"
 echo "-q[val] : print pairs with slave month equal to [val] (e.g., 09, 10, etc)"
 echo "-p[val1/val2] : print successive pairs between val1 and val2; val1 and val2 should be in yyyymmdd format"
 echo "-w[val] : assign a filter wavelength of [val] in m"
 echo "Example - all pairs with master beginning in 2014 or later with wavelength of 100 m with perpendicular baseline less than or equal to 60 m"
 echo "bash-4.1$ generate_PAIRSmake.sh -fTSX_T91_brady_pairs.txt -b60 -m20140000 -w100"
 echo "Example - print pairlist of successive epochs between 2016-02-25 and 2016-04-15 with wavelength of 100 m"
 echo "bash-4.1$ generate_PAIRSmake.sh -fTSX_T91_brady_pairs.txt -p20160225/20160415 -w100"
 exit 1
fi

# sort through each flag
while getopts ":f:b:M:S:m:o:s:d:l:q:e:g:p:w:n:" opt; do
  case $opt in
    f) 
      echo "starting list is $OPTARG" >&2
      cp $OPTARG PAIRSmake.txt
      pairlist=$OPTARG
      ;;
    b)
      echo "print pairs with baseline <= $OPTARG" >&2
      awk -v var=$OPTARG 'sqrt($15^2) < var {print ;}' PAIRSmake.txt > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    M)
      echo "print pairs with master equal to $OPTARG" >&2
      awk -v var=$OPTARG '$1 == var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;; 
    S)
      echo "print pairs with slave equal to $OPTARG" >&2
      awk -v var=$OPTARG '$2 == var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    o)
      echo "print pairs with master month equal to $OPTARG" >&2
      #mast_month=`echo $OPTARG | awk '{print substr($1, 5, 2)}'`
      awk -v var=$OPTARG 'substr($1, 5, 2) == var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    #O) 
    #  echo "print pairs with master month equal to $OPTARG" >&2
      # check to see if input is a range
      #if [[ $OPTARG == *,* ]]  
      #then
      #  
      #else
      #  awk -v var=$OPTARG 'substr($1, 5, 2) == var {print ;}' PAIRSmake.txt  > pairs.tmp
      #  cp pairs.tmp PAIRSmake.txt
     # fi
   q)
      echo "print pairs with slave month equal to $OPTARG" >&2
      #mast_month=`echo $OPTARG | awk '{print substr($1, 5, 2)}'`
      awk -v var=$OPTARG 'substr($2, 5, 2) == var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    m)
      echo "print pairs with master greater than or equal to $OPTARG" >&2
      awk -v var=$OPTARG '$1 >= var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    s)
      echo "print pairs with slave less than or equal to $OPTARG" >&2
      awk -v var=$OPTARG '$2 <= var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    d)
      echo "print pairs with time interval equal to $OPTARG" >&2
      awk -v var=$OPTARG '($7) == var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    mm) 
      echo "print pairs with master month equal to $OPTARG" >&2
      mast_month=`echo $OPTARG | awk '{print substr($1, 5, 2)}'`
      awk -v var=$mast_month '$2 == var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    p)
      echo $OPTARG
      tstart=`echo $OPTARG | awk -F/ '{print $1}'`
      tend=`echo $OPTARG | awk -F/ '{print $2}'`
      echo "print successive pairs between $tstart and $tend"
      awk -v var=${tstart} '$1 >= var {print ;}' PAIRSmake.txt | awk -v var=${tend} '$2 <= var {print $1, $2;}' | awk '!a[$1]++' > lst.tmp
       > pairs.tmp
      while read -r a b; do
        grep $a PAIRSmake.txt | grep $b >> pairs.tmp
      done < lst.tmp
      rm lst.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    l)
      echo "print pairs with time interval less than $OPTARG" >&2
      awk -v var=$OPTARG '($7) < var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    w)
      echo "print pairs with filter wavelength set to $OPTARG m" >&2
      #sed -e 's/$/ $OPTARG/' -i  PAIRSmake.txt  > pairs.tmp
      awk -v var=$OPTARG '{print $0, var}' PAIRSmake.txt > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    e) 
      echo "print pairs using epoch pairs in $OPTARG"
      > pairs.tmp
      while read -r a b; do
        mast=$a
        slav=$b
        echo "`grep $mast PAIRSmake.txt | grep $slav`" >> pairs.tmp
      done < $OPTARG
      cp pairs.tmp PAIRSmake.txt
      ;;
    g)
      echo "print pairs with time interval greater than $OPTARG" >&2
      awk -v var=$OPTARG '($7) > var {print ;}' PAIRSmake.txt  > pairs.tmp
      cp pairs.tmp PAIRSmake.txt
      ;;
    n)
      echo "print pairs that are not in list $OPTARG"
      #cp PAIRSmake.txt pairs.tmp
      > lst.tmp
      while read -r a b; do
        mast=$a
        slav=$b
        echo "`grep $mast PAIRSmake.txt | grep $slav`" >> lst.tmp
      done < $OPTARG
      awk 'FNR==NR {a[$0]++; next} !a[$0]' lst.tmp PAIRSmake.txt > pairs.tmp
      rm lst.tmp
      #while read -r a b; do
      #  mast=$a
      #  slav=$b
      #  xline=`grep $mast PAIRSmake.txt | grep $slav`
      #  echo $xline
      #  sed -i '/${xline}/d' ./pairs.tmp
      #done < $OPTARG
      cp pairs.tmp PAIRSmake.txt
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

# add header
# make sure text file has header, add one if not
header=`head -1 PAIRSmake.txt`

if [[ "$header"  =~ ^#.*$ && "$a" != [[:blank:]]  ]]
then
  sed -i "/#/c\#mast slav orb1 orb2 doy_mast doy_slav dt nan trk orbdir swath site wv bpar bperp burst sat dem processed unwrapped pha_std t_crit t_stat res_mean res_std res_nu user" PAIRSmake.txt
else
  sed -i '1 i\#mast slav orb1 orb2 doy_mast doy_slav dt nan trk orbdir swath site wv bpar bperp burst sat dem processed unwrapped pha_std t_crit t_stat res_mean res_std res_nu user' PAIRSmake.txt
fi

# clean up
 awk '!seen[$0]++' PAIRSmake.txt > file.tmp 
 column -t file.tmp > PAIRSmake.txt
 rm pairs.tmp file.tmp
