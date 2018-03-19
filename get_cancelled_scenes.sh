#!/bin/bash
# shell script to call get_cancelled_scenes.py and grep to get relevant information
# use Cancelled_Orders.tmp as argument
# Elena C Reinisch 20170511
# update ECR 20180319 update for new bin_htcondor repo

#scene_file=$1

## get scene location
#grep 'tr class=" d0 "' -A1 $scene_file | grep td | awk -F\> '{print $2}' | awk -F\< '{print $1}'  | sed '/^$/d'  > site.tmp
#
## get strip
#grep 'tr class=" d0 "' -A2 $scene_file | grep strip  | awk -F\> '{print $2}' | awk -F\< '{print $1}' | sed '/^$/d'   > strip.tmp
#
## get track
#grep 'tr class=" d0 "' -A3 $scene_file | grep strip -A2 | sed "/strip/d" | awk -F\> '{print $2}' | awk -F\< '{print $1}'  | sed '/^$/d'  > track.tmp
#
## get epoch
#grep 'tr class=" d0 "' -A4 $scene_file | grep width | awk -F\> '{print $2}' | awk -F\< '{print $1}' | sed 's/-//g' | sed '/^$/d'  > epoch.tmp
#
## save to file
#paste epoch.tmp site.tmp track.tmp strip.tmp > list.tmp
#column -t list.tmp > Cancelled_Orders.txt
#
## clean up
##rm site.tmp strip.tmp track.tmp epoch.tmp list.tmp
touch Cancelled_Orders.txt
> new_orders.tmp
pagen=0
nlines=30

# pull down new info from WInSAR until overlap with already archived data
while [[ $nlines -ge 30 ]]
do
let pagen=pagen+1
if [[ $pagen == 3 ]]
then
    exit 1
fi
# pull down page from WInSAR archive
> Cancelled_Orders.tmp
python ~ebaluyut/bin_htcondor/get_cancelled_scenes.py ${pagen}
scene_file=Cancelled_Orders.tmp

# get cancelled scenes info
grep 'tr class=" d0 "' -A4 $scene_file > tmp_list.tmp
#nepochs=`grep 'tr class=" d0 "' $scene_file | wc -l`
nepochs=`grep 'tr class=" d0 "' tmp_list.tmp | wc -l`
echo $nepochs
nepochs=`echo $nepochs | awk '{print $1 * 6}'`
echo $nepochs
echo "--" >> tmp_list.tmp # add line to bottom to even out cancelled scenes to all have 6 lines
> orders.tmp

for count in $(seq 1 6 $nepochs); do
    epoch=`cat tmp_list.tmp | head -$(expr ${count} + 5) | tail -6 | head -5 | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}' | sed 's/-//g'`
    track=`cat tmp_list.tmp | head -$(expr ${count} + 5) | tail -6 | head -4 | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
    sat=TSX
    site=`cat tmp_list.tmp | head -$(expr ${count} + 5) | tail -6 | head -2 | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}' | sed 's/ //g' `
    estrip=`cat tmp_list.tmp | head -$(expr ${count} + 5) | tail -6 | head -3 | tail -1 | awk -F\> '{print $2}' | awk -F\< '{print $1}'`
    echo "$epoch $site $sat $track $estrip" >> orders.tmp 
done 

#

sort -u orders.tmp | column -t > tmp.tmp
# find file names that aren't in list yet
column -t Cancelled_Orders.txt > tmp2.tmp
comm -13  <(sort tmp2.tmp) <(sort tmp.tmp) >> new_orders.tmp

nlines=`comm -13 -i <(sort tmp2.tmp) <(sort tmp.tmp) | wc -l`
echo new lines = $nlines
rm tmp.tmp tmp2.tmp
done

if [[ `cat new_orders.tmp | wc -l` -gt 0 ]]
then
 sort new_orders.tmp >> Cancelled_Orders.txt
#column -t orders.tmp > Cancelled_Orders.txt
else
    rm new_orders.tmp
fi
