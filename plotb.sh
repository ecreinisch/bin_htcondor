gmtset PAPER_MEDIA = letter
gmtset D_FORMAT = %.12lg
gmtset BASEMAP_TYPE = plain
gmtset TICK_LENGTH = -0.2c
gmtset ANNOT_FONT_SIZE_PRIMARY = 8p
gmtset LABEL_FONT_SIZE = 8p
gmtset PLOT_DEGREE_FORMAT  = D 
makecpt -T-3.14159226418/3.14159226418/.1 > cpt
makecpt -T-5/5/.1 -Cpolar -D > cptr
region=-R-119.027/-118.995/39.78/39.815
days=`echo $1 | cut -c26-40 | sed 's/_/ /g' | sed 's/\(....\)/\1 /g' | awk '{print 365*(($3+$4/365)-($1+$2/365))}'`
pair=`echo $1 | cut -c1-19`
echo $pair $days
cat - <<EOF > prd.ll
   -119.02162947 39.79272711 4080.120 13 82A-11 WELL_82A-11_GRATE EXT 1826m
   -119.01244155 39.79715201 4098.810 17  48A-1 WELL_48A-1_TOP    EXT  389m
   -119.01199236 39.79831159 4101.080 19  47C-1 WELL_47C-1_FLANGE EXT  585m
   -119.01135267 39.79991062 4100.140 21   46-1 WELL_46-1_FLANGE  EXT  610m
   -119.01768238 39.79727838 4086.040 16   27-1 WELL_27-1_GRATE   EXT 1814m
   -119.02032118 39.79567731 4089.090 15   18-1 WELL_18-1_TOP     EXT 1753m
EOF
cat - <<EOF > inj.ll
   -119.00015870 39.81115547 4189.840 28 18B-31 WELL_18B-31_FLANGE INJ 235m
   -119.00059741 39.81040617 4185.480 27 18D-31 WELL_18D-31_FLANGE INJ 213m
   -119.00543534 39.74750304 4123.700  8  73-25 INJ_WELL_73-25_FLANGE  190m
EOF
cat - <<EOF > stm.ll
   -119.01875820 39.78671799 4077.380 12  15-12 WELL_15-12_TOP
EOF
grdimage $1 -Y1.25 -Ccpt -JM3 $region -P -B.01/.01::WSne -K -P> $2
cat prd.ll | awk '{print $1,$2}' | psxy $region -J -St0.125 -W1/0/0/0 -Gblack -O -K -V -P >> $2
cat inj.ll | awk '{print $1,$2}' | psxy $region -J -Si0.125 -W1/0/0/0 -Gblack -O -K -V -P >> $2
cat stm.ll | awk '{print $1,$2}' | psxy $region -J -Ss0.125 -W1/0/0/0 -Gblack -O -K -V -P >> $2
cat box.txt | awk '{print $1,$2}' | psxy $region -J -M -W2/0/0/0 -O -K -V -P >> $2
pstext -X0 -N -R -J -Gblack -O -K << EOF >> $2
-119.027 39.816 10 0 0 ML T53 pair $pair ($days days)
EOF
grdimage $3 -X3.25 -Ccptr -JM3 $region -P -B.01/.01::wSne -O -K >> $2
cat prd.ll | awk '{print $1,$2}' | psxy $region -J -St0.125 -W1/0/0/0 -Gblack -O -K -V -P >> $2
cat inj.ll | awk '{print $1,$2}' | psxy $region -J -Si0.125 -W1/0/0/0 -Gblack -O -K -V -P >> $2
cat stm.ll | awk '{print $1,$2}' | psxy $region -J -Ss0.125 -W1/0/0/0 -Gblack -O -K -V -P >> $2
cat box.txt | awk '{print $1,$2}' | psxy $region -J -M -W2/0/0/0 -O -K -V -P >> $2
psscale -Ccpt -D-1.75/-0.3/3/0.125h -Bf1a2:"Phase (radians)":/:: -O -K  >> $2
psscale -Ccptr -D1.5/-0.3/3/0.125h -Bf1a2:"Range change rate (radians/year)":/:: -O -K  >> $2
