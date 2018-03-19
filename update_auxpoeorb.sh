#!/bin/bash
# script to make list of all available S1A aux_poeorb files 
# to be run automatically every day or so to make sure list is up to date
# Elena C Reinisch 20170728

# pull first page and keep pulling pages until all new updates have been made
pagen=0
nlines=10
> new_eof.tmp

while [[ $nlines -ge 10 ]]; do
let pagen=pagen+1
wget --no-check-certificate  https://qc.sentinel1.eo.esa.int/aux_poeorb/?page=${pagen} -O new_page.tmp

# get file names only
grep S1A_OPER_AUX_POEORB_OPOD_ new_page.tmp | awk -F\" '{print $2}' > new_list.tmp

# find file names that aren't in list yet
comm -13 <(sort /s21/insar/S1A/aux_poeorb) <(sort new_list.tmp) | sort -r >> new_eof.tmp

nlines=`comm -13 <(sort /s21/insar/S1A/aux_poeorb) <(sort new_list.tmp) | sort -r | wc -l`
echo nlines = $nlines
done

if [[ `cat new_eof.tmp | wc -l` -gt 0 ]]
then
# add existing database to new list
cat /s21/insar/S1A/aux_poeorb >> new_eof.tmp

# replace existing database with updated one
mv new_eof.tmp /s21/insar/S1A/aux_poeorb

# update permissions
chmod a+w+r+x /s21/insar/S1A/aux_poeorb

else
 rm new_eof.tmp
fi

# clean up
rm new_list.tmp new_page.tmp
