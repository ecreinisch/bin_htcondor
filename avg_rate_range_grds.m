function [] = avg_rate_range_grds( pair_list_file )
%function [ output_args ] = stack_grds( tm, ts, grd_list )
%   Script for calculating stack grid from collection of grids
% INPUTS:
% pair_list_txt - a .txt file with 3 columns (space delimited), 1st column master in calendar year, 2nd column slave in calendar year, 3rd column name of range grd files
% OUTPUTS:
% stack_range_mperyr.grd - grd file with stacked rate in years
% Update ECR 20171128 change from outdated read_range_from_grd_file function to grdread3.m to be able to use UTM grd files as well as lat/lon

VALS = readtable(pair_list_file, 'ReadVariableNames', 0, 'Delimiter', 'space');

tm_cal = cal2datetime(table2array(VALS(:,1)));
ts_cal = cal2datetime(table2array(VALS(:,2)));
grd_list = table2array(VALS(:,3));

ndat = numel(grd_list);
%[xgrd,ygrd,stacked_pha] = read_range_from_grd_file(char(grd_list(1)));
[xgrd,ygrd,stacked_pha] = grdread3(char(grd_list(1)));

% calculate sum of value
for i=2:ndat
    %[xgrd,ygrd,phaimg] = read_range_from_grd_file(char(grd_list(i)));
    [xgrd,ygrd,phaimg] = grdread3(char(grd_list(i)));
    tmpmat = [];
    tmpmat(:, :, 1) = stacked_pha;
    tmpmat(:, :, 2) = phaimg;
    %stacked_pha = stacked_pha + phaimg;
    stacked_pha = nanmean(tmpmat, 3);
    %stacked_pha = nansum(tmpmat, 3);
end

% calculate sum of time in years
dt = sum(years(ts_cal - tm_cal));

% calculate stacked rate
stacked_rate = stacked_pha/dt;

% write output to grd file
grdwrite2(xgrd, ygrd, stacked_rate, 'avg_range_radperyr.grd')
return

