% (C) Copyright 2021 CPP ROI developers

clear all;
clc;


%addpath('../../lib/bids-matlab');

warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

% bidspm - use
run ../lib/CPP_BIDS_SPM_pipeline/initCppSpm.m;

%cpp_roi
run /Users/battal/Documents/GitHub/CPPLab/CPP_ROI/initCppRoi;

% to load the subjects
opt = getOptionMoebius();

% options : 'wang', 'neuromorphometrics', 'anatomy_toobox', 'visfAtlas'
opt.roi.atlas = 'hcpex';
opt.roi.space = {'MNI', 'individual'};
% chosen ones: 3b = primary sensory cx, 4 = primary motor cx
opt.roi.name = {'1', '2', '3a', '3b', '4','6a', '6d', '6v', 'FEF', 'PEF'};

%define folders
opt.roi.dir = fullfile(opt.dataDir , '..','derivatives','roi');

spm_mkdir(opt.roi.dir);

% check the atlas labels
%[atlasFile, lut] = getAtlasAndLut(opt.roi.atlas);

%define hemisphere
hemi = {'L', 'R'};

% extract ROIs from atlas in MNI space
for iHemi = 1:numel(hemi)

  for iROI = 1:numel(opt.roi.name)

    roiName = opt.roi.name{iROI};

    imageName = extractRoiFromAtlas(opt.roi.dir, opt.roi.atlas, roiName, hemi{iHemi});

  end

end


% individual space
opt.dir.stats = fullfile(opt.dataDir, '..', 'derivatives', 'cpp_spm-stats');

createIndividualROI(opt);

opt.glm.roibased.do = true;

bidsRoiBasedGLM(opt);
