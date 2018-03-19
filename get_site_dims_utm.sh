#!/bin/bash
# script to give dimensions of interest (polygon) based on site 
#  e.g.: ./get_site_dims.sh brady 
#
# SITE 5 LETTER CODE NAMES
#
# brady - Bradys Hot Springs, NV, USA
# maule - Laguna del Maule, Chile
# mcgin - McGinness Hills
# dcamp - Don Campell
# cosoc - Coso, CA
# tungs - Tungsen
# emesa - East Mesa
# fallo - Fallon, NV
# milfo - Milford, UT
# fawns - Fawnskin
# 
# POLYGON INFORMATION
# order: W E S N
#
# brady: -119.03/-118.99/39.78/39.82
# maule:
# mcgini0: -116.95/-116.85/39.56/39.61
# mcgin: -117.011111111/-116.8/39.5/39.7
# dcampi0: -120.3/-117.299168/37.49916787/40.5
# dcamp: -118.35/-118.25/38.815/38.865
# cosoc:
# emesa: -115.332916666/-115.167083334/32.6670833334/32.91625
# fallo:
# milfo:
# fawns: -116.96/-116.85/34.33/34.39
# tungs: -117.6919090194407/-117.6849326882351/39.66684680613911/39.67244569755783
# dixie: -118.1384607218144/-117.9726034519923/39.76155907198107/39.83892561603565

SAREA=$1

case "$SAREA" in 
"brady")
  echo "-R326160/329680/4405200/4409800"
  ;;
"mcgin")
  echo "-R-117.011111111/-116.8/39.5/39.7"
  echo "-R499044.6776341409/-116.8/39.5/39.7"
  ;;
"fawns")
  echo "-R-116.96/-116.85/34.33/34.39"
  ;;
"dcamp")
  echo "-R382794.98/391553.08/4296989.34/4302661.57"
  ;;
"emesa")
  echo "-R655890/671880/3615600/3643500"
  ;;
"tinytungS")
  echo "-R440650/441260/4391000/4391600"
  ;;
"tungs")
  echo "-R436360/446500/4387800/4394100"
  ;;
"dixie")
  echo "-R402480/416780/4401700/4410500"
  ;;
"maule")
  #echo "-R318601.70/410443.39/5958730.92/6071045.93"
  echo "-R351757.36/378095.96/5992941.08/6020213.19"
  ;;
"malas")
  echo "-R500000/566526.35/6606865.46/6673685.07"
  ;;
"berin")
  echo "-R417604/637312.3/6652359.7/6709705.1"
  ;;
*)
  echo "not yet defined"
  ;;
esac 

