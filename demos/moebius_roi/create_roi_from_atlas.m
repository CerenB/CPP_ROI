% (C) Copyright 2021 CPP ROI developers

clear all;
clc;

% bidsmatlab add to path - it's not defined in initCppRoi
addpath('../../lib/bids-matlab');

warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));


% add path of this folder
thisDirectory = pwd;
addpath(fullfile(thisDirectory));

% bidspm - use
%run ../lib/CPP_BIDS_SPM_pipeline/initCppSpm.m;

%cpp_roi
run ../../initCppRoi;

% to load the subjects
moebiusSource = ['/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/',...
               'code/moebiusproject_fMRI_analysis/src'];
moebiusCppBids = fullfile(moebiusSource, '../lib/CPP_BIDS_SPM_pipeline/');
addpath(moebiusCppBids);
run initCppSpm.m;

opt = getOptionMoebiusROI();

% % 
% %     opt.roi.atlas = 'hcpex';
% %     opt.roi.space = {'MNI', 'individual'};
% %     % chosen ones: 3b = primary sensory cx, 4 = primary motor cx
% %     opt.roi.name = {'1', '2', '3a', '3b', '4','6a', '6d', '6v', 'FEF', 'PEF'};
% %     
    

% check the atlas labels
%[atlasFile, lut] = getAtlasAndLut(opt.roi.atlas);

%define hemisphere
hemi = {'L', 'R'};

% extract ROIs from atlas in MNI space
for iHemi = 1:numel(hemi)

  for iROI = 1:numel(opt.roi.name)

    roiName = opt.roi.name{iROI};

    imageName{iHemi,iROI} = extractRoiFromAtlas(opt.roi.dir, ...
                                                opt.roi.atlas, ...
                                                roiName, hemi{iHemi});

  end

end


% individual space - ROI making
createIndividualROI(opt);

% find peaks
peakVoxels = findPeakCoordinates(opt);

%% find cluster size/centre of gravity

% take spmT map (that is thresholded already) masked with sensorimotor cx and 
% then count the cluster voxels 
funcFWHM = 6;
%opt.subjects = {'ctrl001'};
createMaskedTmaps(opt,funcFWHM);


% find the centre of gravity for each Tmaps
%opt.subjects = {'ctrl001','ctrl002'};
[CoG, voxels] = findCentreOfGravity(opt,funcFWHM);


% calculate the pairwise euclidean distance 
[dataTable] = calculateCoGDistance(opt,CoG);


% calculate the dice coefficient 
funcFWHM = 6;
coef = calculateDiceCoeff(opt,funcFWHM);

% make pairwise sum up (foot - lip) and count the tempImg(tempImg==2) to
% see the overlap, sum this and divide for the number of overlapping voxels
% do it for all participants




%%%%%%%%%%%%%%%

% %% second way for CoG calc 
% % it seems to take into account the tvalue/intensity
% 
% % Step 2: Load the NIfTI image
% nifti_file = 'path/to/your/activation_image.nii';
% V = spm_vol(nifti_file);
% Y = spm_read_vols(V);
% 
% % Step 3: Threshold the image
% threshold = 2.5; % Set your desired threshold
% activated_voxels = Y > threshold;
% 
% % Step 4: Identify clusters
% CC = bwconncomp(img, 6); % 6-connectivity for clustering
% 
% % Step 5: Calculate the center of gravity for each cluster
% cluster_centroids = zeros(length(CC.PixelIdxList), 3); % Initialize centroids array
% 
% for i = 1:length(CC.PixelIdxList)
%     % Get voxel indices for the cluster
%     voxelIdx = CC.PixelIdxList{i};
%     
%     % Get voxel coordinates
%     [x, y, z] = ind2sub(size(Y), voxelIdx);
%     voxelCoords = [x, y, z];
%     
%     % Get voxel intensities
%     voxel_intensities = Y(voxelIdx);
%     
%     % Calculate weighted center of gravity
%     total_intensity = sum(voxel_intensities);
%     weighted_sum = sum(voxelCoords .* voxel_intensities, 1);
%     cluster_centroids(i, :) = weighted_sum / total_intensity;
% end
% 
% % Display the results
% disp('Cluster centroids (weighted by intensity):');
% disp(cluster_centroids);


%% old cpp-bids code to run GLM within ROI
% opt.glm.roibased.do = true;
% bidsRoiBasedGLM(opt);
