SHELL := /bin/bash # Use bash syntax
# Make file for copying to different servers
site=forge

.PHONY : all
all :
	@make setup
	@make get_in
	@make untar_in
	@make prep_log
	@make topo
	@make pre_gipht
	@make plot_pha_utm

.PHONY : setup
setup : 
	@echo "setup directory"
	@mkdir -p gipht
	@mkdir -p intf
	@mkdir -p preproc
	@mkdir -p SLC
	@mkdir -p log
	@mkdir -p Plots
	@mkdir -p topo 

.PHONY : get_in
get_in :
	@echo "move job pairs from site directory"
	@getjobpairs.sh intf/maule_pairs.lst

.PHONY : untar_in
untar_in :
	@echo "untar pairs"
	@cdir=`pwd`
	@echo "tar -xzvf In*.tgz"
	@cd intf; untar_condor.sh; cd ${cdir}


.PHONY : prep_log
prep_log :
	@echo "move log files to intf/[pair] directories"
	@cd log; mv_log_files.sh; cd ${cdir}


.PHONY : topo
topo :
	@echo "prepare topo directory with DEM"
	@pre_topo_maule.sh ${site}

.PHONY : pre_gipht
pre_gipht :
	@echo "prepare files for gipht"
	@cdir=`pwd`
	@cd gipht; prepare_grids_for_gipht6.sh ${site}; cd ${cdir}

.PHONY : plot_comp
plot_comp :
	@echo "making comparison plots for phase and range"
	@cdir=`pwd`
	@echo ${cdir}
	@cd intf; plot_PAIRSmake.sh PAIRSmake_check.txt phase_ll unwrap_ll; cd ${cdir}

.PHONY : plot_comp_utm
plot_comp_utm :
	@echo "making comparison plots for phase and range in UTM"
	@cdir=`pwd`
	@echo ${cdir}
	@cd intf; plot_PAIRSmake.sh PAIRSmake_check.txt phase_utm drange_utm; cd ${cdir}

.PHONY : plot_pha
plot_pha :
	@echo "making plots for phase"
	@cdir=`pwd`
	@echo ${cdir}
	@cd intf; plot_PAIRSmake1.sh PAIRSmake_check.txt phase_ll; cd ${cdir}

.PHONY : plot_pha_utm
plot_pha_utm :
	@echo "making plots for phase in UTM"
	@cdir=`pwd`
	@echo ${cdir}
	@cd intf; plot_PAIRSmake1.sh PAIRSmake_check.txt phase_utm; cd ${cdir}

.PHONY : plot_unw
plot_unw :
	@echo "making plots for unwrapped range change"
	@cdir=`pwd`
	@echo ${cdir}
	@cd intf; plot_PAIRSmake1.sh PAIRSmake_check.txt unwrap_ll; cd ${cdir}
