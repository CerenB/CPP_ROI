function createMaskedTmaps(opt,funcFWHM)

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
