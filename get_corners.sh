#!/bin/bash -vex

# get corners of dem in radar (range,azimuth) coordinates
# 2021/07/07 Kurt Feigl

ref=${1}

# should be run in directory named "raw"
gmt grdinfo -C ../topo/dem.grd > tmp.info

cat tmp.info | awk '{printf("%20.10f %20.10f %20.10f\n",$2,$4,$6)}' >  corners.llt  # SW
cat tmp.info | awk '{printf("%20.10f %20.10f %20.10f\n",$3,$4,$6)}' >> corners.llt  # SE
cat tmp.info | awk '{printf("%20.10f %20.10f %20.10f\n",$3,$5,$7)}' >> corners.llt  # NE
cat tmp.info | awk '{printf("%20.10f %20.10f %20.10f\n",$2,$5,$7)}' >> corners.llt  # NW

SAT_llt2rat ${ref}.PRM 0 < corners.llt > corners.rallt
# more corners.rallt

# feigl@askja raw]$ more corners.rallt
# 13301.441414781 4681.999995738 1066.028717699 -119.375000000 40.347963000
# 10350.245744909 10968.000006099 1493.339669741 -119.460000000 40.448981000