function [centroidData,voxels] = findCentreOfGravity(opt,funcFWHM)


% set output folder/name
savefileMat = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'CoGCoordandVoxelNbforROIs_unthresh', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'CoGCoordandVoxelNbforROIs_unthresh', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

% set structure array for keeping the results
voxels = struct();
centroidData = zeros(10, 3, numel(opt.subjects));
c = 1;

% load the masked Tmaps
for iSub = 1:numel(opt.subjects)

          subLabel = opt.subjects{iSub};

          subjectFolder = getFFXdir(subLabel, funcFWHM, opt);
          
          maskedImagesList = spm_select('FPlist', subjectFolder, ...
                                            '.*-099_k-0_MC-none_maskLabel-.*_spmT.nii$');

        
    %load masked images and find centre of gravity 
    for iROI = 1:size(maskedImagesList, 1)

        roiImage = deblank(maskedImagesList(iROI, :));
        
        % get the filename 
        p = bids.internal.parse_filename(spm_file(roiImage, 'filename'));

        
        % load the image 
        hdr = spm_vol(roiImage);
        img = spm_read_vols(hdr);
        
        % convert nans to zeros
        temp = img;
        temp(isnan(temp)) = 0;
        
        % count voxel numbers
        temp(temp>0) =1;
        voxelNb = sum(temp(:));
        
        % Get the voxel indices (linear indices)
        voxelIdx = find(temp);
        
        % Convert linear indices to subscripts (x, y, z coordinates)
        [x, y, z] = ind2sub(size(img), voxelIdx);
        voxelCoord = [x, y, z];
        
        % convert space from slice number to world coordinate
        worldCoord = cor2mni(voxelCoord, roiImage);
        
        % Calculate center of gravity (centroid)
        centroid = mean(worldCoord, 1);

        %insert centroids into matrix for later on calculations
        centroidData(iROI, :, iSub) = [centroid(1), centroid(2), centroid(3)];      
        
        %% save into csv & mat file
        voxels(c).subLabel = subLabel;
        voxels(c).imageContrastName = p.entities.desc;
        %voxel number/size
        voxels(c).voxelNb = voxelNb;
        %centre of gravity coordinates
        voxels(c).centroidCoordinateX = centroid(1);
        voxels(c).centroidCoordinateY = centroid(2);
        voxels(c).centroidCoordinateZ = centroid(3);
        voxels(c).maskHemi = p.entities.maskLabel(1);
        voxels(c).maskLabel = p.entities.maskLabel(2:end);
        
        %coordinates to save in .mat
        voxels(c).coordinateX = worldCoord(:,1);
        voxels(c).coordinateY = worldCoord(:,2);
        voxels(c).coordinateZ = worldCoord(:,3);
        voxels(c).voxelX = voxelCoord(:,1);
        voxels(c).voxelY = voxelCoord(:,2);
        voxels(c).voxelZ = voxelCoord(:,3);
        
        %other relevant info to keep track
        voxels(c).image = p.filename;
        voxels(c).imageContrastIdx = p.entities.label;
        voxels(c).imageContrastp = p.entities.p;
        voxels(c).imageContrastMC = p.entities.MC;
        voxels(c).imageContrastk = p.entities.k;
        voxels(c).ffxSmooth = funcFWHM;

        c = c +1;

    end

end        
          
% mat file
save(savefileMat, 'voxels');

% csv but with important info for plotting
voxels = rmfield(voxels, 'coordinateX');
voxels = rmfield(voxels, 'coordinateY');
voxels = rmfield(voxels, 'coordinateZ');
voxels = rmfield(voxels, 'voxelX');
voxels = rmfield(voxels, 'voxelY');
voxels = rmfield(voxels, 'voxelZ');
writetable(struct2table(voxels), savefileCsv);
     
          
end

