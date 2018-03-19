function [] = avg_rate_phase_grds( pair_list_file  )
%function [ output_args ] = stack_grds( tm, ts, grd_list )
%   Script for calculating stack grid from collection of grids
% INPUTS:
% pair_list_txt - a .txt file with 3 columns (space delimited), 1st column master in calendar year, 2nd column slave in calendar year, 3rd column name of range grd files
% OUTPUTS:
% avg_phase_radperyr.grd - grd file with averaged rate in years 

VALS = readtable(pair_list_file, 'ReadVariableNames', 0, 'Delimiter', 'space');

tm_cal = cal2datetime(table2array(VALS(:,1)));
ts_cal = cal2datetime(table2array(VALS(:,2)));
grd_list = table2array(VALS(:,3));

ndat = numel(grd_list);
[xgrd,ygrd,stacked_pha] = read_range_from_grd_file(char(grd_list(1)));
stacked_cos = cos(stacked_pha);
stacked_sin = sin(stacked_pha);

% calculate sum of value
for i=2:ndat
    [xgrd,ygrd,phaimg] = read_range_from_grd_file(char(grd_list(i)));
    stacked_cos =  stacked_cos + cos(phaimg);
    stacked_sin = stacked_sin + sin(phaimg);
end
stacked_pha = atan2(stacked_cos, stacked_sin);

% calculate sum of time in years
dt = sum(years(ts_cal - tm_cal));

% calculate stacked rate
stacked_rate = stacked_pha/dt;

% write output to grd file
grdwrite2(xgrd, ygrd, stacked_rate, 'avg_phase_radperyr.grd')
return

