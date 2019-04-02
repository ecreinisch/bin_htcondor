#! /bin/bash
#
# This scrip bundles drhomaskd_utm.grd, phasefilt_utm.grd, ${site}_${date_range}_drange_utm_byte.tif, ${site}_${date_range}_phasefilt_utm_byte.tif, 
# their legends, unit_vectors.txt, and metadata_info.txt into a zip  file
# should result in a self-describing file name something like "brady_T53_In20111224_20121027.zip"
#
# This script should be run in the "intf" directory of processed pairs that have been returned from submit-2
# The script loops through all of the In{yyyymmdd}_{yyyymmdd} directories in the "intf" directory
# At the end, it moves the zip bundles into a directory called "zips"

# Updates:
# 1/29/2019 changed variable definitions to be based on paths rather than arguments
# 1/29/2019 added loop to the script

# Get directory variables
currentpath=`pwd`
echo "running in ${currentpath}"
basepath1=`echo ${currentpath} | cut -d "/" -f2`
echo "basepath1 is ${basepath1}"
basepath2=`echo ${currentpath} | cut -d "/" -f3`
echo "basepath2 is ${basepath2}"
basepath=${basepath1}/${basepath2}
#sat="$1"
sat=`echo ${currentpath} | cut -d "/" -f4`
echo "sat is ${sat}"
#trk="$2"
trk=`echo ${currentpath} | cut -d "/" -f5`
echo "trk is ${trk}"
#site="$3"
site=`echo ${currentpath} | cut -d "/" -f6`
echo "site is ${site}"
basepath3=`echo ${currentpath} | cut -d "/" -f7`
echo "basepath3 is ${basepath3}"
filepath=${basepath3}/intf
echo "filepath is ${filepath} "
filepath2=${basepath3}/preproc
echo "filepath2 is ${filepath2}"

#Start of bundling

#Make list of directories to process, first clean-up from previous run, if any, and make new list to avoid duplicats
rm /${basepath}/${sat}/${trk}/${site}/${filepath}/dir.txt; for d in ./In*;do [[ -d "$d" ]] && echo "${d##./}" >> /${basepath}/${sat}/${trk}/${site}/${filepath}/dir.txt; done
dir_filename=/${basepath}/${sat}/${trk}/${site}/${filepath}/dir.txt
filelines=`cat ${dir_filename}`
echo Starting Loop of Directories: $filelines
for line in $filelines ; do
	pair_dir=$line
	#pair_dir="$1"
	mast=$(echo ${pair_dir} | cut -c3-10)
	slav=$(echo ${pair_dir} | cut -c12-19)
	date_range=${mast}_${slav}
	echo "date_range is ${date_range}"
	slgspace=" "
	dblspace="  "
	mastslav=${mast}${dblspace}${slav}
	# build zip filename
	zipfilename=${site}_${trk}_${sat}_${pair_dir}.zip
	echo "gathering files for ${zipfilename}"
	tmpzipdir=${site}_${trk}_${sat}_${pair_dir}
	# make temp copies the files in a directory called tmpzipdir (make directory if it does not exist):
	mkdir -p ${tmpzipdir}
	cp /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/drhomaskd_utm.grd ${tmpzipdir}/.
	cp /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/phasefilt_utm.grd ${tmpzipdir}/.
	cp /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/drange_utm_byte.tif /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/${site}_${date_range}_drange_utm_byte.tif
	cp /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/phasefilt_utm_byte.tif /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/${site}_${date_range}_phasefilt_utm_byte.tif
	cp /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/${site}_${date_range}_drange_utm_byte.tif ${tmpzipdir}/.
	cp /${basepath}/${sat}/${trk}/${site}/${filepath}/${pair_dir}/${site}_${date_range}_phasefilt_utm_byte.tif ${tmpzipdir}/.
	cp /t31/batzli/legend_cool_drange_utm.pdf ${tmpzipdir}/.
	cp /t31/batzli/legend_phasefilt_utm.pdf ${tmpzipdir}/.
	# only grab appropriate line for unit_vectors.txt
	grep ${pair_dir} /${basepath}/${sat}/${trk}/${site}/${filepath2}/unit_vectors.txt > ${tmpzipdir}/unit_vectors_sub.txt
	# get the metadata and make a text file
	#echo "#mast slav orb1 orb2 dmast dslav jdmast jdslav trk orbdir swath site wv bpar bperp burst sat dem processed unwrapped pha_std t_crit t_stat res_mean res_std res_nu user" > $tmpzipdir/metadata_info.txt
	echo "#mast	slav	orb1	orb2	dt	trk	swath	site	wv	bpar	bperp	sat	unwrp	pha_std	t_crit	t_stat" > ${tmpzipdir}/metadata_info.txt
	grep -h "${mastslav}" /${basepath}/${sat}/${trk}/${site}/${filepath}/PAIRSmake_check.txt | awk '{OFS="\t";print $1,$2,$3,$4,$7,$9,$11,$12,$13,$14,$15,$17,$20,$21,$22,$23}' | sed 's/nan/nannannan/g' >> ${tmpzipdir}/metadata_info.txt
	# zip the bundle with zipfilename
	zip -r ${zipfilename} ${tmpzipdir} 
	# make zips directory if necessary
	mkdir -p /${basepath}/${sat}/${trk}/${site}/zips
	mv ${zipfilename} /${basepath}/${sat}/${trk}/${site}/zips/${zipfilename}
	# remove the tempzipdir
	rm -fr $tmpzipdir
done
