% This script shows how to extract the river network from the DEM of the 
% Vjosa river network using functions from topotoolbox and how to build 
% the ReachData matrix to be used in CASCADE.
% 
% The resulting network should be further elaborated with the aid a GIS
% sofware, to identify and remove possible outliers and errors,
% before employing it in CASCADE_script.
%
% Visit https://topotoolbox.wordpress.com/ for more information about
% topotoolbox

clear all
clc

%% main input
%DEM name
DEM_name = 'Vjosa_basin_25m.tif' ;

%Minimum drainage area in km2. Large drainage areas cause the river 
%network to consider only larger streams, small drainage areas increase 
%the possibility of identifying unexisting reaches.
Amin_km2 = 50; 

mingradient = 0.0001;

%% reach partition input 
% "reach_length_km" reports the approximate length of the reaches the river network is partitioned. Insert very large
% values to obtain partitions only at confluences or if manual partition is desired.

%if uniform partitioning
reach_length_km = 100; 
breaknodes = [];

%if manual partitioning (break points and/or dams)
 reach_length_km = 200000; 
 load('Vjosa_breaknodes.mat');

%breakpoint matrix must contain a single matrix (Nx2) of x and y coordinates of N break points of
%the network, with the same reference system of the DEM, found using GIS software

%% add topotoolbox folder path
addpath(genpath(pwd))

%% preprocessing
DEM = GRIDobj(DEM_name);

%% River network extraction
[ReachData,S] = ExtractRiverNetwork(DEM, Amin_km2, reach_length_km, breaknodes, mingradient);

% plot river network
plot(S);

%% export map struct (for visualization and manipulation in GIS softwares)
shp_name = 'River_Network';
shapewrite(ReachData,shp_name);
    