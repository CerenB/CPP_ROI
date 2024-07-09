% (C) Copyright 2021 CPP ROI developers

clear all;
clc;


addpath('../../lib/bids-matlab');

warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

run ../../initCppRoi;

% options : 'wang', 'neuromorphometrics', 'anatomy_toobox', 'visfAtlas'
opt.roi.atlas = 'hcpex';

[atlasFile, lut] = getAtlasAndLut(opt.roi.atlas);

% to get the list of possible run `getLookUpTable(opt.roi.atlas)`
% chosen ones: 3b = primary sensory cx, 4 = primary motor cx
opt.roi.name = {'1', '2', '3a', '3b', '4','6a', '6d', '6v', 'FEF', 'PEF'};
opt.roi.dir = fullfile(pwd, '..','output');

spm_mkdir(opt.roi.dir);

hemi = {'L', 'R'};

for iHemi = 1:numel(hemi)

  for iROI = 1:numel(opt.roi.name)

    roiName = opt.roi.name{iROI};

    imageName = extractRoiFromAtlas(opt.roi.dir, opt.roi.atlas, roiName, hemi{iHemi});

  end

end
