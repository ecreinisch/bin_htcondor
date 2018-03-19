#!/bin/bash

phadir=$1
unwdir=$2

# get pair list
find $phadir -name "In2*" | awk -F/ '{print $2}' | awk -F. '{print $1}' > InListA

# get individual pair profiles
~/SCRIPTS/profile_pair_brady.sh $phadir phase
~/SCRIPTS/profile_pair_brady.sh $unwdir range



# combine individual profile pairs
cd Profiles
while read -r a; do
# get names of ps files
pha_psname=${a}_`echo $phadir | awk -F_ '{print $1}'`
unw_psname=${a}_`echo $unwdir | awk -F_ '{print $1}'`
echo $pha_psname
echo $unw_psname

~/SCRIPTS/ps2pdf_crop.sh $pha_psname.ps
~/SCRIPTS/ps2pdf_crop.sh $unw_psname.ps

# join separate cropped images
gs -q -dNOPAUSE -dBATCH -sDEVICE=pswrite -sOutputFile=merged.pdf $pha_psname.pdf $unw_psname.pdf

# merge to one page
pdf2ps merged.pdf merged.ps

psnup -2 merged.ps > ${a}_`echo $phadir | awk -F_ '{print $1}'`_vs_`echo $phadir | awk -F_ '{print $1}'`.ps

# clean up
rm merged.* 
done < ../InListA
cd ..


