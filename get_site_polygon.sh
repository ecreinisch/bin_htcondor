#!/bin/bash
# script to give polygon based on site 
# 20180327 Elena C Reinisch

if [[ $# -eq 0 ]]; then
  echo "script to give polygon based on site"
  echo "usage: get_site_polygon.sh [site]"
  echo "e.g., get_site_dims.sh brady"
  exit 1
fi

site=$1

if [[ `grep $site ~ebaluyut/gmtsar-aux/site_poly.txt | wc -l` -gt 0 ]]; then
  echo $(grep $site -A1 ~ebaluyut/gmtsar-aux/site_poly.txt | tail -1)
else
  echo "site undefined."
  exit 1
fi
