#!/bin/bash
# script to give utm zone based on site 
#  e.g.: ./get_site_utmzone.sh brady 
# 20171205 Kurt 
# SITE 5 LETTER CODE NAMES
#
# brady - Bradys Hot Springs, NV, USA
# maule - Laguna del Maule, Chile (negative for southern hemisphere)
# mcgin - McGinness Hills
# dcamp - Don Campell
# cosoc - Coso, CA
# tungs - Tungsen
# emesa - East Mesa
# fallo - Fallon, NV
# milfo - Milford, UT
# fawns - Fawnskin
# 

SAREA=$1

case "$SAREA" in 
"brady")
  echo "11"
  ;;
"mcgin")
  echo "11"
  ;;
"fawns")
  echo "11"
  ;;
"dcamp")
  echo "11"
  ;;
"emesa")
  echo "11"
  ;;
"tungs")
  echo "11"
  ;;
"dixie")
  echo "11"
  ;;
"malas")
  echo "7"
  ;;
"maule")
  echo "-19"
  ;;
*)
  echo "not yet defined"
  ;;
esac 

