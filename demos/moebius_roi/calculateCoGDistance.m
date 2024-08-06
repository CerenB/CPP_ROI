function [dataTable] = calculateCoGDistance(opt, CoG)


savefileMat = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'CoGDistance_unthresh', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(opt.dir.roi, 'group', ...
    [opt.taskName, ...
    'CoGDistance_unthresh', ...
    opt.roi.atlas, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);


% Assuming centroid_data is already populated with centroid coordinates
subjectNb = size(CoG,3);
labels = {'Foot', 'Forehead', 'Hand', 'Lips', 'Tongue'};
centroidsNbPerSubject = size(CoG,1)/2;

% Generate pair labels
pairIdx = nchoosek(1:centroidsNbPerSubject, 2);
pairLabels = arrayfun(@(i) sprintf('%s-%s', ...
                            labels{pairIdx(i, 1)}, labels{pairIdx(i, 2)}),...
                            1:size(pairIdx, 1), 'UniformOutput', false);
pairNb = size(pairIdx, 1);                        

% Initialize arrays to store the data in column-wise format
subject = [];
hemisphere = [];
pair = [];
distance = [];
group = [];

for iSub = 1:subjectNb
    % Extract the right hemisphere centroids for the current subject
    rightCentroids = CoG(2:2:end, :, iSub); % Extracting rows 2, 4, 6, etc.
    
    % Extract the left hemisphere centroids for the current subject
    leftCentroids = CoG(1:2:end, :, iSub); % Extracting rows 1, 3, 5, etc.
    
    % Calculate pairwise Euclidean distances for right hemisphere centroids
    rightDistances = pdist(rightCentroids, 'euclidean');
    
    % Calculate pairwise Euclidean distances for left hemisphere centroids
    leftDistances = pdist(leftCentroids, 'euclidean');
    
    % Append data to the columns
    subject = [subject; repmat(iSub, pairNb, 1); repmat(iSub, pairNb, 1)];
    hemisphere = [hemisphere; repmat({'R'}, pairNb, 1); repmat({'L'}, pairNb, 1)];
    pair = [pair; pairLabels'; pairLabels'];
    distance = [distance; rightDistances'; leftDistances'];
    
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
dataTable = table(subject, hemisphere, pair, distance, group, ...
                   'VariableNames', {'Subject', 'Hemi', 'Pair', 'Distance', 'Group'});

% Write the table to a CSV file
writetable(dataTable, savefileCsv);

% Save the centroid data and distance matrices
save(savefileMat, 'dataTable');

end