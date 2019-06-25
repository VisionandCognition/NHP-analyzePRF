function pRF_prepdata_avg(SessionList,doUpsample)
% collects data, concatenates, downsamples stimulus and resaves
% NB: won't run on macbook unless there's a USB-drive with all data 

% Extra regressor are not possible because we're averaging the BOLD here
% z-score per voxel and average over runs in a session

%% WHICH DATA =============================================================
%clear all; clc;
if nargin <2
    fprintf('Not enough arguments specified, will use defaults:\n');
    fprintf('SessionList: pRF_PrepDatalist_Danny\n');
    pRF_PrepDatalist_Danny;
    %pRF_PrepDatalist_Eddy;
    doUpsample = true;
else
    eval(SessionList);
end

%% Sweep to volume mapping ------------------------------------------------
TR = 2.5;
TR_3 = 3.0; % 20160721

SwVolMap_230 = { ... % 15 blanks / 20 steps
    1 , 6:25    ;...
    2 , 41:60   ;...
    3 , 61:80   ;...
    4 , 96:115  ;...
    5 , 116:135 ;...
    6 , 151:170 ;...
    7 , 171:190 ;...
    8 , 206:225 };

SwVolMap_210 = { ... % also for 215 vols
    1 , 6:25    ;... % 10 blanks / 20 steps
    2 , 36:55   ;...
    3 , 56:75   ;...
    4 , 86:105  ;...
    5 , 106:125 ;...
    6 , 136:155 ;...
    7 , 156:175 ;...
    8 , 186:205 };

SwVolMap_218 = { ... % 12 blanks / 20 steps
    1 , 6:25    ;...
    2 , 38:57   ;...
    3 , 58:77   ;...
    4 , 90:109  ;...
    5 , 110:129 ;...
    6 , 142:161 ;...
    7 , 162:181 ;...
    8 , 194:213 };

SwVolMap_436 = { ...
    1 , 6:25    ;...
    2 , 38:57   ;...
    3 , 58:77   ;...
    4 , 90:109  ;...
    5 , 110:129 ;...
    6 , 142:161 ;...
    7 , 162:182 ;...
    8 , 194:213 ;...
    1 , 224:243 ;...
    2 , 256:275 ;...
    3 , 276:295 ;...
    4 , 308:327 ;...
    5 , 328:347 ;...
    6 , 360:379 ;...
    7 , 380:399 ;...
    8 , 412:431 };

Is436 = false;

%% INITIALIZE =============================================================
% Platform specific basepath
if ispc
    tool_basepath = 'D:\CK\code\MATLAB';
    BIDS_basepath = '\\vs02\NHP_MRI\VandC\NHP_MRI\NHP-BIDS';
    BIDS_basepath = '\\vs02\VandC\NHP_MRI\NHP-BIDS';
else
    tool_basepath = '~/Dropbox/MATLAB_NONGIT/TOOLBOX';
    BIDS_basepath = '/NHP_MRI/NHP-BIDS/';
    addpath(genpath('/media/DOCUMENTS/DOCUMENTS/MRI_ANALYSIS/NHP-analyzePRF'));
end
% Add nifti reading toolbox
addpath(genpath(fullfile(tool_basepath, 'NIfTI')));
% Add Kendrick Kay's pRF analysis toolbox
addpath(genpath(fullfile(tool_basepath, 'analyzePRF')));

% Link to the brain mask
if strcmp(MONKEY, 'danny')
    BrainMask_file = fullfile(BIDS_basepath, 'manual-masks','final',...
        'sub-danny','ses-20180117','func','T1_to_func_brainmask_zcrop.nii');
elseif strcmp(MONKEY, 'eddy')
    BrainMask_file = fullfile(BIDS_basepath, 'manual-masks','final','sub-eddy',...
        'ses-20170607b','anat','HiRes_to_T1_mean.nii_shadowreg_Eddy_brainmask.nii');
else
    error('Unknown monkey name or no mask available')
end

% create a folder to save outputs in

if doUpsample
    out_folder = fullfile('..','Data',['pRF_sub-' MONKEY '_us-padded']);
else
    out_folder = fullfile('..','Data',['pRF_sub-' MONKEY '-padded']); %#ok<*UNRCH>
end
warning off %#ok<*WNOFF>
mkdir(out_folder);
warning on %#ok<*WNON>

%% GET THE FILE-PATHS OF THE IMAGING  & STIM-MASK FILES ===================
% All functional runs that are preprocessed with the BIDS pipeline are
% resampled to 1x1x1 mm isotropic voxels, reoriented from sphinx,
% motion corrected, (potentially smoothed with 2 mm FWHM), and
% registered to an example functional volume
% (so they're already in a common space)
% do the analysis in this functional space than we can register to hi-res
% anatomical data and/or the NMT template later
sessions = unique(DATA(:,1)); %#ok<*NODEF>

monkey_path_nii = fullfile(BIDS_basepath, 'derivatives',...
    'featpreproc','highpassed_files',['sub-' MONKEY]);
monkey_path_stim = fullfile(BIDS_basepath,['sub-' MONKEY]);

monkey_path_motion.regress = fullfile(BIDS_basepath, 'derivatives',...
    'featpreproc','motion_corrected',['sub-' MONKEY]);
monkey_path_motion.outlier = fullfile(BIDS_basepath, 'derivatives',...
    'featpreproc','motion_outliers',['sub-' MONKEY]);

for s=1:length(sessions)    
    sess_path_nii{s} = fullfile(monkey_path_nii, ['ses-' sessions{s}(1:8)], 'func'); %#ok<*SAGROW>
    sess_path_stim{s} = fullfile(monkey_path_stim, ['ses-' sessions{s}(1:8)], 'func');
    sess_path_motreg{s} = fullfile(monkey_path_motion.regress, ['ses-' sessions{s}(1:8)], 'func');
    sess_path_motout{s} = fullfile(monkey_path_motion.outlier, ['ses-' sessions{s}(1:8)], 'func');
    runs = unique(DATA(strcmp(DATA(:,1),sessions{s}),2));
    for r=1:length(runs)
        if ispc % the ls command works differently in windows
            a=ls( fullfile(sess_path_nii{s},['*run-' runs{r} '*.nii.gz']));
            run_path_nii{s,r} = fullfile(sess_path_nii{s},a(1:end-3));
            b = ls( fullfile(sess_path_stim{s}, ...
                ['*run-' runs{r} '*model*']));
            run_path_stim{s,r}= fullfile(sess_path_stim{s},b,'StimMask.mat');
            c=ls( fullfile(sess_path_motreg{s},['*run-' runs{r} '*.param.1D']));
            run_path_motreg{s,r} = fullfile(sess_path_motreg{s},c);
            d=ls( fullfile(sess_path_motout{s},['*run-' runs{r} '*.outliers.txt']));
            run_path_motout{s,r} = fullfile(sess_path_motout{s},d);
            e = ls( fullfile(sess_path_stim{s}, ...
                ['*run-' runs{r} '*model*']));
            run_path_rew{s,r}= fullfile(sess_path_stim{s},e,'RewardEvents.txt');
        else
            a = ls( fullfile(sess_path_nii{s},['*run-' runs{r} '*.nii.gz']));
            run_path_nii{s,r} = a(1:end-3);
            run_path_nii{s,r} = run_path_nii{s,r}(1:end-1);
            run_path_stim{s,r} = ls( fullfile(sess_path_stim{s}, ...
                ['*run-' runs{r} '*model*'],'StimMask.mat'));
            run_path_stim{s,r} = run_path_stim{s,r}(1:end-1);
            run_path_motreg{s,r} = ls( fullfile(sess_path_motreg{s}, ...
                ['*run-' runs{r} '*.param.1D']));
            run_path_motreg{s,r}=run_path_motreg{s,r}(1:end-1);
            run_path_motout{s,r} = ls( fullfile(sess_path_motout{s}, ...
                ['*run-' runs{r} '*_outliers.txt']));
            run_path_motout{s,r}=run_path_motout{s,r}(1:end-1);
            run_path_rew{s,r} = ls( fullfile(sess_path_stim{s}, ...
                ['*run-' runs{r} '*model*'],'RewardEvents.txt'));
            run_path_rew{s,r}=run_path_rew{s,r}(1:end-1);
        end
        sweepinc{s,r} = DATA( ...
            (strcmp(DATA(:,1),sessions{s}) & strcmp(DATA(:,2),runs{r})),3);
    end
end

%% LOAD & RE-SAVE STIMULUS MASKS & NIFTI ==================================
for s=1:size(run_path_stim,1) % sessions
    fprintf(['Processing session ' sessions{s} '\n']);
    rps = [];
    if strcmp(sessions{s},'20160721')
        TR=TR_3;
        fprintf('!!!! NB: This TR is 3s do not use in averaging !!!!\n');
        % should be excluded in the prepdata list
    end

    for i=1:size(run_path_stim,2)
        if ~isempty(run_path_stim{s,i})
            rps=[rps i];
        end
    end
    
    for r=rps % runs
        % stimulus mask -----
        % loads variable called stimulus (x,y,t) in volumes
        load(run_path_stim{s,r}(1:end-4));
        
        sinc = cell2mat(sweepinc{s,r});
        if size(stimulus,3) == 210 || size(stimulus,3) == 215
            SwVolMap = SwVolMap_210;
            Is436 = false;
        elseif size(stimulus,3) == 218
            SwVolMap = SwVolMap_218;
            Is436 = false;
        elseif size(stimulus,3) == 230
            SwVolMap = SwVolMap_230;
            Is436 = false;
        elseif size(stimulus,3) == 436
            SwVolMap = SwVolMap_436;  
            Is436 = true;
        else
            error('weird number of stimulus frames');
        end
        firstvol = SwVolMap{min(sinc),2}(1) - 5;
        lastvol = SwVolMap{max(sinc),2}(end) + 5;
        v_inc=firstvol:lastvol;
        v_all=1:size(stimulus,3);
        
        bin_vinc = zeros(1,size(stimulus,3));
        bin_vinc(v_inc) = 1;
                
        % volumes ------
        %fprintf('Unpacking nii.gz');
        %uz_nii=gunzip(run_path_nii{s,r});
        % >>> Unpacking is slow from within matlab. Do this in the system
        
        temp_nii=load_nii(run_path_nii{s,r});%load_nii(uz_nii{1});
        %delete(uz_nii{1});
        fprintf(' ...done\n');
              
        % save the session-based stims & vols -----
        for v=1:size(stimulus,3)
            % resample image (160x160 pix gives 10 pix/deg)
            s_run(r).stim{v} = imresize(stimulus(:,:,v_all(v)),[160 160]);
            s_run(r).vol{v} = temp_nii.img(:,:,:,v_all(v));
            if v==1
                s_run(r).hdr = temp_nii.hdr;
            end
        end
        
        % create nan volume/stim to pad with
        nanVol=nan(size(temp_nii.img(:,:,:,1)));
        nanStim=nan(160);
        
        % pad everything to 230 volumes
        p_run(r).stim = cell(1,230);
        p_run(r).vol = cell(1,230);
        p_run(r).hdr = s_run(r).hdr;
        p_run(r).inc = zeros(1,230);
        if Is436
            shiftruns=max(rps);
            p_run(r+shiftruns).stim = cell(1,230);
            p_run(r+shiftruns).vol = cell(1,230);
            p_run(r+shiftruns).hdr = s_run(r).hdr;
            p_run(r+shiftruns).inc = zeros(1,230);
        end
       
        if size(stimulus,3) <= 215 % 210/215
            p_run(r).stim = [ ...
                s_run(r).stim(1:SwVolMap{2,2}(1)-1) ...
                nanStim nanStim nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                nanStim nanStim nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                nanStim nanStim nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                nanStim nanStim nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r).inc = [ ...
                bin_vinc(1:SwVolMap{2,2}(1)-1) ...
                0 0 0 0 0 ....
                bin_vinc(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                0 0 0 0 0 ....
                bin_vinc(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                0 0 0 0 0 ....
                bin_vinc(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                0 0 0 0 0 ....
                bin_vinc(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r).vol = [ ...
                s_run(r).vol(1:SwVolMap{2,2}(1)-1) ...
                nanVol nanVol nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                nanVol nanVol nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                nanVol nanVol nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                nanVol nanVol nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            % add 5 blanks
        elseif size(stimulus,3) == 218
           p_run(r).stim = [ ...
                s_run(r).stim(1:SwVolMap{2,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                nanStim nanStim nanStim ...
                s_run(r).stim(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r).inc = [ ...
                bin_vinc(1:SwVolMap{2,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r).vol = [ ...
                s_run(r).vol(1:SwVolMap{2,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            % add 3 blanks
        elseif size(stimulus,3) == 230
            p_run(r).stim = s_run(r).stim;
            p_run(r).inc = bin_vinc;
            p_run(r).vol = s_run(r).vol;
            % as is
        elseif size(stimulus,3) == 436
            p_run(r).stim = [ ...
                s_run(r).stim(1:SwVolMap{2,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                nanStim nanStim nanStim ...
                s_run(r).stim(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r).inc = [ ...
                bin_vinc(1:SwVolMap{2,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r).vol = [ ...
                s_run(r).vol(1:SwVolMap{2,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            
            p_run(r+shiftruns).stim = [ ...
                s_run(r).stim(SwVolMap{9,2}(1)-5:SwVolMap{10,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{10,2}(1):SwVolMap{12,2}(1)-1) ...
                nanStim nanStim nanStim ...
                s_run(r).stim(SwVolMap{12,2}(1):SwVolMap{14,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{14,2}(1):SwVolMap{16,2}(1)-1) ...
                nanStim nanStim nanStim ....
                s_run(r).stim(SwVolMap{16,2}(1):SwVolMap{16,2}(end)+5) ...
                ];
            p_run(r+shiftruns).inc = [ ...
                bin_vinc(1:SwVolMap{2,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{2,2}(1):SwVolMap{4,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{4,2}(1):SwVolMap{6,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{6,2}(1):SwVolMap{8,2}(1)-1) ...
                0 0 0 ....
                bin_vinc(SwVolMap{8,2}(1):SwVolMap{8,2}(end)+5) ...
                ];
            p_run(r+shiftruns).vol = [ ...
                s_run(r).vol(SwVolMap{9,2}(1)-5:SwVolMap{10,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{10,2}(1):SwVolMap{12,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{12,2}(1):SwVolMap{14,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{14,2}(1):SwVolMap{16,2}(1)-1) ...
                nanVol nanVol nanVol ....
                s_run(r).vol(SwVolMap{16,2}(1):SwVolMap{16,2}(end)+5) ...
                ];
            % split and add 3 blanks
        end        

        clear stimulus temp_nii
        
        % if requested, upsample temporal resolution
        if doUpsample
            % stim ---
            tempstim = p_run(r).stim;
            ups_stim = cell(1,2*length(tempstim));
            ups_stim(1:2:end) = tempstim;
            ups_stim(2:2:end) = tempstim;
            p_run(r).stim = ups_stim;
            clear tempstim ups_stim
            
            % selected timepoints
            tempinc = p_run(r).inc;
            ups_inc = nan(1,2*length(tempinc));
            ups_inc(1:2:end) = tempinc;
            ups_inc(2:2:end) = tempinc;
            p_run(r).inc = ups_inc;
            
            % bold ---
            us_nii=[];
            for v=1:length(p_run(r).vol)
                us_nii=cat(4,us_nii,p_run(r).vol{v});
            end
            fprintf('Upsampling BOLD data...\n');
            us_nii = tseriesinterp(us_nii,TR,TR/2,4);
            for v=1:size(us_nii,4)
                p_run(r).vol{v} = us_nii(:,:,:,v);
            end
            clear us_nii
            
            if Is436
                % stim ---
                tempstim = p_run(r+shiftruns).stim;
                ups_stim = cell(1,2*length(tempstim));
                ups_stim(1:2:end) = tempstim;
                ups_stim(2:2:end) = tempstim;
                p_run(r+shiftruns).stim = ups_stim;
                clear tempstim ups_stim
                
                % selected timepoints
                tempinc = p_run(r+shiftruns).inc;
                ups_inc = nan(1,2*length(tempinc));
                ups_inc(1:2:end) = tempinc;
                ups_inc(2:2:end) = tempinc;
                p_run(r+shiftruns).inc = ups_inc;
                
                % bold ---
                us_nii=[];
                for v=1:length(p_run(r+shiftruns).vol)
                    us_nii=cat(4,us_nii,p_run(r+shiftruns).vol{v});
                end
                fprintf('Upsampling BOLD data...\n');
                us_nii = tseriesinterp(us_nii,TR,TR/2,4);
                for v=1:size(us_nii,4)
                    p_run(r+shiftruns).vol{v} = us_nii(:,:,:,v);
                end
                clear us_nii
            end
            
        end
    end
    fprintf(['Saving ses-' sessions{s} '\n']);
    save(fullfile(out_folder, ['ses-' sessions{s} '-230vols']),'p_run','-v7.3');
    fprintf('Saved result in code folder. Please move it manually...\n')
    clear s_run p_run
end