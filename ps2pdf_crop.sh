#!/bin/bash
# ps2pdf and crop down images in list $1
# 2021/07/08 Kurt skip cropping
#while read -r a; do
filename=`echo $1 | awk -F. '{print $1}'`
ps2pdf $1
# pdfcrop $filename.pdf --margins 5
# mv $filename-crop.pdf $filename.pdf

#done < $1
