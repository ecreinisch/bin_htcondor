#!/bin/bash -vex
#!/usr/bin/env -S bash -x
# for debugging, add "-vx" switch after "bash" in the shebang line above.
# switches in line above:
#      -e exit on error
#      -v verbose
#      -x examine
# run_pair_gmtsarv60.sh (this script)
# how to run a pair of insar images 20160804 Kurt Feigl
#
# edit 20170218 Elena C Reinisch, change S1A setup for preprocessing per pair; save PRM and LED files to output
# edit 20170710 copy data from maule during job, send email when job has finished; transfer pair directly to maule 
# edit 20170801 ECR update to copy maule ALOS data with frame in the name
# edit 20171114 ECR comment out renaming of p2p_TSX script for airbus and instead add $site to pair2e.sh call
# edit 20180406 ECR update to pull from new bin_htcondor repo
# edit 20200124 KF/SAB update to share geoscience group directory
# edit 20201227 Kurt fix bug that stops run before geocoding
# edit 20200406 Kurt and Sam try to fix bug about disk usage exceedes request
# edit 20201106 Sam changed shebang from #!/bin/bash to #!/usr/bin/env bash as recommended by TC -- updated maule to askja and s21 to s12
# edit 20201130 Sam and Kurt set name of GMTSAR package to GMTSAR_v60

# edit 20201201 set up environment variables with path names for GMT and GMTSAR
# note 20201201 this is where software is unbundled for submit-2 (yes) bundled in the DAG version of this script - batzli
# edit 20201202 batzli added usage
# edit 20201228 batzli added some breaks for troublshooting
# edit 20210305 batzli ran successful pair, removed exit before result file cutting, moving, and cleanup, moved a >cd and actual >./run.sh to pair2e.sh
# edit 20210308 batzli added ${unwrap} variable ("value" [.12] or empthy) to pass through from run_pair_DAG_gmtsarv60.sh to here (run_pair_gmtsarv60.sh) then to pair2e.sh

if [[ ! $# -eq 14 ]] ; then
    echo '	ERROR: $0 requires 14 arguments.'
    echo '	Usage: run_pair_gmtsarv60.sh sat trk ref sec user satparam demf filter_wv xmin xmax ymin ymax site'
    echo '	$1=sat'
    echo '	$2=trk'
    echo '	$3=ref (reference image date in YYYYMMDD) formerly mast' 
    echo '	$4=sec (secondary image date in YYYYMMDD) formerly slav'
    echo '	$5=user'
    echo '	$6=satparam (for TSX this is strip number)'
    echo '	$7=demf (DEM filename)'
    echo '	$8=filter_wv (filter wavelength)'
    echo '	$9,${10},${11},${12} are xmin xmax ymin ymax'
    echo '	${13}=site'
    echo '	${14}=unwrap (value or empty) default empty will not unwrap)'
    echo '	Example: run_pair_gmtsarv60.sh TSX T144 20180724 20181203 feigl strip_007R tusca_dem_3dep_10m.grd 80 -116.1900101030447 -116.0749982018097 41.41245177646995 41.49864121097495 tusca y'
    exit 0
fi

# save account name for askja (this is for HTCondor when user name is different there, which it is for batzli/sabatzli)
if [[ $USER == "sabatzli" ]] ; then
	echo "Sams case"
	# login name is different on remote machine
	askja="batzli@askja.ssec.wisc.edu"
else
	# login name is the same on both machines
	askja=${USER}'@askja.ssec.wisc.edu'
fi
echo askja is: $askja
s12=$askja:/s12

#source the setup for Askja
#source setup_gmtsarv60.sh
#echo askja is $askja
#echo s12 is $s12

# set satellite and track
sat=${1}
trk=${2}
# set reference and secondary variables
ref=${3}
sec=${4}
orb1a=`expr $ref - 1`
orb2a=`expr $sec - 1`
user=${5}
satparam=${6} # extra parameter for satellite specific parameters (e.g., for S1A satparam = subswath number)
demf=${7}
# set filter wavelength
filter_wv=${8}
# set region variables
xmin=${9}
xmax=${10}
ymin=${11}
ymax=${12}
site=${13}
unwrap=${14}

# set up ssh transfer (for HTCONDOR only, [missing destination dir?] move up to conditional)

# conditional for server name
if [[ "$HOSTNAME" == "askja.ssec.wisc.edu" ]] ; then
	echo "Running on Askja as user: ${user}"
	if [[ -d "/s12/${user}" ]]; then
		cd /s12/${user}
		echo " in /s12/${user}."
	else
		echo "Error: Directory /s12/${user} does not exist. Please create it with group 'geoscience' and permissions 775.  May require sudo."
		exit 0
	fi
else
	mkdir bin_htcondor
	mv bin_htcondor.tgz bin_htcondor
	cd bin_htcondor
	tar -xzf bin_htcondor.tgz
	rm bin_htcondor.tgz
	cd ..
	tar -xzf GMTSAR_v60.tgz
	tar -xzf ssh.tgz
	tar -xzf GMT.tgz
	# edit set paths in GMTSAR scripts to be relative to job directory
	sed -i "/echo/c\echo \"$(pwd)/GMT5SAR5.4/share/gmtsar\"" GMT5SAR5.4/bin/gmtsar_sharedir.csh
	tar -xzf gmtsar_dependencies.tgz

	ln -s GMT5SAR5.4 gmtsar
	ln -s GMT5.2.1 this_gmt

	# link for libnetcdf and libhdf5 dependencies [expect this to be different for GMTSAR_v60]
	cd this_gmt/lib64/
	ln -s libhdf5_hl.so.6.0.4 libhdf5_hl.so.6
	ln -s libhdf5.so.6.0.4 libhdf5.so.6
	ln -s libnetcdf.so.6.0.0 libnetcdf.so.6
	# for GMTSARv5.4
	ln -s libhdf5_hl.so.8.0.2 libhdf5_hl.so.8
	ln -s libhdf5.so.8.0.2 libhdf5.so.8
	ln -s libnetcdf.so.7.2.0 libnetcdf.so.7
	#go to user's home directory
	cd ../../
fi

# print dependencies
#echo "running ldd on calc_dop_orb..."
#ldd `pwd`/gmtsar/bin/calc_dop_orb

# untar orbits directory if sat is ERS or ENVI
if [[ "$sat" == "ENVI" ]] ; then
	tar -xf orbits_ENVI.tgz
	rm orbits_ENVI.tgz
elif [[ "$sat" == "ERS"* ]] ; then
	tar -xf orbits_ERS.tgz
	rm orbits_ERS.tgz
fi

# clean up
#rm -v GMT5SAR_v54.tgz GMT.tgz ssh.tgz gmtsar_dependencies.tgz

#cp -r .ssh /home/${user}/

# make local directories for local copies of data and dem
#if [ ! -d "/s12/${user}/RAW" ] ; then
if [ ! -d "./RAW" ] ; then
	mkdir RAW
fi
#if [ ! -d "/s12/${user}/dem" ] ; then
if [ ! -d "./dem" ] ; then
	mkdir dem
fi

# f test site, cut dem down to size
if [[ "$site" == "test" ]] ; then
	scp $askja:/s12/insar/condor/feigl/insar/dem/${demf} dem/$demf
	xmax=
	xmin=
	ymax=
	ymin=
else
	# transfer cut grid file to job server (for moving to submit-2)
	# scp $askja:/s12/insar/condor/feigl/insar/dem/cut_$demf dem/$demf
	# copy cut grid for current use
	cp /s12/insar/dem/cut_$demf dem/$demf
fi

# ECR 20170709 update raw2prmslc and other data get, test in interactive
if [[ "$sat" == "S1A" ]] ; then
  	raw2prmslc_S1A_htc.sh $ref $sec $trk $demf $satparam
elif [[ "$sat" == *"ALOS"* ]] ; then
  	# transfer data to submit-2     	
  	scp $askja:/s12/insar/${sat}/${trk}/preproc/${ref}_${satparam}.tgz RAW/${ref}.tgz
  	scp $askja:/s12/insar/${sat}/${trk}/preproc/${sec}_${satparam}.tgz RAW/${sec}.tgz
  	cd RAW
else
  	cd RAW
  	## get reference data to working directory
		# transfer ref data to submit-2
		# /s12/insar/TSX/T91/raw/TDX1_SM_091_strip_005_20201023014507 (ref) 
		#longfilename=`ls -1d /s12/insar/TSX/T91/raw/* | grep strip | grep 005 | grep 20201023`  
		swath=`echo $satparam | awk '{print substr($1,7,3)}'`
		echo "swath is $swath"
		#longfilename1=`ls -1d /s12/insar/${sat}/${trk}/raw/* | grep strip | grep ${swath} | grep ${ref}`  
		#grep sanem /s12/insar/TSX/TSX_OrderList.txt | grep 20190912 | awk '{print $12}'
		longfilename1=`grep ${site} /s12/insar/TSX/TSX_OrderList.txt | grep ${ref} | awk '{print $12}'`
		echo "longfilename1 is $longfilename1"
	if [[ ${HOSTNAME} == "askja.ssec.wisc.edu" ]]; then
		rsync -rav $longfilename1 .
	else
		rsync -rav askja.ssec.wisc.edu:$longfilename1 .
	fi
		# cp /s12/insar/${sat}/${trk}/preproc/${ref}.LED /s12/${user}/RAW/.
		# cp /s12/insar/${sat}/${trk}/preproc/${ref}.PRM /s12/${user}/RAW/.
		# cp /s12/insar/${sat}/${trk}/preproc/${ref}.SLC /s12/${user}/RAW/.
		# rsync -rav askja.ssec.wisc.edu:/s12/insar/${sat}/${trk}/preproc/${ref}.LED .
		# rsync -rav askja.ssec.wisc.edu:/s12/insar/${sat}/${trk}/preproc/${ref}.PRM .
		# rsync -rav askja.ssec.wisc.edu:/s12/insar/${sat}/${trk}/preproc/${ref}.SLC .

		# local transfer on Askja
		#cp /s12/insar/${sat}/${trk}/preproc/${ref}*.tgz .
		# if duplicates, take the one corresponding to this site
		# if [[ `ls ${ref}*.tgz | wc -l` -gt 1 ]] ; then
		#  		# keep file that has correct site identifier if it exists
		#  		if [[ -e ${ref}_${site}.tgz ]] ; then
		#   			# keep only site specific file 
		#   			rm ${ref}.tgz
		#   			mv ${ref}_${site}.tgz ${ref}.tgz
		#  		else # if file with correct site identifier doesn't exist then take original
		#   			mv ${ref}.tgz .. 
		#   			# remove incorrect files
		#   			rm ${ref}*.*
		#   			# move correct file back
		#   			mv ../${ref}.tgz . 
		# 	fi
		# fi

   	## get secondary data to working directory
		# transfer sec data to submit-2
		#scp $askja:/s12/insar/${sat}/${trk}/preproc/${sec}*.tgz .
		#longfilename2=`ls -1d /s12/insar/TSX/T91/raw/* | grep strip | grep 005 | grep 20201023`  
		swath=`echo $satparam | awk '{print substr($1,7,3)}'`
		echo "swath is $swath"
		#longfilename2=`ls -1d /s12/insar/${sat}/${trk}/raw/* | grep strip | grep ${swath} | grep ${sec}`
		longfilename2=`grep ${site} /s12/insar/TSX/TSX_OrderList.txt | grep ${sec} | awk '{print $12}'`
		echo "longfilename2 is $longfilename2"
	if [[ ${HOSTNAME} == "askja.ssec.wisc.edu" ]]; then
		rsync -rav $longfilename2 .
	else	
		rsync -rav askja.ssec.wisc.edu:$longfilename2 .
	fi
		# cp /s12/insar/${sat}/${trk}/preproc/${sec}.LED /s12/${user}/RAW/.
		# cp /s12/insar/${sat}/${trk}/preproc/${sec}.PRM /s12/${user}/RAW/.
		# cp /s12/insar/${sat}/${trk}/preproc/${sec}.SLC /s12/${user}/RAW/.
		# rsync -rav askja.ssec.wisc.edu:/s12/insar/${sat}/${trk}/preproc/${sec}.LED .
		# rsync -rav askja.ssec.wisc.edu:/s12/insar/${sat}/${trk}/preproc/${sec}.PRM .
		# rsync -rav askja.ssec.wisc.edu:/s12/insar/${sat}/${trk}/preproc/${sec}.SLC .

		# local transfer on Askja
		#cp /s12/insar/${sat}/${trk}/preproc/${sec}*.tgz .
		# if duplicates, take the one corresponding to this site
		#   	if [[ `ls ${sec}*.tgz | wc -l` -gt 1 ]]
		#   		then
		#keep file that has correct site identifier if it exists
		#     		if [[ -e ${sec}_${site}.tgz ]]
		#      			then
		#keep only site specific file
		#      			rm ${sec}.tgz
		#      			mv ${sec}_${site}.tgz ${sec}.tgz
		#     		else # if file with correct site identifier doesn't exist then take original
		#      			mv ${sec}.tgz ..
		#remove incorrect files
		#      			rm ${sec}*.*
		# move correct file back
		#      			mv ../${sec}.tgz .
		#    	 	fi
		#   	fi
fi

# if data is ALOS then rename files to match epoch dates, otherwise untar as normal
if [[ "$sat" == "ALOS"* ]] ; then
	mkdir tmp_ref tmp_sec 
	# rename refer data by epoch date
	mv ${ref}.tgz tmp_ref 
	cd tmp_ref
	tar -xzvf ${ref}.tgz 
	rm ${ref}.tgz
	refroot=`ls LED* | awk -F\- '{print $2}'`
	for reffile in `ls`; do
		mv $reffile ../`echo $reffile | sed "s/${refroot}/${ref}/"`
	done
	cd ..; rm -r tmp_ref
	# rename sece data by epoch date
	mv ${sec}.tgz tmp_sec
	cd tmp_sec
	tar -xzvf ${sec}.tgz
	rm ${sec}.tgz
	secroot=`ls LED* | awk -F\- '{print $2}'`
	for secfile in `ls`; do
		mv $secfile ../`echo $secfile | sed "s/${secroot}/${sec}/"`
	done
	cd ..; rm -r tmp_sec
fi
if [[ "$sat" != "S1A" ]] ; then
   echo "sat is $sat"
fi

echo "leaving RAW"
cd ../
echo "in $0 working directory is now $PWD"
pwd


# run a script to write a script (run.sh)
pair2e.sh ${sat} ${ref} ${sec} ${satparam} dem/${demf} ${filter_wv} ${site} ${xmin} ${xmax} ${ymin} ${ymax} ${unwrap}

# change directory 
cd In"${ref}"_"${sec}" 

# make executable and actually run the script run.sh 
#chmod +x run.sh
echo
echo
echo "Now we are in pwd $PWD Starting run.sh, logging in $PWD/run.log"
pwd
ls 
# copy standard error and standard out to screen and log file

exit -1

./run.sh |& tee run.log 
# copy standard error and standard out to screen only
#./run.sh >& run.log 

# clean up afterwards
### find . -type f  ! -name '*.png'  ! -name '*LED*' ! -name '*PRM' ! -name '*.tif' ! -name '*.tiff' ! -name '*.cpt' ! -name '*corr*.grd'  !  -name '*.kml' ! -name 'display_amp*.grd' ! -name 'phase*.grd' ! -name 'unwrap*.grd' ! -name 'trans.dat'  -delete
# remove links
#find . -type l -delete

# move results out of single intf directory (named by DOY) into current In${ref}_${sec} directory 
if [[ -d intf ]]; then
	if [ $(find . -name "phasefilt_ll.grd") ]; then
  #	if [ -f intf/phasefilt_ll.grd ]; then  #this will always fail because file will be in /intf/$DOY/ --SAB 6/30/2021
		pair_status=1
		pwd
		mv -v intf/*/* .
		mv -v topo/* .
		mv -v ../config.*.txt .
		mv -v raw/*LED* raw/*PRM .
		# delete folders and any remaining content or broken sym links
		rm -vf topo_ra.grd trans.dat *.SLC
		rm -rvf intf raw SLC topo
	else
		pair_status=0
	fi
else
	pair_status=0	
fi

echo "pair_status is ${pair_status}"

#if [[ ${ref} != 20170324 || ${sec} != 20170313 ]] ; then
if [ $pair_status != 0 ]; then
	if [[ -e "phase_ll.grd"  ]] ; then
		gmt grdcut phase_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphase_ll.grd
	fi
	if [[ -e "phasefilt_ll.grd"  ]] ; then
		gmt grdcut phasefilt_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphasefilt_ll.grd
	fi
	if [[ -e "phasefilt_mask_ll.grd" ]] ; then
		gmt grdcut phasefilt_mask_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gphasefilt_mask_ll.grd
	fi
	if [[ -e "unwrap_ll.grd" ]] ; then
		gmt grdcut unwrap_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_ll.grd
	fi
	if [[ -e "unwrap_mask_ll.grd" ]] ; then
		gmt grdcut unwrap_mask_ll.grd -R${xmin}/${xmax}/${ymin}/${ymax} -Gunwrap_mask_ll.grd
	fi
fi

# print completion status and compute arc if necessary
if [[ -e "phase_ll.grd" && -e "phasefilt_ll.grd" && -e "unwrap_mask_ll.grd" ]] ; then
	pair_status=1
	gmt grdmath phase_ll.grd phasefilt_ll.grd ARC = arc.grd
	# calculate mean, std, and rms of arc; print to txt file
	arc_mean=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $3}'`
	arc_std=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $5}'`
	arc_rms=`gmt grdinfo -M -L2 arc.grd | grep mean | awk '{print $7}'`
	echo "arc_mean = ${arc_mean}"
	echo "arc_std = ${arc_std}"
	echo "arc_rms = ${arc_rms}"
	rm arc.grd
#else
#	pair_status=0
fi

echo "pair_status is now ${pair_status}"
cd ..
# remove echoes when satisfied 
#tar -czvf In${ref}_${sec}.tgz In${ref}_${sec}
# follow the links
#tar -chzvf In${ref}_${sec}.tgz In${ref}_${sec}
#echo rm -rvf RAW

# transfer pair to askja under /s12/insar/[sat][trk]/site
# htcondor version
# ssh $askja "mkdir -p /s12/insar/$sat/$trk/$site"
#rsync -av --remove-source-files In${ref}_${sec}.tgz $askja:/s12/insar/$sat/$trk/$site/
#rsync -av In${ref}_${sec}.tgz $askja:/s12/insar/$sat/$trk/$site/

# clean up after pair is transferred
# rm -fv In${ref}_${sec}.tgz 

#exit 0

echo "done with pair In${ref}_${sec}"

