#!/bin/csh -f
# modified version of GMTSARv5.2 script 
# modified by Elena C Reinisch (lines 9 and 10)
#
alias rm 'rm -f'
unset noclobber
set earth_radius = 0
# define master and slave based on PRM file name
set master = `echo $1 | awk -F.PRM '{print $1}'`
set slave = `echo $2 | awk -F.PRM '{print $1}'`

cp $master.PRM $master.PRM00
cp $slave.PRM $slave.PRM00

@ m_lines  = `grep num_lines $master.PRM | awk '{printf("%d",int($3))}' `
@ s_lines  = `grep num_lines $slave.PRM | awk '{printf("%d",int($3))}' `

if($s_lines <  $m_lines) then
  update_PRM.csh $master.PRM num_lines $s_lines
  update_PRM.csh $master.PRM num_valid_az $s_lines
  update_PRM.csh $master.PRM nrows $s_lines
else
  update_PRM.csh $slave.PRM num_lines $m_lines
  update_PRM.csh $slave.PRM num_valid_az $m_lines
  update_PRM.csh $slave.PRM nrows $m_lines
endif

cp $master.PRM $master.PRM0
calc_dop_orb $master.PRM0 $master.log $earth_radius 0
cat $master.PRM0 $master.log > $master.PRM
echo "fdd1                    = 0" >> $master.PRM
echo "fddd1                   = 0" >> $master.PRM

cp $slave.PRM $slave.PRM0
calc_dop_orb $slave.PRM0 $slave.log $earth_radius 0
cat $slave.PRM0 $slave.log > $slave.PRM
echo "fdd1                    = 0" >> $slave.PRM
echo "fddd1                   = 0" >> $slave.PRM
rm *.PRM0
SAT_baseline $master.PRM $slave.PRM
