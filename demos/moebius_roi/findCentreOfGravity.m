function findCentreOfGravity(opt,funcFWHM)

% inspired by bidsResults to find the contrasts, load, run matlabbatch and
% then rename the files 

% (C) Copyright 2020 CPP_SPM developers

  currentDirectory = pwd;

  [BIDS, opt] = setUpWorkflow(opt, 'computing GLM results');

  if isempty(opt.model.file)
    opt = createDefaultModel(BIDS, opt);
  end

  % loop trough the steps and more results to compute for each contrast
  % mentioned for each step
  for iStep = 1:length(opt.result.Steps)

    % Depending on the level step we migh have to define a matlabbatch
    % for each subject or just on for the whole group
    switch opt.result.Steps(iStep).Level

      case 'subject'

        % For each subject
        for iSub = 1:numel(opt.subjects)

          matlabbatch = {};

          subLabel = opt.subjects{iSub};

          results.dir = getFFXdir(subLabel, funcFWHM, opt);

          for iCon = 1:length(opt.result.Steps(iStep).Contrasts)

            matlabbatch = ...
                setBatchContrastFiles( ...
                                            matlabbatch, ...
                                            opt, ...
                                            subLabel, ...
                                            funcFWHM, ...
                                            iStep, ...
                                            iCon);

          end

          batchName = sprintf('compute_sub-%s_results', subLabel);

          saveAndRunWorkflow(matlabbatch, batchName, opt, subLabel);

          renameOutputResults(results);

          renamePng(results);

        end

      otherwise

        error('This BIDS model does not contain an analysis step I understand.');

    end

  end

  cd(currentDirectory);

end

function renameOutputResults(results)
  % we create new name for the nifti oupput by removing the
  % spmT_XXXX prefix and using the XXXX as label- for the file

  outputFiles = spm_select('FPList', results.dir, '^spmT_[0-9].*_sub-.*.nii$');

  for iFile = 1:size(outputFiles, 1)

    source = deblank(outputFiles(iFile, :));

    basename = spm_file(source, 'basename');
    split = strfind(basename, '_sub');
    p = bids.internal.parse_filename(basename(split + 1:end));
    p.label = basename(split - 4:split - 1);
    p.use_schema = false;

    newName = bids.create_filename(p);

    target = spm_file(source, 'basename', newName);

    movefile(source, target);
  end

end

function renamePng(results)
  %
  % removes the _XXX suffix before the PNG extension.

  pngFiles = spm_select('FPList', results.dir, '^sub-.*[0-9].png$');

  for iFile = 1:size(pngFiles, 1)
    source = deblank(pngFiles(iFile, :));
    basename = spm_file(source, 'basename');
    target = spm_file(source, 'basename', basename(1:end - 4));
    movefile(source, target);
  end

end



















% %find spmT image
% funcFWHM = 6;
% subLabel = opt.subjects{1};
% ffxDir = getFFXdir(subLabel, funcFWHM, opt);
% spmTmaps = spm_select('FPList', ffxDir, '^sub-.*.GtAll_.*.k-20_MC-none.*spmT.nii$');
% dataImage = deblank(spmTmaps(2,:));
% 
% 
% % find roi/mask image
% roiList = spm_select('FPlist', ...
%                          fullfile(opt.dir.roi, 'group'), ...
%                          '.*space-.*_mask.nii$');
% roiList = cellstr(roiList);
% roiImage = roiList{1, :};
% 
% 
% % masking the thresholded spmT map with our sensorimotor cx binary mask
% matlabbatch = {};
% matlabbatch{1}.spm.stats.results.spmmat = {'/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-stats/sub-ctrl001/stats/task-somatotopy_space-MNI_FWHM-6_desc-AuditoryCueParts/SPM.mat'};
% matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
% matlabbatch{1}.spm.stats.results.conspec.contrasts = 79;
% matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
% matlabbatch{1}.spm.stats.results.conspec.thresh = 0.001;
% matlabbatch{1}.spm.stats.results.conspec.extent = 20;
% matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
% matlabbatch{1}.spm.stats.results.conspec.mask.image.name = {'/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-roi/group/hemi-L_space-MNI_seg-hcpex_label-123ab_mask.nii,1'};
% matlabbatch{1}.spm.stats.results.conspec.mask.image.mtype = 0;
% matlabbatch{1}.spm.stats.results.units = 1;
% matlabbatch{1}.spm.stats.results.export{1}.png = true;
% matlabbatch{1}.spm.stats.results.export{2}.tspm.basename = 'hemi-L_space-MNI_mask-sensorimotorcx_cond-HandGtAll_p-0001_MC-none_k-20_FWHM-6';
% 
% % Run the job
% spm_jobman('run', matlabbatch);
% 
% 
% 
% % next: inthe new masked_spmT map, find the cluster size
% 
% % our new fileName = 
% maskedImage = 'spmT_0079_hemi-L_space-MNI_mask-sensorimotorcx_cond-HandGtAll_p-0001_MC-none_k-20_FWHM-6.nii';
% path = '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/cpp_spm-stats/sub-ctrl001/stats/task-somatotopy_space-MNI_FWHM-6_desc-AuditoryCueParts/';
% imageName = fullfile(path,maskedImage);
% hdr = spm_vol(imageName);
% img = spm_read_vols(hdr);
% 
% % convert nans to zeros
% temp = img;
% temp(isnan(temp)) = 0;
% 
% % count voxel numbers
% temp(temp>0) =1;
% sum(temp(:))
% 
% % Get the voxel indices (linear indices)
% voxel_indices = find(temp);
% 
% % Convert linear indices to subscripts (x, y, z coordinates)
% [x, y, z] = ind2sub(size(img), voxel_indices);
% voxelCoord = [x, y, z];
% 
% % Calculate the center of gravity (centroid) based on voxel coordinates
% centroid_x = mean(x);
% centroid_y = mean(y);
% centroid_z = mean(z);
% 
% % Combine into a single vector
% centroid = [centroid_x, centroid_y, centroid_z];
% 
% % Display the centroid coordinates
% fprintf('Cluster centroid: (%.2f, %.2f, %.2f)\n', centroid_x, centroid_y, centroid_z);
%     
% % convert space from slice number to world coordinate
% worldCoord = cor2mni(voxelCoord, roiImage);
%     
% % Calculate center of gravity (centroid)
% cluster_centroids(i, :) = mean(worldCoord, 1);
% 
% 
% 
