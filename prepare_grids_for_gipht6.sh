#!/bin/bash -vx
# add -vex to above line for diagnostic purposes  
# based on file from Kurt Feigl
# edit Elena Reinisch 20160909 add subregions for Brady, McGinness Hills,  and Fawnskin
# takes argument for study area:
# mcgh - McGinness Hills
# fawn - Fawnskin
# brady - Bradys
# 20170215 ECR edit for HTC use
# 20170307 ECR edit to incorporate change from RAW to preproc dir names
# 20170413 ECR add dyear to grd file comments
# 20170418 ECR update region information to pull from get_site_dims.sh
# 20170418 KLF & SAB create geotif files, too
# 20170421 ECR & KLR & SAB remove proj_ra2ll lines
# 20170530 ECR switch to converting to UTM using grd2xyz & mapproject 
# 20170713 ECR add creation of drange (range change rate in m per year)
# 20170724 ECR include Sam's leapfrog scripts
# 20170914 ECR more robust for PRM files
# 20170926 Kurt and Sam - update RANGES for tungs
# 20180319 ECR update for new bin_htcondor repo
# 20180327 ECR update for new gmtsar-aux layout
# 20180327 ECR update for new get_site_dims.sh
# 20180418 ECR update removing outdated line for amp_utm
# 20180829 ECR update to make robust for southern hemisphere areas
# 20200128 KLF update to use phase_filt_ll
# 20200129 KLF handle missing files better
# 20200325 KLF handle gmt grdsample: Error: Selected region exceeds the Y-boundaries of the grid file by more than one y-increment!
# 20200416 KLF project amp and coherence to UTM, also
# 20210708 KLF port to GMT v. 6
# 20211021 SAB fixed typo in variable name ${sece} --> ${sec}, changed source of *colortable*.txt files to siteinfo. 
#              Noticed that /usr/bin/ programs like gdal and gs not available in container
# 20211028 KLF & SAB - rearrange to work only in current working directory (rather than In*) 
#                      because this script is called from post_process.sh (launched by run.sh inside each In* directory 
#                      and not by retreieve_pairs anymore.
#                    - comment out calls to gdal

if [[ $# -eq 0 ]]; then
    cat - << ENDOFDOC
$0:t Last modification 20160819

Prepare files from GMT for input into GIPhT version 3.0

Takes argument of site ID
e.g.: prepare_grds_for_gipht6.sh brady

ENDOFDOC

    exit 1

else
    SAREA=$1 #`pwd | awk -F/gipht '{print $1}' | awk -F/ '{print $2}'`

    # set Region of interest here W/E/S/N in degrees
    echo $SAREA
    RANGES=`get_site_dims.sh $SAREA 1`
    URANGES=`get_site_dims.sh $SAREA 2`
    ZONE=`get_site_dims.sh $SAREA 3` 
    echo $RANGES
    echo $ZONE

    STARTDIR=$PWD
 
   # go to the place where we have interfegograms   
    # loop over all possible pa-R-119.03/-118.99/39.78/39.82s 3-digit day of year
    #for PAIR in `ls -d In*_*`; do
    #for PAIR in `find ${SITE}* -mindepth 1 -maxdepth 1 -type d -name "In*_*"`; do
    #for PAIR in "/s12/insar/TSX/T30/forge/feigl_20210711/In20200426_20210126"; do
    #for PAIR1 in `find . -maxdepth 1 -type d -name "In*_*"`; do 
        echo "PWD is now $PWD"
        PAIR1=`pwd`
        echo "Now working on pair ${PAIR1}"
        #cd ${PAIR1}
        #PAIR="In20200426_20210126"
        PAIR=`basename ${PAIR1}`
        echo "PAIR is now ${PAIR}"

        if [[ -e "phasefilt_ll.grd" ]] ; then
	    echo "now working on phasefilt_ll.grd"
            # Clarify name to distinguish (lon,lat) from UTM (easting, northing)
            DEM=dem.grd
            if [[ ! -e dem_ll.grd ]]; then
                \cp -v $DEM dem_ll.grd
            fi

            # find increments from DEM
            incx=`gmt grdinfo $DEM -Vq | grep x_inc | awk '{print $7}'` ; echo incx is $incx
            incy=`gmt grdinfo $DEM -Vq | grep y_inc | awk '{print $7}'` ; echo incy is $incy

            echo INCX = $incx
            echo INCY = $incy

            #cp *.PRM ../../preproc/

            # remove any old files
            echo "Deleting old files...."
            \rm -rfv *utm*.grd *cut*.grd

            # take real and imagingary parts
            # 20200128 do  NOT use unmasked versions
            #gmt grdmath phasefilt_ll.grd COS = refilt_ll.grd
            #gmt grdmath phasefilt_ll.grd SIN = imfilt_ll.grd
            #gmt grdmath phase_ll.grd COS = re_ll.grd
            #gmt grdmath phase_ll.grd SIN = im_ll.grd
            # 20200128 use masked versions
            gmt grdmath phasefilt_mask_ll.grd COS = refilt_ll.grd
            gmt grdmath phasefilt_mask_ll.grd SIN = imfilt_ll.grd
            gmt grdmath phase_mask_ll.grd COS = re_ll.grd
            gmt grdmath phase_mask_ll.grd SIN = im_ll.grd

            # find the name of the parameter file 
            imast=`echo $PAIR | awk -F_ '{print $1}' | awk -Fn '{print $2}'`
            prmfile=$imast.PRM
            echo prmfile is $prmfile

            # cut each grid file
            for GRD in  dem_ll.grd drhomaskd_ll.grd re_ll.grd display_amp_ll.grd im_ll.grd refilt_ll.grd imfilt_ll.grd corr_ll.grd; do
                if [[ -e $GRD ]];then 
                    # 20200325 next line throws error 
                    # gmt grdsample $GRD $RANGES -I$incx/$incy -r -V -G`echo $GRD | sed 's/ll/ll_cut/'`
                    # cut first, then resample 
                    # http://gmt.soest.hawaii.edu/doc/5.3.2/gmt.html#n-full
                    #-n[b|c|l|n][+a][+bBC][+c][+tthreshold]
                    # find fringe spacing in m
                    metersperfringe=`grep radar_wavelength $prmfile | awk 'NR == 1 {print $3/2.}'`

                    # second try at fringe spacing if can't read from PRM
                    if [[ -z $metersperfringe || $metersperfringe == 0 ]];then
                        metersperfringe=`tail -1 ../PAIRSmake_check.txt | awk '{print $13/2}'`
                    fi

                    echo metersperfringe is $metersperfringe
                    echo "working on $GRD"

		    # convert from radians to meters
                    if [[ -e unwrap_mask_ll.grd ]]; then
                        gmt grdmath unwrap_mask_ll.grd ISFINITE unwrap_mask_ll.grd MUL PI DIV 2.0 DIV $metersperfringe MUL = drhomaskd_ll.grd
                    fi

                    #Select grid interpolation mode by adding b for B-spline smoothing, 
                    # c for bicubic interpolation, l for bilinear interpolation, or 
                    # n for nearest-neighbor value (for example to plot categorical data). 
                    # Optionally, append +a to switch off antialiasing (where supported). 
                    # Append +bBC to override the boundary conditions used, adding g for geographic, p for periodic, or n for natural boundary conditions. 
                    # For the latter two you may append x or y to specify just one direction, otherwise both are assumed. 
                    # Append +c to clip the interpolated grid to input z-min/max [Default may exceed limits]. 
                    # Append +tthreshold to control how close to nodes with NaNs the interpolation will go. 
                    # A threshold of 1.0 requires all (4 or 16) nodes involved in interpolation to be non-NaN. 
                    # 0.5 will interpolate about half way from a non-NaN value; 0.1 will go about 90% of the way, etc. 
                    # [Default is bicubic interpolation with antialiasing and a threshold of 0.5, using geographic 
                    # (if grid is known to be geographic) or natural boundary conditions].
		    echo "trying this command: gmt grdcut $GRD $RANGES -N -V -Gtemp.grd"
                    gmt grdcut $GRD $RANGES -N -V -Gtemp.grd
                    gmt grdsample temp.grd -I$incx/$incy -r -V -G`echo $GRD | sed 's/ll/ll_cut/'`
                fi
            done # loop over grid files to be cut

            # project cut grids into UTM
            for GRD in dem_ll.grd drhomaskd_ll.grd re_ll.grd display_amp_ll.grd im_ll.grd refilt_ll.grd imfilt_ll.grd corr_ll.grd; do
                if [[ -e $GRD ]]; then 
                    CUTGRD=`echo $GRD | sed 's/ll/ll_cut/'`
                    UTMGRD=`echo $GRD | sed 's/ll/utm/'`

                    echo UTMGRD is now $UTMGRD
                        # note that the plus sign in the -Ju switch assumes northern hemisphere
                    if [[ $UTMGRD == "re"* || $UTMGRD == "im"* || $UTMGRD == "drhomaskd"* || $UTMGRD == *".grd" ]]; then
                        gmt grdproject $CUTGRD -Ju$ZONE/1:1 -C -F $RANGES -G$UTMGRD  
                    else
                        # convert grd file to temporary text file
                        grd2xyz $CUTGRD > grd_ll.tmp
                        mapproject grd_ll.tmp -Ju$ZONE/1:1 -C -F > grd_utm.tmp
                        xnodes=`gmt grdinfo $CUTGRD -C | awk '{print $10}'`
                        ynodes=`gmt grdinfo $CUTGRD -C | awk '{print $11}'`
                        deltax=`echo ${URANGES}/${xnodes}/${ynodes} | awk -FR '{print $2}' | awk -F/ '{print ($2-$1)/($5-1)}'`
                        deltay=`echo ${URANGES}/${xnodes}/${ynodes} | awk -FR '{print $2}' | awk -F/ '{print ($4-$3)/($6-1)}'`
                                #echo XNODES = $xnodes
                                #echo YNODES = $ynodes
                        if [[ $deltax < 0  ]]; then
                            deltax=`echo $deltax | awk '{print (-1)*$1}'`
                        fi
                        if [[ $deltay < 0 ]]; then
                            deltay=`echo $deltay | awk '{print (-1)*$1}'`
                        fi
                        #echo deltax = $deltax
                        #echo deltay = $deltay
                        #echo URANGES = $URANGES
                        #echo "CUTGRD is" $CUTGRD
                        gmt nearneighbor grd_utm.tmp -I${deltax}/${deltay} -N4 -S100 ${URANGES}+ue -G$UTMGRD
                        \rm -f grd_utm.tmp grd_ll.tmp  
                    fi
                fi 
            done # loop over GRD files for single PAIR

            if [[ "$SAREA" == "brady" ]]; then 
                    # copy unwrapped grid to grid with far field displacement subtracted out
                    #gmt grdmath drhomaskd_utm.grd -Rk328.5/329.5/4405/4406 MEAN = tmp_mean.grd
                    #gmt grdmath drhomaskd_utm.grd $URANGES MEAN = tmp_mean.grd
                gmt grdmath drhomaskd_utm.grd -R326500/327500/4408500/4409500 MEAN = tmp_mean.grd
                RHOMEAN=`gmt grdinfo tmp_mean.grd | grep z_min | awk '{print $3}'`
                gmt grdmath drhomaskd_utm.grd $RHOMEAN SUB = drhomaskd0_utm.grd
                \rm -f tmp_mean.grd
            fi

            # edit metadata in grd file headers
            # -Dxname/yname/zname/scale/offset/invalid/title/remark 
            ref=`echo $PAIR | awk -F_ '{print $1}' | awk -FIn '{print $2}'`
            sec=`echo $PAIR | awk -F_ '{print $2}'`
            dref=`grep SC_clock_start ${ref}*.PRM | awk '{print $3}'`
            dsec=`grep SC_clock_start ${sec}*.PRM | awk '{print $3}'`

            gmt grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"m"/1///"elevation"/"dyear(mast) = ${dref}; dyear(sec) = ${dsec}; m/fringe = ${metersperfringe}"        dem_utm.grd
            if [[ -e drhomaskd_utm.grd ]]; then 
                gmt grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"m"/1///"range change"/"dyear(mast) = ${dref}; dyear(sec) = ${dsec}; m/fringe = ${metersperfringe}" drhomaskd_utm.grd
            fi 

            # make grd file for unwrapped range change rate [m/yr] named drange_utm.grd; edit comments
            # script also makes tif files
            if [[ -e drhomaskd_utm.grd ]];then
                drhomaskd2drangeperyr.sh drhomaskd_utm.grd

                # #commands to make geotiff version of drhomaskd_utm
                # gmt grdconvert drhomaskd_utm.grd=nf out_drho.tif=gd:GTiFF
                # gdal_translate -a_srs EPSG:32611 out_drho.tif drhomaskd_utm.tif
            fi

            # convert real and imaginary parts back into wrapped phase
            gmt grdmath imfilt_utm.grd refilt_utm.grd ATAN2 = phasefilt_mask_utm.grd 
            gmt grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"radians"/1///"wrapped phase"/"dyear(mast) = ${dref}; dyear(sec) = ${dsec}" phasefilt_mask_utm.grd 
            gmt grdmath im_utm.grd re_utm.grd ATAN2 = phase_mask_utm.grd
            gmt grdedit -D"UTM zone $ZONE Easting in meters"/"UTM zone $ZONE Northing in meters"/"radians"/1///"wrapped phase"/"dyear(mast) = ${dref}; dyear(sec) = ${dsec}" phase_mask_utm.grd

            ##commands to make geotiff version for phasefilt_utm
            # gmt grdconvert phasefilt_mask_utm.grd=nf out_filt.tif=gd:GTiFF
            # gdal_translate -a_srs EPSG:32611 out_filt.tif phasefilt_mask_utm.tif
            # gmt grdconvert phase_mask_utm.grd=nf out_p.tif=gd:GTiFF
            # gdal_translate -a_srs EPSG:32611 out_p.tif phase_mask_utm.tif

            # perform quad-tree resampling
            #/Users/feigl/gipht/pha2qls/pha2qls1.csh -i phasefilt_utm.grd -L 24 -M 8 -N 4 
            #commented out because script no available on maule
            #csh -f pha2qls.csh -i phasefilt_utm.grd -L 24 -M 8 -N 4 

            #gmt grdinfo phasefilt_utm.grd

            # make geotiffs for amp and display_amp
            #gmt grdconvert amp_utm.grd=nf out_amp.tif=gd:GTiFF
            #gdal_translate -a_srs EPSG:32611 out_amp.tif amp_utm.tif
            # echo converting display_amp_utm.grd
            # gmt grdconvert display_amp_utm.grd=nf out_display_amp.tif=gd:GTiFF
            # gdal_translate -a_srs EPSG:32611 out_display_amp.tif display_amp_utm.tif

            # make Sam's leapfrog geotiff files
	        echo "present working directory is ${PWD}"
            ref=`echo $PAIR | awk -FIn '{print $2}' | awk -F_ '{print $1}'`
            sec=`echo $PAIR | awk -F_ '{print $2}'`
            if [[ -e phasefilt_mask_utm.tif ]]; then
		        cp ../siteinfo/phasefilt_colortable_UInt16.txt .
                #cp $HOME/FringeFlow/gmtsar-aux/phasefilt_colortable_UInt16.txt .
                make_leapfrog_geotiffs.sh phasefilt_mask_utm.tif ${ref} ${sec}
            fi
            if [[ -e drange_utm.tif ]]; then
                cp ../siteinfo/drange_colortable_UInt16.txt .
		        #cp $HOME/FringeFlow/gmtsar-aux/drange_colortable_UInt16.txt .
                make_leapfrog_geotiffs.sh drange_utm.tif ${ref} ${sec} 
            fi
            \rm -f phasefilt_colortable_UInt16.txt drange_colortable_UInt16.txt

            # clean up
            \rm -f tmp.grd re_ll.grd im_ll.grd re_utm.grd im_utm.grd tmp *cut*.grd *out*.tif *out*.xml refilt_ll.grd imfilt_ll.grd

            # make unit vector files
            gmt grd2xyz phasefilt_ll.grd  > ${PAIR}_llt.txt
            #gmt gmtconvert trans.dat -bi5 | awk '{print $4, $5, $3}' | column -t > ${PAIR}_llt.txt

            # calculate relative orbit information
            SAT_baseline $ref.PRM $sec.PRM > ${PAIR}_baseline.txt
            # find perpendicular component of baseline
            bperp=`grep B_perpendicular ${PAIR}_baseline.txt | awk '{print $3}'`
            echo bperp is $bperp meter

            # write metadata for gipht
            # grd_file_namesPHA1.ilist
            # grd_file_names.data
            # YYYYMMDD1 YYYYMMDD2 IDATATYPE MPERCY   FNAME
            #  19920807 19930618  0         0.028333  ../In19920807_19930618/phasefilt_utm.grd          % wrapped phase in radians         in UTM coordinates
            #  19920807 19930618  2         0.028333  ../In19920807_19930618/drhomaskd_utm.grd          % unwrapped range change in meters in UTM coordinates
            
            # get time span in days
            # https://stackoverflow.com/questions/9008824/how-do-i-get-the-difference-between-two-dates-under-bash
            #let daydiff=(`date +%s -d $dsec`-`date +%s -d $dref`)/86400
            daydiff="NaN"
            echo time span is $daydiff days
            
            echo "YYYYMMDD1 YYYYMMDD2 IDATATYPE MPERCY   FNAME" > grd_file_namesPHA.ilist
            echo "YYYYMMDD1 YYYYMMDD2 IDATATYPE MPERCY   FNAME" > grd_file_namesRHO.ilist
            echo "$ref $sec 0 $metersperfringe ${PAIR}/phasefilt_utm.grd  % wrapped phase in radians in UTM coordinates"        >> grd_file_namesPHA.ilist
            echo "$ref $sec 2 $metersperfringe ${PAIR}/drhomaskd_utm.grd  % unwrapped range change in meters in UTM coordinates" >> grd_file_namesRHO.ilist
            echo "YYYYMMDD1 YYYYMMDD2 IDATATYPE MPERCY BperpInMeters  TimeSpanInDays FNAME" > grd_file_namesPHA.plist
            echo "YYYYMMDD1 YYYYMMDD2 IDATATYPE MPERCY BperpInMeters  TimeSpanInDays FNAME" > grd_file_namesRHO.plist
            echo "$ref $sec 0 $metersperfringe $bperp $daydiff ${PAIR}/phasefilt_utm.grd  % wrapped phase in radians in UTM coordinates"         >> grd_file_namesPHA.plist
            echo "$ref $sec 2 $metersperfringe $bperp $daydiff ${PAIR}/drhomaskd_utm.grd  % unwrapped range change in meters in UTM coordinates" >> grd_file_namesRHO.plist

            
            echo "Finished pair $PAIR and created:"
            \ls -l *utm*.grd
            #\ls -l *utm*.tif
        fi
        cd $STARTDIR
    #done # loop over PAIR

    # # collect look vectors into single file
    # cd ../preproc
    # find ../intf -name "*_llt.txt" > llt.tmp 
    # echo "#pair look_e look_n look_u" > unit_vectors.txt
    # while read -r a; do
    #     ref=`echo $a | awk -F/ '{print $(NF)}' | awk -FIn '{print $2}' | awk -F_ '{print $1}'`
    #     sec=`echo $a | awk -F/ '{print $(NF)}' | awk -FIn '{print $2}' | awk -F_ '{print $2}' | awk -F_llt '{print $1}'`
    #     if [[ `pwd` == *"ALOS"* ]]
    #     then
    #         ALOS_look ${ref}.PRM < $a > In${ref}_${sec}-orb.txt
    #     else
    #         SAT_look ${ref}.PRM < $a > In${ref}_${sec}-orb.txt
    #     fi
    #         #echo In${ref}_${sec} `awk '{print $4, $5, $6; next}' In${ref}_${sec}-orb.txt | awk '{++a[$0]}END{for(i in a)if(a[i]>max){max=a[i];k=i}print k}'` >> unit_vectors.txt
    #     unit_vector=`cat In${ref}_${sec}-orb.txt | awk '{print $4, $5, $6}' | sort | uniq -c | sort -r | head -1|  xargs | cut -d" " -f2-`
    #     echo "In${ref}_${sec} $unit_vector"  >> unit_vectors.txt
    #     done < llt.tmp
    # rm -f llt.tmp
    # cd ../gipht

    echo "completion of if statement of prepare_grds_for_gipht6.sh (called by post_process.sh)."
    echo "we are now in directory $PWD"
 fi

#commands to make geotiff version for amp_utm.grd
#../intf/In${ref}_${sec}/

#gmt grdconvert ../intf/In${ref}_${sec}/amp_utm.grd=nf ../intf/In${ref}_${sec}/out_amp.tif=gd:GTiFF
#gdal_translate -a_srs EPSG:32611 ../intf/In${ref}_${sec}/out_amp.tif ../intf/In${ref}_${sec}/amp_utm.tif
#gmt grdconvert ../intf/In${ref}_${sec}/display_amp_utm.grd=nf ../intf/In${ref}_${sec}/out_diaplay_amp.tif=gd:GTiFF
#gdal_translate -a_srs EPSG:32611 ../intf/In${ref}_${sec}/out_display_amp.tif ../intf/In${ref}_${sec}/display_amp_utm.tif


#exit 1

