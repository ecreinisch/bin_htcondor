#!/bin/bash
# given a list of pairs with maule pwd (e.g., /s21/insar/ERS2/T485/brady/In19951105_20060903.tgz), copy pairs to intf subdirectory on maule
# run in main site directory with intf as subdirectory
# Elena C Reinisch 20190520
# 20200128 Kurt move rather than copy


while read -r a; do
# #cp $a intf/ # copy for now, in case we need to run the same pairs on porotomo
if [[ -e $a ]]
then
 mv -v $a intf/ # use once porotomo server is obsolete in workflow
fi 
done < $1

#\mv -v In*.tgz intf

