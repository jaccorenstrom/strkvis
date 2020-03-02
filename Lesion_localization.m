%% Lesion Localisation Script

% script to automatically classify lesion location and affected area within
% MNI152 2mm space.
% 
% requires:
% 
%   - Binary lesion mask and ROIs in same space (1 inside lesion, 0 outside)
%   - LABELLED lesion_mask.nii.gz
%   - ROIs in .nii.gz format in current directory
%   
%
% outputs:
%     - ROI_mats folder containing all ROIs where there is overlap with lesion
%     - each ROI has a % of overlap attached
%
% it is recommended that the lesion_mask is directly taken from LINDA
% output but can be transformed manually as well. 

% JR 13-02-2020

% addpath /Users/jaccorenstrom/matlab/;

%% Set-Up

% specify prefix and suffix for removal
prefix = 'roi_FS_';
suffix = '_2mm.nii.gz';
suffix_mat = '.mat';

% make folder for output
mkdir ROI_mats;
addpath('ROI_mats/');

%% Loading in Lesion Mask
lesion_mask = niftiread('lesion_mask.nii.gz');

% evaluate whether lesion mask is a compatible single precision

mask_evaluation = isa(lesion_mask,'single');
    
% if not, convert to single, if the mask is uncompatible this is where it 
% would break down. LINDA should produce good, compatible mask but if masks
% are used from ITK-SNAP for example, this step is necessary.

% IMPORTANT: conversion from uinit16 to single changes the value of the
% mask, therefore subsequent calculations deal with overlap as >1 instead
% of an absolue number of 2

% only tested with uinit16 masks, if another precision appears this is
% where it needs to be changed

    if mask_evaluation ~= 1
        lesion_mask=im2single(lesion_mask);
    end 

% get total value of mask plus overlap for subsequent identification
a=unique(lesion_mask);
lesion_val=a(2,1);

% if lesion val is too small due to conversion of file, mask gets
% multiplied to make visible for later calculations
if lesion_val < 0.1
   lesion_mask = lesion_mask * 1000;
end 
a=unique(lesion_mask);
lesion_val=a(2,1);
overlap_val = lesion_val + 1;
    
%% Loading in ROIs
ROIs = dir('roi_FS_*.nii.gz');

%% Main Loop

for i=1:length(ROIs)
    
    % loop through ROIs and extract each name per loop
    
    temp_name = getfield(ROIs,{i},'name');
    
    % may need to add line to unzip via gunzip if running old version of
    % matlab
    
    % format the name of the ROI
    newStr = strrep(temp_name,prefix,'');
    newStr = strrep(newStr,suffix,'');
  
    % load nifti image
    newVal=niftiread(temp_name);
    
    % work out total coverage of ROI
    total_ROI=numel(find(newVal==1));
    
    % combine ROI and mask to establish overlap
    newVal=newVal+lesion_mask;
    
    % checks whether there is overlap
    check_val=ismember(overlap_val,newVal);
    
    if check_val>0
            cd ROI_mats/;
            total_lesion=numel(find(newVal==overlap_val));
            overlap_percent=(total_lesion/total_ROI)*100;
            
            filename = strcat(newStr);
            save(filename,'total_ROI','total_lesion','overlap_percent');
            cd ..
    end
    
  
end

% some aesthetics, maybe collate files into table/graph to show biggest
% percentage.


