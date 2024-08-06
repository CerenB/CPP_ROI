function [voxels] = findPeakCoordinates(opt)
% this function find s the peak coordinates within the ROI and spmT maps
% provided
% it loops through the rois(masks) and spmT images and saves the voxel
% coordinates into .csv and .mat structures

% set output folder/name
savefileMat = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'PeakVoxels_unthreshTmaps', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'PeakVoxels_unthreshTmaps', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

%% let's get going!

% set structure array for keeping the results
voxels = struct();
c = 1;

%set smoothing
funcFWHM = 6;

%threshold for binarise the rois
% tested it with mricron viz - 
threshold = 0.15; 


% get the ROIs
roiList = spm_select('FPlist', ...
                         fullfile(opt.dir.roi, 'group'), ...
                         '.*space-.*_mask.nii$');
roiList = cellstr(roiList);


% get data images to read
for iSub = 1:numel(opt.subjects)
    
    subLabel = opt.subjects{iSub};
    
    printProcessingSubject(iSub, subLabel);
    
    %read subject's spmT maps
    ffxDir = getFFXdir(subLabel, funcFWHM, opt);
    spmTmaps = spm_select('FPList', ffxDir, '^sub-.*.GtAll_.*.-099_k-0_MC-none_spmT.nii$'); % -099_k-0_MC-none_spmT k-20_MC-none_spmT
    
    % get to work
    for iRoi = 1:size(roiList,1)
        
        roiImage = roiList{iRoi, :};
        
        for iTmap = 1:size(spmTmaps,1)
            
            dataImage = deblank(spmTmaps(iTmap,:));
            
            % reslice images if necessary & omit the prefix afterwards
            reslicedImages = resliceRoiImages(dataImage, roiImage);
            
            sts = checkRoiOrientation(dataImage, roiImage);
            if sts == 0
                reslicedImages = removePrefix(reslicedImages, spm_get_defaults('realign.write.prefix'));
            end
            
            % binarize ROIs
            voxelnb = binariseImage(reslicedImages, threshold);
            
          %  isBinaryMask(reslicedImages);
            
            % read file names
            p = bids.internal.parse_filename(spm_file(roiImage, 'filename'));
            s = bids.internal.parse_filename(spm_file(dataImage, 'filename'));
            
            % Get to work.
            [worldCoord, voxelCoord, maxVal] = getPeakCoordinates(dataImage, reslicedImages);
            
            % peakVoxels
            voxels(c).subLabel = subLabel;
            voxels(c).mask = p.filename;
            voxels(c).maskLabel = p.entities.label;
            voxels(c).maskHemi = p.entities.hemi;
            voxels(c).voxelnb = voxelnb;
            voxels(c).coordinateX = voxelCoord(1);
            voxels(c).coordinateY = voxelCoord(2);
            voxels(c).coordinateZ = voxelCoord(3);
            voxels(c).worldCoordX = worldCoord(1);
            voxels(c).worldCoordY = worldCoord(2);
            voxels(c).worldCoordZ = worldCoord(3);
            voxels(c).tValue = maxVal;
            voxels(c).ffxSmooth = funcFWHM;
            
            voxels(c).dataImageSub = s.entities.sub;
            voxels(c).dataImage = s.filename;
            voxels(c).dataImageContrast = s.entities.desc;
            voxels(c).dataImageSpace = s.entities.space;
            
            c = c +1;
        end
    end

    % mat file
    save(savefileMat, 'voxels');
    
    % csv but with important info for plotting
    writetable(struct2table(voxels), savefileCsv);
    
    

end

end

function voxelnb = binariseImage(imageName, threshold)

    hdr = spm_vol(imageName);
    img = spm_read_vols(hdr);

    %binarize
    img(img(:) > threshold) = 1;
    img(img(:) <= threshold) = 0;
    
    % sum the voxel number
    voxelnb = sum(img(:));
    
    % save
    spm_write_vol(hdr, img);

end