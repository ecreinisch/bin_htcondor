#!/bin/bash
# script to make list of all available S1A aux_poeorb files for S1B
# Elena C Reinisch 20180605

# initialize file
> /s21/insar/S1B/aux_poeorb_S1B

# loop through page indexes for wget until the end is reached
pagen=0
page_next=1
> new_page.tmp
while [[ $page_next -gt 0 ]]; do  
  mv new_page.tmp old_page.tmp
  let pagen=pagen+1
  wget --no-check-certificate  https://qc.sentinel1.eo.esa.int/aux_poeorb/?page=${pagen} -O new_page.tmp
  # check to see if new queried page is different from last
  page_next=`diff new_page.tmp old_page.tmp | wc -l`
  # if page is different, add it to the master file
  if [[ $page_next -gt 0 ]]
  then
    grep S1B_OPER_AUX_POEORB_OPOD_ new_page.tmp | awk -F\" '{print $2}' >> /s21/insar/S1B/aux_poeorb_S1B
  fi
done

# update permissions
chmod a+w+r+x /s21/insar/S1B/aux_poeorb_S1B

# clean up
rm new_page.tmp old_page.tmp
