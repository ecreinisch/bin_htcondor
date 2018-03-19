#!/bin/bash
# to be run in intf directory
# calls new_profile_pair_brady.sh
# plots phase vs unwrapped range with profiles for each
# Elena Reinisch 20161015

# get pair list
find -type d -name "In2*" | awk -F/ '{print $2}' > InListA

# get individual pair profiles
new_profile_pair_brady.sh phasefilt_ll.grd phase
new_profile_pair_brady.sh unwrap_ll.grd range

# combine individual profile pairs
cd ../Profiles
while read -r a; do
# get names of ps files
pha_psname="${a}_phase"
unw_psname="${a}_unwrapped"
echo $pha_psname
echo $unw_psname

# join separate cropped images
gs -q -dNOPAUSE -dBATCH -sDEVICE=pswrite -sOutputFile=merged.pdf $pha_psname.pdf $unw_psname.pdf

# merge to one page
pdf2ps merged.pdf merged.ps

psnup -2 merged.ps > ${a}_${phadir}_vs_${unwdir}.ps

# clean up
rm merged.* $pha_psname.pdf $unw_psname.pdf
done < ../intf/InListA
cd ..


