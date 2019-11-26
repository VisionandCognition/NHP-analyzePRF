%% ck_Run_Aston
% use this file to run subfunctions
addpath(genpath('../../prfCode'));

%% SETTINGS ###############################################################
subj = 'Aston'; % Lick / Aston
sess = '20181004_B1'; % 20180807_B2 / 20181004_B1

Do.Load.Any         = true; 
Do.Load.DigChan     = false; % new files
Do.Load.MUA         = false; % new files
Do.Load.LFP         = false; % new files
Do.Load.Behavior    = false; % new files

Do.Load.ProcMUA     = true;
Do.Load.ProcLFP     = false;
Do.Load.ProcBEH     = true;

Do.SyncTimes        = true;
Do.SaveUncut        = false;

Do.SaveMUA_perArray = true;
Do.SaveLFP_perArray = false;

Do.CreatePrediction = false;

Do.FitPRF           = false;
Do.FitMUA           = false; % MUA data
Do.FitLFP           = false; % LFP data (split by freq band)

Do.PlotPRF_MUA      = false;
Do.PlotPRF_LFP      = false;

%% load data ==============================================================
if Do.Load.Any
    ck_Load(subj, sess, Do)
end

rmpath(genpath('../../prfCode'));