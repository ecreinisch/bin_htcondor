#!/bin/bash
# get parameter estimates from HTC mesh run
# Elena C Reinisch 20171226
# edit ECR 20180101 add sat to log
# edit ECR 20180213 add variables for DVres and DVresstd (from modeled reservoir of In20160722_20170822)

ls -d In* > InList.tmp
sat=`pwd | awk -F/ '{print $4}'`
trk=`pwd | awk -F/ '{print $5}'`
echo "mast slav mse beta dV dV_std dV_resv dV_resv_std dT dT_std dE_lb_watts dE_ub_watts dE_mean_watts dE_std_watts sat" > ${sat}_${trk}_mesh_results.txt
while read -r a; do
   pair=$a
   mast=`echo $pair | awk -F_ '{print $1}' | awk -FIn '{print $2}'`
   slav=`echo $pair | awk -F_ '{print $2}'`
   mse=`grep "mse =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{printf("%5.2f\n", sqrt($1))}'`
   beta=`grep "beta =" -A2 ${pair}/run_HTC.log | tail -1`
   dVmean=`grep "DV_defregion =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   # dVstd=`grep "DV_defregion_std =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1*10000000}'`
   dVstd=`grep "DV_defregion_std =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dVres=`grep "DV_resregion =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dVresstd=`grep "DV_resregion_std =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dTmean=`grep "dTmean_defregion =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dTstd=`grep "DTmean_defregion_std =" -A2 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dE_lb=`grep "dE_lb =" -A1 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dE_ub=`grep "dE_ub =" -A1 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dE_mean=`grep "dE_mean =" -A1 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   dE_std=`grep "dE_std =" -A1 ${pair}/run_HTC.log | tail -1 | awk '{print $1}'`
   echo $mast $slav $mse $beta $dVmean $dVstd $dVres $dVresstd $dTmean $dTstd $dE_lb $dE_ub $dE_mean $dE_std $sat  >> ${sat}_${trk}_mesh_results.txt
done < InList.tmp

rm InList.tmp
