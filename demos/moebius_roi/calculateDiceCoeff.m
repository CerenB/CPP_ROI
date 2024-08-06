function coef = calculateDiceCoeff(opt,funcFWHM)


savefileMat = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'DiceCoeff_', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'DiceCoeff_', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);


% Assuming centroid_data is already populated with centroid coordinates
%subjectNb = numel(opt.subjects);
labels = {'Foot', 'Forehead', 'Hand', 'Lips', 'Tongue'};
maskNbPerSubject = size(labels,2);

% Generate pair labels
pairIdx = nchoosek(1:maskNbPerSubject, 2);
pairLabels = arrayfun(@(i) sprintf('%s-%s', ...
                            labels{pairIdx(i, 1)}, labels{pairIdx(i, 2)}),...
                            1:size(pairIdx, 1), 'UniformOutput', false);
pairNb = size(pairIdx, 1);                        

% Initialize arrays to store the data in column-wise format
subject = [];
hemisphere = [];
pair = []; 
pairB = [];
diceCoef = [];
group = []; overlapVoxels = []; totalVoxels = [];

% load the masked Tmaps
for iSub = 1:numel(opt.subjects)
    
    subLabel = opt.subjects{iSub};
    
    subjectFolder = getFFXdir(subLabel, funcFWHM, opt);
    
    maskedImagesList = spm_select('FPlist', subjectFolder, ...
                                  '.*-0001_k-20_MC-none_maskLabel-.*_mask.nii$');
    leftImages = maskedImagesList(1:2:end,:);
    rightImages = maskedImagesList(2:2:end,:);

    % Calculate pairwise Dice coefficients for evenRows
    [pairwiseDiceLeft, overlapVoxL, totVoxL, pairLabelsL] = calculate_pairwise_dice(leftImages);
    
    % Calculate pairwise Dice coefficients for oddRows
    [pairwiseDiceRight, overlapVoxR, totVoxR, pairLabelsR] = calculate_pairwise_dice(rightImages);
    
    % Append data to the columns
    subject = [subject; repmat({subLabel}, pairNb, 1); repmat({subLabel}, pairNb, 1)]; %#ok<*AGROW>
    hemisphere = [hemisphere; repmat({'L'}, pairNb, 1); repmat({'R'}, pairNb, 1)];
    pairB = [pairB; pairLabels'; pairLabels'];
    pair = [pair; pairLabelsL'; pairLabelsR'];
    diceCoef = [diceCoef; pairwiseDiceLeft'; pairwiseDiceRight'];
    overlapVoxels = [overlapVoxels; overlapVoxL'; overlapVoxR']; 
    totalVoxels = [totalVoxels; totVoxL'; totVoxR'];
    
    % Determine the group for the current subject
    if iSub <= 7
        groupLabel = 'mbs';
    else
        groupLabel = 'ctrl';
    end
    
    % Append group data
    group = [group; repmat({groupLabel}, pairNb * 2, 1)];
   
end


% Combine all columns into a table
coef = table(subject, hemisphere, pair, diceCoef, group, ...
            overlapVoxels, totalVoxels, pairB,...
                   'VariableNames', ...
                   {'Subject', 'Hemi', 'Pair', 'Dice', 'Group', ...
                   'OverlapVoxels', 'TotVoxels', 'AlternativePairs'});

% Write the table to a CSV file
writetable(coef, savefileCsv);

% Save the centroid data and distance matrices
save(savefileMat, 'coef');


end



function [dsc, intersectVoxels, totalVoxels]= diceCoefficient(imgA, imgB)
    % Check that A and B are binary masks of the same size
    if ~isequal(size(imgA), size(imgB))
        error('Input masks must have the same dimensions');
    end
    
    % Convert to logical in case they are not
    imgA = logical(imgA);
    imgB = logical(imgB);
    
    % Compute the Dice coefficient
    intersectVoxels = nnz(imgA & imgB);
    totalVoxels = nnz(imgA) + nnz(imgB);
    
    % Avoid division by zero
    if totalVoxels == 0
        dsc = 1;  % Both images are empty
    else
        dsc = 2 * intersectVoxels / totalVoxels;
    end
end


% Function to calculate pairwise Dice coefficients for a list of image filenames
function [pairwiseDice, overlapVox, totVox, pairs] = calculate_pairwise_dice(imageList)
    nImg = size(imageList,1);
    pairwiseDice = [];
    pairs = {};
    
    % Read all images first
    images = cell(nImg, 1);
    for i = 1:nImg
        vol = spm_vol(imageList(i,:));
        img = spm_read_vols(vol);
        images{i} = img > 0;  % Convert to binary mask
    end
    
    % Calculate pairwise Dice coefficients
    k = 1;
    for i = 1:nImg
        for j = i+1:nImg
            [pairwiseDice(k),overlapVox(k), totVox(k)] = diceCoefficient(images{i}, images{j});
            
%             pairwiseDiceMatrix(i, j) = pairwiseDice(k);  % Symmetric matrix
            pairLabel1 = findPattern(imageList(i,:));
            pairLabel2 = findPattern(imageList(j,:)); 
            pairs{k} = [pairLabel1, '-', pairLabel2];
%             fprintf('%s-%s value = %f, matrixValue = %f, overlap VoxelNb = %d, total Voxel = %d,\n ',...
%                                  pairLabel1, pairLabel2, pairwiseDice(k), ...
%                                  pairwiseDiceMatrix(i, j),overlapVox(i,j), totVox(i,j));
            k = k + 1;
        end
    end
end


function pattern = findPattern(fileName)

        p = bids.internal.parse_filename(spm_file(fileName, 'filename'));
        pattern = p.entities.desc(1:end-5);


end
