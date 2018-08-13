#!/usr/bin/env python
# script for converting from lat/lon to UTM on command line
# 20170519 Elena C Reinisch

import utm
from sys import argv
script, lats, lons = argv
lati = float(lats)
loni = float(lons)
vals = utm.from_latlon(lati,loni)
easting = str(vals[0])
northing = str(vals[1])
uzone = str(vals[2])
print("Easting = " + easting)
print("Northing = " + northing)
print("Zone = " + uzone)

