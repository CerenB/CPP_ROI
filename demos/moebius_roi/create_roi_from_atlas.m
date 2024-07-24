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
voxels = findPeakCoordinates(opt);

%% find cluster size/centre of gravity

% take spmT map (that is thresholded already) masked with sensorimotor cx and 
% then count the cluster voxels 
funcFWHM = 6;
findCentreOfGravity(opt,funcFWHM);

%find spmT image

subLabel = opt.subjects{1};
ffxDir = getFFXdir(subLabel, funcFWHM, opt);
spmTmaps = spm_select('FPList', ffxDir, '^sub-.*.GtAll_.*.k-20_MC-none.*spmT.nii$');
dataImage = deblank(spmTmaps(2,:));


% find roi/mask image
roiList = spm_select('FPlist', ...
                         fullfile(opt.dir.roi, 'group'), ...
                         '.*space-.*_mask.nii$');
roiList = cellstr(roiList);
roiImage = roiList{1, :};


% masking the thresholded spmT map with our sensorimotor cx binary mask
matlabbatch = {};
matlabbatch{1}.spm.stats.results.spmmat = {'/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-stats/sub-ctrl001/stats/task-somatotopy_space-MNI_FWHM-6_desc-AuditoryCueParts/SPM.mat'};
matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
matlabbatch{1}.spm.stats.results.conspec.contrasts = 79;
matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
matlabbatch{1}.spm.stats.results.conspec.thresh = 0.001;
matlabbatch{1}.spm.stats.results.conspec.extent = 20;
matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
matlabbatch{1}.spm.stats.results.conspec.mask.image.name = {'/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/hemi-L_space-MNI_seg-hcpex_label-123ab_mask.nii,1'};
matlabbatch{1}.spm.stats.results.conspec.mask.image.mtype = 0;
matlabbatch{1}.spm.stats.results.units = 1;
matlabbatch{1}.spm.stats.results.export{1}.png = true;
matlabbatch{1}.spm.stats.results.export{2}.tspm.basename = 'hemi-L_space-MNI_mask-sensorimotorcx_cond-HandGtAll_p-0001_MC-none_k-20_FWHM-6';

% Run the job
spm_jobman('run', matlabbatch);



% next: inthe new masked_spmT map, find the cluster size

% our new fileName = 
maskedImage = 'spmT_0079_hemi-L_space-MNI_mask-sensorimotorcx_cond-HandGtAll_p-0001_MC-none_k-20_FWHM-6.nii';
path = '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-stats/sub-ctrl001/stats/task-somatotopy_space-MNI_FWHM-6_desc-AuditoryCueParts/';
imageName = fullfile(path,maskedImage);
hdr = spm_vol(imageName);
img = spm_read_vols(hdr);

% convert nans to zeros
temp = img;
temp(isnan(temp)) = 0;

% count voxel numbers
temp(temp>0) =1;
sum(temp(:))

% Get the voxel indices (linear indices)
voxel_indices = find(temp);

% Convert linear indices to subscripts (x, y, z coordinates)
[x, y, z] = ind2sub(size(img), voxel_indices);
voxelCoord = [x, y, z];

% Calculate the center of gravity (centroid) based on voxel coordinates
centroid_x = mean(x);
centroid_y = mean(y);
centroid_z = mean(z);

% Combine into a single vector
centroid = [centroid_x, centroid_y, centroid_z];

% Display the centroid coordinates
fprintf('Cluster centroid: (%.2f, %.2f, %.2f)\n', centroid_x, centroid_y, centroid_z);
    
% convert space from slice number to world coordinate
worldCoord = cor2mni(voxelCoord, roiImage);
    
% Calculate center of gravity (centroid)
cluster_centroids(i, :) = mean(worldCoord, 1);








% Label connected clusters
% 6 (surface), 18 (edge) or 26 (corner) [Default: 18]
[labels, numClusters] = spm_bwlabel(temp, 6); % 6-connectivity


% Initialize an array to store cluster sizes
cluster_sizes = zeros(numClusters, 1);

% Calculate the size of each cluster
for i = 1:numClusters
    cluster_sizes(i) = sum(labels(:) == i);
end

% Display the results
disp('Cluster sizes (in number of voxels):');
disp(cluster_sizes);

% Optionally, calculate the centroid of each cluster
cluster_centroids = zeros(numClusters, 3);

for i = 1:numClusters
    % Get voxel indices for the cluster
    voxelIdx = find(labels == i);
    
    % Get voxel coordinates
    [x, y, z] = ind2sub(size(temp), voxelIdx);
    voxelCoords = [x, y, z];
    
    % convert space from slice number to world coordinate
    worldCoord = cor2mni(voxelCoord, roiImage);
    
    % Calculate center of gravity (centroid)
    cluster_centroids(i, :) = mean(worldCoord, 1);

end


  
% Display the centroids
disp('Cluster centroids:');
disp(cluster_centroids);



% 
% 
% % do we need a threshold?
% hdr = spm_vol(imageName);
% img = spm_read_vols(hdr);
% 
% %binarize
% img(img(:) > threshold) = 1;
% img(img(:) <= threshold) = 0;
% 
% % sum the voxel number
% voxelnb = sum(Y_masked(:));
% 
% % save
% spm_write_vol(hdr, img);









%% second way 


% Step 2: Load the NIfTI image
nifti_file = 'path/to/your/activation_image.nii';
V = spm_vol(nifti_file);
Y = spm_read_vols(V);

% Step 3: Threshold the image
threshold = 2.5; % Set your desired threshold
activated_voxels = Y > threshold;

% Step 4: Identify clusters
CC = bwconncomp(img, 6); % 6-connectivity for clustering

% Step 5: Calculate the center of gravity for each cluster
cluster_centroids = zeros(length(CC.PixelIdxList), 3); % Initialize centroids array

for i = 1:length(CC.PixelIdxList)
    % Get voxel indices for the cluster
    voxelIdx = CC.PixelIdxList{i};
    
    % Get voxel coordinates
    [x, y, z] = ind2sub(size(Y), voxelIdx);
    voxelCoords = [x, y, z];
    
    % Get voxel intensities
    voxel_intensities = Y(voxelIdx);
    
    % Calculate weighted center of gravity
    total_intensity = sum(voxel_intensities);
    weighted_sum = sum(voxelCoords .* voxel_intensities, 1);
    cluster_centroids(i, :) = weighted_sum / total_intensity;
end

% Display the results
disp('Cluster centroids (weighted by intensity):');
disp(cluster_centroids);


















%% old cpp-bids code to run GLM within ROI
opt.glm.roibased.do = true;
bidsRoiBasedGLM(opt);
