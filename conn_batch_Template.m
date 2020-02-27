% Sample CONN Script for the OSU Workshop
% Created by Andrew Jahn, University of Michigan, 02.27.2020
% Adapted from Alfonso Nieto-Castanon's script, www.alfnie.com 

%% FIND functional/structural files
% note: this will look for all data in these folders, irrespestive of the specific download subsets entered as command-line arguments
NSUBJECTS=1;
cwd=pwd;
FUNCTIONAL_FILE=cellstr(conn_dir('sub-01_func_sub-01_task-rest_bold.nii.gz'));
STRUCTURAL_FILE=cellstr(conn_dir('sub-01_anat_sub-01_T1w.nii'));
if rem(length(FUNCTIONAL_FILE),NSUBJECTS),error('mismatch number of functional files %n', length(FUNCTIONAL_FILE));end
if rem(length(STRUCTURAL_FILE),NSUBJECTS),error('mismatch number of anatomical files %n', length(FUNCTIONAL_FILE));end
nsessions=length(FUNCTIONAL_FILE)/NSUBJECTS;
FUNCTIONAL_FILE=reshape(FUNCTIONAL_FILE,[NSUBJECTS,nsessions]);
STRUCTURAL_FILE={STRUCTURAL_FILE{1:NSUBJECTS}};
disp([num2str(size(FUNCTIONAL_FILE,1)),' subjects']);
disp([num2str(size(FUNCTIONAL_FILE,2)),' sessions']);
TR=3.56; % Repetition time


%% CONN-SPECIFIC SECTION: RUNS PREPROCESSING/SETUP/DENOISING/ANALYSIS STEPS
%% Prepares batch structure
clear batch;
batch.filename=fullfile(cwd,'Arithmetic_Scripted.mat');            % New conn_*.mat experiment name

%% SETUP & PREPROCESSING step (using default values for most parameters, see help conn_batch to define non-default values)
% CONN Setup                                            % Default options (uses all ROIs in conn/rois/ directory); see conn_batch for additional options 
% CONN Setup.preprocessing                               (realignment/coregistration/segmentation/normalization/smoothing)
batch.Setup.isnew=1;
batch.Setup.nsubjects=NSUBJECTS;
batch.Setup.RT=TR;                                        % TR (seconds)
batch.Setup.functionals=repmat({{}},[NSUBJECTS,1]);       % Point to functional volumes for each subject/session
for nsub=1:NSUBJECTS,for nses=1:nsessions,batch.Setup.functionals{nsub}{nses}{1}=FUNCTIONAL_FILE{nsub,nses}; end; end %note: each subject's data is defined by three sessions and one single (4d) file per session
batch.Setup.structurals=STRUCTURAL_FILE;                  % Point to anatomical volumes for each subject
nconditions=nsessions;                                  % treats each session as a different condition (comment the following three lines and lines 84-86 below if you do not wish to analyze between-session differences)
if nconditions==1
    batch.Setup.conditions.names={'rest'};
    for ncond=1,for nsub=1:NSUBJECTS,for nses=1:nsessions,              batch.Setup.conditions.onsets{ncond}{nsub}{nses}=0; batch.Setup.conditions.durations{ncond}{nsub}{nses}=inf;end;end;end     % rest condition (all sessions)
else
    batch.Setup.conditions.names=[{'rest'}, arrayfun(@(n)sprintf('Session%d',n),1:nconditions,'uni',0)];
    for ncond=1,for nsub=1:NSUBJECTS,for nses=1:nsessions,              batch.Setup.conditions.onsets{ncond}{nsub}{nses}=0; batch.Setup.conditions.durations{ncond}{nsub}{nses}=inf;end;end;end     % rest condition (all sessions)
    for ncond=1:nconditions,for nsub=1:NSUBJECTS,for nses=1:nsessions,  batch.Setup.conditions.onsets{1+ncond}{nsub}{nses}=[];batch.Setup.conditions.durations{1+ncond}{nsub}{nses}=[]; end;end;end
    for ncond=1:nconditions,for nsub=1:NSUBJECTS,for nses=ncond,        batch.Setup.conditions.onsets{1+ncond}{nsub}{nses}=0; batch.Setup.conditions.durations{1+ncond}{nsub}{nses}=inf;end;end;end % session-specific conditions
end
batch.Setup.preprocessing.steps='default_mni';
batch.Setup.preprocessing.sliceorder='interleaved (Siemens)';
batch.Setup.done=1;
batch.Setup.overwrite='Yes';

batch.Setup.rois.files{1}='ROIs/AndyROIs.nii';
batch.Setup.rois.multiplelabels = 1;

% batch.Setup.analyses = [1, 2]; % Only does seed-to-voxel and ROI-to-ROI analysis (3 and 4 do voxel-to-voxel and dynamic FC)

% uncomment the following 3 lines if you prefer to run one step at a time:
% conn_batch(batch); % runs Preprocessing and Setup steps only
% clear batch;
% batch.filename=fullfile(cwd,'Arithmetic_Scripted.mat');            % Existing conn_*.mat experiment name

%% DENOISING step
% CONN Denoising                                    % Default options (uses White Matter+CSF+realignment+scrubbing+conditions as confound regressors); see conn_batch for additional options 
batch.Denoising.filter=[0.01, 0.1];                 % frequency filter (band-pass values, in Hz)
batch.Denoising.done=1;
batch.Denoising.overwrite='Yes';

% uncomment the following 3 lines if you prefer to run one step at a time:
% conn_batch(batch); % runs Denoising step only
% clear batch;
% batch.filename=fullfile(cwd,'Arithmetic_Scripted.mat');            % Existing conn_*.mat experiment name

%% FIRST-LEVEL ANALYSIS step
% CONN Analysis                                     % Default options (uses all ROIs in conn/rois/ as connectivity sources); see conn_batch for additional options 
batch.Analysis.done=1;
batch.Analysis.overwrite='Yes';

%% Run all analyses
conn_batch(batch);

%% CONN Display
% launches conn gui to explore results
conn
conn('load',fullfile(cwd,'Arithmetic_Scripted.mat'));
conn gui_results

