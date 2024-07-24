% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function opt = getOptionMoebiusROI()
    % opt = getOption()
    % returns a structure that contains the options chosen by the user to run
    % slice timing correction, pre-processing, FFX, RFX.

    if nargin < 1
        opt = [];
    end

    % suject to run in each group

%     opt.subjects = {'ctrl012','ctrl013'};
                      % 'ctrl014': for mototopy
% 
%                      
    opt.subjects = {'mbs001', 'mbs002', 'mbs003', 'mbs004', 'mbs005', ...
                   'mbs006', 'mbs007', ...
                    'ctrl002','ctrl003','ctrl004', 'ctrl005', 'ctrl007', ...
                    'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011', 'ctrl012', ...
                    'ctrl013','ctrl015', 'ctrl016','ctrl017'};

    % The directory where the data are located
    opt.dataDir = fullfile('/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/raw');
    opt.derivativesDir = fullfile(opt.dataDir, '..', 'derivatives','cpp_spm');

    % task to analyze
%     opt.taskName = 'mototopy';
    opt.taskName = 'somatotopy';
    

    % Suffix output directory for the saved jobs
%     opt.jobsDir = fullfile( ...
%                            opt.dataDir, '..', 'derivatives', ...
%                            'cpp_spm', 'JOBS', opt.taskName);
                       
    opt.model.file = fullfile(opt.dataDir,'../code/moebiusproject_fMRI_analysis', ...
                              'model', ['model-',opt.taskName,'_audCueParts_smdl.json']); 

    % options : 'wang', 'neuromorphometrics', 'anatomy_toobox', 'visfAtlas'
    opt.roi.atlas = 'hcpex';
    opt.roi.space = {'MNI', 'individual'};
    % chosen ones: 3b = primary sensory cx, 4 = primary motor cx
    opt.roi.name = {'1', '2', '3a', '3b', '4','6a', '6d', '6v', 'FEF', 'PEF'};

    %define folders for ROI
    opt.roi.dir = fullfile(opt.dataDir , '..','derivatives','roi');
    spm_mkdir(opt.roi.dir);
    
    opt.dir.stats = fullfile(opt.dataDir, '..', 'derivatives', 'cpp_spm-stats');
    
    opt.dir.roi = [opt.derivativesDir '-roi'];
    spm_mkdir(fullfile(opt.dir.roi, 'group'));

    opt.jobsDir = fullfile(opt.dir.roi, 'JOBS', opt.taskName);
    
    
    % add contrast of interests 
    %inclusive mask names 
    opt = chooseContrastsAndMasks(opt);
    
    % not sure if these are necessary...
    opt.sliceOrder = [];
    opt.STC_referenceSlice = [];

    % Options for normalize
    % Voxel dimensions for resampling at normalization of functional data or leave empty [ ].
    opt.funcVoxelDims = [];

    opt.parallelize.do = false;

    %% DO NOT TOUCH
    opt = checkOptions(opt);
    saveOptions(opt);

end
