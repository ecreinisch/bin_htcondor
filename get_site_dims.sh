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
  echo "-R-119.03/-118.99/39.78/39.82"
  ;;
"mcgin")
  echo "-R-117.011111111/-116.8/39.5/39.7"
  ;;
"fawns")
  echo "-R-116.96/-116.85/34.33/34.39"
  ;;
"dcamp")
  echo "-R-118.35/-118.25/38.815/38.865"
  ;;
"emesa")
  echo "-R-115.332916666/-115.167083334/32.6670833334/32.91625"
  ;;
"tinytungS")
  echo "-R-117.6919090194407/-117.6849326882351/39.66684680613911/39.67244569755783"
  ;;
"tungs")
  echo "-R-117.741666364385/-117.6239574902617/39.63861234626911/39.69449737714895"
  ;;
"dixie")
  echo "-R-118.1384607218144/-117.9726034519923/39.76155907198107/39.83892561603565"
  ;;
"maule")
  echo "-R-71/-70/-36.5/-35.5"
  ;;
"colum")
  echo "-R-147.5/-146.3/60.91/61.5"
  ;;
"malas")
  echo "-R-141.0/-139.8/59.6/60.2"
  ;;
"berin")
  echo "-R-144.5/-142.5/60.0/60.5"
  ;;
"tians")
  echo "-R85.6/87.3/42.5/43.31"
  ;;
"kenne")
  echo "POLYGON((-143.6 61.7, -142.4 61.7, -142.4 61.3, -143.6 61.3, -143.6 61.7))"
  ;;
"peter")
  echo "-R-64.5/-56.0/80.0/81.5"
  ;;
*)
  echo "not yet defined"
  ;;
esac 

