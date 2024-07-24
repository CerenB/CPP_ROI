function opt = chooseContrastsAndMasks(opt)


    opt.result.Steps(1) = returnDefaultResultsStructure();

    opt.result.Steps(1).Level = 'subject';


    roiList = spm_select('FPlist', ...
        fullfile(opt.dir.roi, 'group'), ...
        '.*space-.*_mask.nii$');
    roiList = cellstr(roiList);

    % contrasts
    contrastNames = {'Hand_gt_All','Foot_gt_All', 'Tongue_gt_All', ...
        'Lips_gt_All', 'Forehead_gt_All'};
    correction = 'none';
    pvalue = 0.001;
    minVoxelinCLuster = 20;

    counter = 1;
    for iMask = 1:size(roiList,1)

        p = bids.internal.parse_filename(roiList{iMask, :});
        maskLabel = [p.entities.hemi, p.entities.label];

        for iContrast = 1:size(contrastNames,2)

            opt.result.Steps(1).Contrasts(counter).Name = ...
                contrastNames{iContrast};
            opt.result.Steps(1).Contrasts(counter).MC =  correction;
            opt.result.Steps(1).Contrasts(counter).p = pvalue;
            opt.result.Steps(1).Contrasts(counter).k = minVoxelinCLuster;
            opt.result.Steps(1).Contrasts(counter).useMask = 1;
            opt.result.Steps(1).Contrasts(counter).maskLabel = maskLabel;
            opt.result.Steps(1).Contrasts(counter).mask = roiList(iMask, :);

            counter = counter +1;
        end
    end

  opt.result.Steps(1).Output.thresh_spm = true();

  opt.result.Steps(1).Output.binary = true();
  
  
end