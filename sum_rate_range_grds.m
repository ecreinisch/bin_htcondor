function [] = sum_rate_range_grds( pair_list_file )
%function [ output_args ] = stack_grds( tm, ts, grd_list )
%   Script for calculating stack of rates in grd form from collection of grids
% OUTDATED!!! Use avg_rate_range function instead
% INPUTS:
% pair_list_txt - a .txt file with 3 columns (space delimited), 1st column master in calendar year, 2nd column slave in calendar year, 3rd column name of range grd files
%
% OUTPUTS:
% sum_rate_radperyr.grd - grd file with stacked rate in years

VALS = readtable(pair_list_file, 'ReadVariableNames', 0, 'Delimiter', 'space');

tm_cal = cal2datetime(table2array(VALS(:,1)));
ts_cal = cal2datetime(table2array(VALS(:,2)));
grd_list = table2array(VALS(:,3));

ndat = numel(grd_list);
[xgrd,ygrd,stacked_pha] = read_range_from_grd_file(char(grd_list(1)));
dt = sum(years(ts_cal(1) - tm_cal(1)));
stacked_rate = stacked_pha/dt;

% calculate sum of value
for i=2:ndat
    [xgrd,ygrd,phaimg] = read_range_from_grd_file(char(grd_list(i)));
    dt = sum(years(ts_cal(i) - tm_cal(i)));
    stacked_rate = stacked_rate + phaimg/dt;
end

% divide by N
stacked_rate = 1/ndat*stacked_rate;

% write output to grd file
grdwrite2(xgrd, ygrd, stacked_rate, 'summed_rate_radperyr.grd')

return

