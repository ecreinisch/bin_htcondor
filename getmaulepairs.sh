#!/bin/bash
# given a list of pairs with maule pwd (e.g., ebaluyut@maule.ssec.wisc.edu:/s21/insar/ERS2/T485/brady/In19951105_20060903.tgz), use scp to get pair
# run in main site directory with intf as subdirectory
# Elena C Reinisch 20170622


while read -r a; do
 scp $a intf/
done < $1
