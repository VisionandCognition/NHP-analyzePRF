% ck_MakePlots
% Takes the pre-processed fitting result tables and creates comparison plots

%% Paths ==================================================================
BaseFld = pwd;
DS='ORG';
ResFld = ...
    ['/Users/chris/Documents/MRI_ANALYSIS/NHP-PRF/'...
    'FitResults/MultiModal/' DS '/cv1'];
TT='Tables_mean';

% add colorbrewer
addpath('/Users/chris/Dropbox/MATLAB_NONGIT/TOOLBOX/BrewerMap')
def_cmap = 'Spectral';

ResType = 'mean'; % max / mean
TT = ['Tables_' ResType];

% figure saving folder
[~,~] = mkdir('fig_png');
figfld = fullfile(pwd,'fig_png');

%% Load ===================================================================
fprintf(['Loading results table. '...
    'Please be patient, this will take a while..\n']);
tic; load(fullfile(ResFld,TT)); t_load=toc;
fprintf(['Loading took ' num2str(t_load) ' s\n']);

%% Correct for result type ================================================
fprintf('Generalizing variable names...\n');
fprintf('MRI...'); 
eval(['tMRI = tMRI_' ResType '; clear tMRI_' ResType ';']);
fprintf('MUA...'); 
eval(['tMUA = tMUA_' ResType '; clear tMUA_' ResType ';']);
fprintf('LFP...'); 
eval(['tLFP = tLFP_' ResType '; clear tLFP_' ResType ';']);
fprintf('>> DONE\n');

%% Split MRI table by model ===============================================
m = unique(tMRI.Model);
for mi = 1:length(m)
    M = tMRI(strcmp(tMRI.Model,m{mi}),:);
    T(mi).mod = M;
    T(mi).name = m{mi};
    modidx.(m{mi}) = mi;
end

%% Initiate some information ==============================================
% proces ROI info
rois = {...
    'V1',   [34];...            % occipital / visual
    'V2',   [131];...           % occipital / visual
    'V3',   [123,60,93];...     % occipital / visual
    'V4',   [20,39,75];...      % mid-visual
    'MT',   [95];...            % mid-visual
    'MST',  [99];...            % mid-visual
    'TEO',  [125];...           % temporal
    'TAa',  [152];...           % temporal
    'Tpt',  [97];...            % temporal (temporal/parietal)
    'TPO',  [159];...           % temporal
    'FST',  [53];...            % temporal
    'VIP',  [30];...            % parietal
    'LIP',  [31,130];...        % parietal
    '1-2',  [50];...            % parietal (somatosensory)
    '5',    [5,134];...         % parietal
    '7',    [91,121];...        % parietal
    'PULV', [197,198];...       % subcortical
    'LGN',  [200,201];...       % subcortical
    'STR',  [175];...           % subcortical
    'SI',   [137];...           % Prim Somatosensory
    'SII',  [63];...            % Sec Somatosensory
    '23',   [6,17,27];...       % cingulate
    'F2',   [153];...           % premotor
    'F4',   [146];...           % premotor
    'F5',   [129];...           % premotor
    'F7',   [126];...           % premotor
    '8A',   [51,148];...        % frontal FEF
    '8B',   [32,57];...         % frontal FEF
    'DLPFC',[76,127];...        % frontal
    'OFC',  [55,107];...        % frontal
    'INS',  [18,87,128];...     % frontal
    'CIN',  [45,98];...         % frontal
    'PFC',  [25,47];...         % frontal
};

roi=rois(:,2);
roilabels=rois(:,1);

MRI_MODELS={...
    'linhrf_cv1_mhrf','linhrf_cv1_dhrf';...
    'linhrf_cv1_mhrf_neggain','linhrf_cv1_dhrf_neggain';...
    'csshrf_cv1_mhrf','csshrf_cv1_dhrf';...
    'doghrf_cv1_mhrf','doghrf_cv1_dhrf';...
    };
MMS={...
    'LIN_m','LIN_d';...
    'LIN-N_m','LIN-N_d';...
    'CSS_m','CSS_d';...
    'DOG_m','DOG_d';...
    };

SUBS = unique(tMRI.Monkey);

%% Number of significant voxels per ROI (split by monkey and model) =======
for s = 1: length(SUBS)
    for r = 1:length(roi)
    end
end



%% MRI scatter plots & differences R2 =====================================
RTHRES = 1;

% scatter plots ---
f=figure;
set(f,'DefaultAxesColorOrder',brewermap(length(roi),def_cmap));
set(f,'Position',[10 10 800 1000]);
s_R2 = T(modidx.linhrf_cv1_mhrf).mod.R2>RTHRES; % allows selection but keep at 0

paneln=1;
for rowmod=1:4
    for colmod=rowmod+1:4
        subplot(3,2,paneln); hold on;
        plot([0 100],[0 100],'k','Linewidth',2);
        for r=1:length(roi)
            SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
                ck_GetROIidx(roilabels(r),rois) );
            scatter(T(modidx.(MRI_MODELS{rowmod,1})).mod.R2(SSS),...
                T(modidx.(MRI_MODELS{colmod,1})).mod.R2(SSS),100,'Marker','.');
        end
        title([MMS{rowmod,1} ' vs ' MMS{colmod,1}],'interpreter','none'); 
        xlabel(MMS{rowmod,1},'interpreter','none');
        ylabel(MMS{colmod,1},'interpreter','none');
        set(gca, 'Box','off', 'xlim', [0 100], 'ylim',[0 100]);
        paneln=paneln+1;
    end
end
saveas(f,fullfile(figfld, 'MRI_ModelComparison_R2.png'));

% diff distributions plots -----
idx=1;
for rowmod=1:4
    for colmod=rowmod+1:4
        diffmat{idx}=[];
        for r=1:length(roi)
            SSS = s_R2 & ...
                ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
                ck_GetROIidx(roilabels(r),rois) );
            
            [n,x] = hist(...
                T(modidx.(MRI_MODELS{colmod,1})).mod.R2(SSS)-...
                T(modidx.(MRI_MODELS{rowmod,1})).mod.R2(SSS), 100);
            f = n./sum(SSS);
            
            m = mean(T(modidx.(MRI_MODELS{colmod,1})).mod.R2(SSS)-...
                T(modidx.(MRI_MODELS{rowmod,1})).mod.R2(SSS));
            sd = std(T(modidx.(MRI_MODELS{colmod,1})).mod.R2(SSS)-...
                T(modidx.(MRI_MODELS{rowmod,1})).mod.R2(SSS));
            se = sd ./ sqrt(sum(SSS));
            diffmat{idx} = [diffmat{idx}; m sd se];
        end
        idx=idx+1;
    end
end

f2=figure;
set(f2,'DefaultAxesColorOrder',brewermap(length(roi),def_cmap));
set(f2,'Position',[100 100 1800 1000]);

cc=1;
for rowmod=1:4
    for colmod=rowmod+1:4
        subplot(3,2,cc); hold on;
        for xval=1:length(diffmat{cc})
            bar(xval,diffmat{cc}(xval,1));
        end
        for xval=1:length(diffmat{cc})
            errorbar(xval,diffmat{cc}(xval,1),diffmat{cc}(xval,3),...
                'k-','Linestyle','none');
        end
        set(gca,'xtick',1:length(diffmat{cc}),...
            'xticklabels',roilabels,'ylim',[-2 2.5]);
        xlabel('ROI'); ylabel('Diff R2');
        title([MMS{colmod,1} ' - ' MMS{rowmod,1}],...
            'interpreter','none');
        xtickangle(45)
        cc=cc+1;
    end
end
saveas(f2,fullfile(figfld, 'MRI_ModelComparison_ROI_R2.png'));

%% Value of exponential parameter for CSS across ROIs =====================





%% MRI scatter plot HRF & differences =====================================
RTHRES = 0;

f3=figure;
set(f3,'Position',[100 100 2000 1200]);
set(f3,'DefaultAxesColorOrder',brewermap(length(roi),def_cmap));
s_R2 = T(modidx.linhrf_cv1_mhrf).mod.R2>RTHRES;

for mm = 1:size(MRI_MODELS,1)
    subplot(4,3,(mm-1)*3 +1); hold on;
    plot([0 100],[0 100],'k','LineWidth',2);
    for r=1:length(roi)
        SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
                ck_GetROIidx(roilabels(r),rois) );
        scatter(T(modidx.(MRI_MODELS{mm,1})).mod.R2(SSS),...
            T(modidx.(MRI_MODELS{mm,2})).mod.R2(SSS),100,'Marker','.');
    end
    title(['mHRF vs cHRF (' MRI_MODELS{mm,1} ')'],'interpreter','none'); 
    xlabel('Monkey HRF R2'); ylabel('Canonical HRF R2');
    set(gca, 'Box','off', 'xlim', [0 100], 'ylim',[0 100]);

    diffmat2{1}=[];
    for r=1:length(roi)
        SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
                ck_GetROIidx(roilabels(r),rois) );
        [n,x] = hist(...
            T(modidx.(MRI_MODELS{mm,1})).mod.R2(SSS)-...
            T(modidx.(MRI_MODELS{mm,2})).mod.R2(SSS),100);
        f = n./sum(SSS);
    
        m = mean(T(modidx.(MRI_MODELS{mm,1})).mod.R2(SSS)-...
            T(modidx.(MRI_MODELS{mm,2})).mod.R2(SSS));
        sd = std(T(modidx.(MRI_MODELS{mm,1})).mod.R2(SSS)-...
            T(modidx.(MRI_MODELS{mm,2})).mod.R2(SSS));
        nvox = sum(SSS);
        se = sd ./ sqrt(nvox);
        diffmat2{1} = [diffmat2{1}; m sd se nvox];
    end

    subplot(4,3,(mm-1)*3 +2); hold on
    for xval=1:length(diffmat2{1})
        bar(xval,diffmat2{1}(xval,1));
    end
    for xval=1:length(diffmat2{1})
        errorbar(xval,diffmat2{1}(xval,1),diffmat2{1}(xval,3),...
        'k-','Linestyle','none')
    end
    % mean (taking nvox into account)
    mAll = sum((diffmat2{1}(:,1).*diffmat2{1}(:,4)))./...
        sum(diffmat2{1}(:,4));    
    text(0.5, -0.4,num2str(mAll))
    set(gca,'xticklabels',[],'ylim',[-0.65 1]);
    xlabel('ROI'); ylabel('Diff R2');
    title(['mHRF - cHRF (' MRI_MODELS{mm,1} ')'],'interpreter','none'); 
    %legend(roilabels,'interpreter','none','Location','NorthEast');
    set(gca,'xtick',1:length(diffmat2{1}),'xticklabels',roilabels);
    xtickangle(45)
    
    subplot(4,3,(mm-1)*3 +3); hold on
    for xval=1:length(diffmat2{1})
        bar(xval,diffmat2{1}(xval,4));
    end
    set(gca,'xticklabels',[]);
    xlabel('ROI'); ylabel('# voxels');
    title(['mHRF - cHRF (' MRI_MODELS{mm,1} ')'],'interpreter','none');
    set(gca,'xtick',1:length(diffmat2{1}),'xticklabels',roilabels);
    xtickangle(45)
    %legend(roilabels,'interpreter','none','Location','NorthEast');
end
saveas(f3,fullfile(figfld, 'HRF_Comparison.png'));

%% MRI rf size depending on HRF ===========================================
R2th=5;

f4=figure;
set(f4,'Position',[100 100 1800 1200]);
set(f4,'DefaultAxesColorOrder',brewermap(length(roi),def_cmap));

s_R2 = T(modidx.csshrf_cv1_mhrf).mod.R2 > R2th;

for mm = 1:size(MRI_MODELS,1)
    
    sp=subplot(4,3,(mm-1)*3 +1);hold on;
    plot([0 100],[0 100],'k','LineWidth',2);
    for r=1:length(roi)
        SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
            ck_GetROIidx(roilabels(r),rois) );
        
        scatter(T(modidx.(MRI_MODELS{mm,1})).mod.rfs(SSS),...
            T(modidx.(MRI_MODELS{mm,2})).mod.rfs(SSS),100,'Marker','.');
    end
    title(['mHRF vs cHRF (' MMS{mm,1} ')'],'interpreter','none'); 
    xlabel('Monkey HRF sz');ylabel('Canonical HRF sz');
    set(gca, 'Box','off', 'xlim', [0 15], 'ylim',[0 15]);
    text('Parent',sp,'Position',[1 13], ...
        'String',['R2th: ' num2str(R2th)],...
        'Fontsize',12, 'Fontweight','bold')

    diffmat2{1}=[];
    for r=1:length(roi)
        SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
            ck_GetROIidx(roilabels(r),rois) );
        [n,x] = hist(...
            T(modidx.(MRI_MODELS{mm,1})).mod.rfs(SSS) - ...
            T(modidx.(MRI_MODELS{mm,2})).mod.rfs(SSS), 100);
        f = n./sum(SSS);
        
        dsz = T(modidx.(MRI_MODELS{mm,1})).mod.rfs - ...
            T(modidx.(MRI_MODELS{mm,2})).mod.rfs;
        dsz = dsz(SSS);
        dsz = dsz(isfinite(dsz));
        
        m = mean(dsz);
        sd = std(dsz);
        se = sd ./ sqrt(length(dsz));
        diffmat2{1} = [diffmat2{1}; m sd se size(dsz,1)];
    end
    
    
    subplot(4,3,(mm-1)*3 +2); hold on
    for xval=1:size(diffmat2{1},1)
        bar(xval,diffmat2{1}(xval,1));
    end
    for xval=1:size(diffmat2{1},1)
        errorbar(xval,diffmat2{1}(xval,1),diffmat2{1}(xval,3),...
            'k-','Linestyle','none')
    end
    set(gca,'xticklabels',[],'ylim',[-2 2.5]);
    xlabel('ROI'); ylabel('Diff pRF size');
    title(['mHRF - cHRF (' MMS{mm,1} ')'],'interpreter','none'); 
    %legend(roilabels,'interpreter','none','Location','NorthEast');
    set(gca,'xtick',1:length(diffmat2{1}),'xticklabels',roilabels);
    xtickangle(45)

    subplot(4,3,(mm-1)*3 +3); hold on
    for xval=1:size(diffmat2{1},1)
        bar(xval,diffmat2{1}(xval,4));
    end

    set(gca,'xticklabels',[]);
    xlabel('ROI'); ylabel('Number of voxels');
    title(['mHRF - cHRF (' MMS{mm,1} ')'],'interpreter','none'); 
    set(gca,'xtick',1:length(diffmat2{1}),'xticklabels',roilabels);
    xtickangle(45)
end
saveas(f4,fullfile(figfld, 'HRF_Comparison_pRF-Size.png'));

%% MRI ECC vs PRF Size ====================================================
Rth=10; 

f5=figure;
set(f5,'Position',[100 100 1000 1200]);
set(f5,'DefaultAxesColorOrder',brewermap(length(roi),def_cmap));

for m=1:length(MRI_MODELS)
    s_R2 = T(modidx.(MRI_MODELS{m,1})).mod.R2 > Rth;
    EccBin = 0.5:1:30.5;
    
    subplot(4,2,(m-1)*2 +1);hold on;
    for r=1:length(roi)
        SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{rowmod,1})).mod.ROI,...
            ck_GetROIidx(roilabels(r),rois) );

        ES{r}=[];
        scatter(T(modidx.(MRI_MODELS{m,1})).mod.ecc(SSS),...
            T(modidx.(MRI_MODELS{m,1})).mod.rfs(SSS),100,'Marker','.');
        for b=1:length(EccBin)
            bb=[EccBin(b)-0.5 EccBin(b)+0.5];
            PSZ=T(modidx.(MRI_MODELS{m,1})).mod.rfs(SSS);
            ECC=T(modidx.(MRI_MODELS{m,1})).mod.ecc(SSS);
            ES{r}=[ES{r}; EccBin(b) median(PSZ(ECC>=bb(1) & ECC<=bb(2)))];
        end
    end
    title(['Ecc vs pRF size [' MRI_MODELS{m,1} ', R>' num2str(Rth) ']'],...
        'interpreter','none');
    xlabel('Eccentricity');ylabel('pRF size');
    set(gca, 'Box','off', 'xlim', [0 10], 'ylim',[0 10]);
    
    subplot(4,2,(m-1)*2 +2);hold on;
    for r=1:length(roi)
        h=plot(ES{r}(:,1),ES{r}(:,2),'o');
        set(h,'MarkerSize',6,'markerfacecolor', get(h, 'color'));
    end
    title(['Ecc vs pRF size [' MMS{m,1} ', R>' num2str(Rth) ']'],...
        'interpreter','none'); xlabel('Eccentricity');ylabel('pRF size');
    set(gca, 'Box','off', 'xlim', [0 10], 'ylim',[0 10]);
    %legend(roilabels,'interpreter','none','Location','NorthWest');
end
saveas(f5,fullfile(figfld, 'MRI_Ecc_vs_Size.png'));

%% EPHYS VFC ==============================================================
% MUA
s=tMUA.R2>20;
szm=tMUA.rfs<200;

model='css_ephys_cv1';

fm=figure;
set(fm,'Position',[100 100 800 800]);
%[cmap,~,~] = brewermap(length(unique(tMUA.Array)),'Dark2');
%set(fm,'DefaultAxesColorOrder',cmap);

subplot(2,2,1);hold on;

szm=tMUA.rfs<5;
m=strcmp(tMUA.Monkey,'lick') & strcmp(tMUA.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tMUA.Area==1;
for r=unique(tMUA.Array)'
    a=tMUA.Array==r;
    scatter(tMUA.X(s & m & a & v),...
        tMUA.Y(s & m & a & v),'Marker','*' )
end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Lick V1 MUA')

subplot(2,2,3);hold on;
szm=tMUA.rfs<5;
m=strcmp(tMUA.Monkey,'lick') & strcmp(tMUA.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tMUA.Area==4;
for r=unique(tMUA.Array)'
    a=tMUA.Array==r;
    scatter(tMUA.X(s & m & a & v),...
        tMUA.Y(s & m & a & v),'Marker','*' )

end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Lick V4 MUA')

subplot(2,2,2);hold on;
m=strcmp(tMUA.Monkey,'aston') & strcmp(tMUA.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tMUA.Area==1;
for r=unique(tMUA.Array)'
    a=tMUA.Array==r;
    scatter(tMUA.X(s & m & a & v),...
        tMUA.Y(s & m & a & v),'Marker','*' )

end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Aston V1 MUA')

subplot(2,2,4);hold on;
m=strcmp(tMUA.Monkey,'aston') & strcmp(tMUA.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tMUA.Area==4;
for r=unique(tMUA.Array)'
    a=tMUA.Array==r;
    scatter(tMUA.X(s & m & a & v),...
        tMUA.Y(s & m & a & v),'Marker','*' )

end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Aston V4 MUA')

saveas(fm,fullfile(figfld, ['EPHYS_VFC_MUA_' model '.png']));

%% Ephys VFC ==============================================================
% LFP Low Gamma
s=tLFP.R2>20;

model='css_ephys_cv1';
b = 'lGamma';
fm=figure;
set(fm,'Position',[100 100 800 800]);

subplot(2,2,1);hold on;
szm=tLFP.rfs<50;
m=strcmp(tLFP.Monkey,'lick') & ...
    strcmp(tLFP.Model, model) & ...
    strcmp(tLFP.SigType, b);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tLFP.Area==1;
for r=unique(tLFP.Array)'
    a=tLFP.Array==r;
    scatter(tLFP.X(s & m & a & v),...
        tLFP.Y(s & m & a & v),'Marker','*' )
end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Lick V1 LFP (lGAM)')

subplot(2,2,3);hold on;
szm=tLFP.rfs<50;
m=strcmp(tLFP.Monkey,'lick') & strcmp(tLFP.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tLFP.Area==4;
for r=unique(tLFP.Array)'
    a=tLFP.Array==r;
    scatter(tLFP.X(s & m & a & v),...
        tLFP.Y(s & m & a & v),'Marker','*' )

end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Lick V4 LFP (lGAM)')

subplot(2,2,2);hold on;
m=strcmp(tLFP.Monkey,'aston') & strcmp(tLFP.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tLFP.Area==1;
for r=unique(tLFP.Array)'
    a=tLFP.Array==r;
    scatter(tLFP.X(s & m & a & v),...
        tLFP.Y(s & m & a & v),'Marker','*' )

end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Aston V1 LFP (lGAM)')

subplot(2,2,4);hold on;
m=strcmp(tLFP.Monkey,'aston') & strcmp(tLFP.Model,model);
plot([-10 20],[0 0],'k');
plot([0 0],[-30 10],'k');
v=tLFP.Area==4;
for r=unique(tLFP.Array)'
    a=tLFP.Array==r;
    scatter(tLFP.X(s & m & a & v),...
        tLFP.Y(s & m & a & v),'Marker','*' )

end
set(gca, 'Box','off', 'xlim', [-5 10], 'ylim',[-10 5]);
title('Aston V4 LFP (lGAM)')

saveas(fm,fullfile(figfld, ['EPHYS_VFC_LFP_' model '.png']));


%% Ephys location difference & size difference  ---------------------------
rth=25;

ephys_MOD={'linear_ephys_cv1','linear_ephys_cv1_neggain',...
    'css_ephys_cv1','dog_ephys_cv1'};
ephys_MMS = MMS(:,1);
clear C R2m SZ
for m=1:length(ephys_MOD)
 
    C{m}=[];R2m{m}=[];SZ{m}=[];
    
    model=ephys_MOD{m};
    s = strcmp(tMUA.Model,model);
    C{m}=[C{m} tMUA.R2(s) tMUA.X(s) tMUA.Y(s) tMUA.rfs(s)];
    R2m{m}=[R2m{m} tMUA.R2(s)];
    SZ{m}=[SZ{m} tMUA.R2(s) tMUA.rfs(s)];
    
    s = strcmp(tMUA.Model,'classicRF');
    C{m}=[C{m} tMUA.X(s)./668.745 tMUA.Y(s)./668.745 tMUA.rfs(s)./2];
    
    s = strcmp(tLFP.Model,model);
    sig=unique(tLFP.SigType);
    lfp_order = [3 1 2 5 4];
    for i=lfp_order
        b=strcmp(tLFP.SigType,sig{i});
        C{m}=[C{m} tLFP.R2(s & b) tLFP.X(s & b) tLFP.Y(s & b) tLFP.rfs(s & b)];
        R2m{m}=[R2m{m} tLFP.R2(s & b)];
        SZ{m}=[SZ{m} tLFP.R2(s & b) tLFP.rfs(s & b)];
    end
    
    s= sum(R2m{m}>rth,2)==size(R2m{m},2);
    distRF{m} = [...
        sqrt(((C{m}(s,2)-C{m}(s,5)).^2) + ((C{m}(s,3)-C{m}(s,6)).^2)) ...
        sqrt(((C{m}(s,2)-C{m}(s,9)).^2) + ((C{m}(s,3)-C{m}(s,10)).^2)) ...
        sqrt(((C{m}(s,2)-C{m}(s,13)).^2) + ((C{m}(s,3)-C{m}(s,14)).^2)) ...
        sqrt(((C{m}(s,2)-C{m}(s,17)).^2) + ((C{m}(s,3)-C{m}(s,18)).^2)) ...
        sqrt(((C{m}(s,2)-C{m}(s,21)).^2) + ((C{m}(s,3)-C{m}(s,22)).^2)) ];
    
    distSZ{m} = [...
        C{m}(s,4)-C{m}(s,7) ...
        C{m}(s,4)-C{m}(s,11) ...
        C{m}(s,4)-C{m}(s,15) ...
        C{m}(s,4)-C{m}(s,19) ...
        C{m}(s,4)-C{m}(s,23) ];
       
    normSz{m} = [...
        C{m}(s,7)./C{m}(s,4) ...
        C{m}(s,11)./C{m}(s,4) ...
        C{m}(s,15)./C{m}(s,4) ...
        C{m}(s,19)./C{m}(s,4) ...
        C{m}(s,23)./C{m}(s,4) ];
end

%% MUA model comparison ===================================================
m=unique(tMUA.Model);
R2=[];
for i=1:length(m)
    R2 = [R2 tMUA.R2(strcmp(tMUA.Model,m{i}))];
end

v1=tLFP.Area(strcmp(tMUA.Model,m{1}))==1;
v4=tLFP.Area(strcmp(tMUA.Model,m{1}))==4;

f6=figure;
set(f6,'Position',[100 100 1200 1200]);
for row=1:4
    for column=1:4
        subplot(4,4,((row-1)*4)+column); hold on;
        plot([0 100],[0 100],'k');
        scatter(R2(v1,row+1), R2(v1,column+1),60,'Marker','.',...
            'MarkerEdgeColor',[.3 .3 .3]);
        scatter(R2(v4,row+1), R2(v4,column+1),60,'Marker','.',...
            'MarkerEdgeColor',[.3 .8 .3]);
        set(gca, 'Box','off', 'xlim', [0 100], 'ylim',[0 100]);
        xlabel(m{row+1},'interpreter','none'); 
        ylabel(m{column+1},'interpreter','none');
        title('MUA');
        if row==1 && column==1
            legend({'','V1','V4'},'location','NorthWest');
        end
    end
end
saveas(f6,fullfile(figfld, 'EPHYS_MUA_ModelComparison.png'));

%% LFP model comparison ===================================================
f7=figure; 
set(f7,'Position',[100 100 1600 1200]);

sig=unique(tLFP.SigType);
lfp_order = [3 1 2 5 4];
spn=1;
for fb=lfp_order
    m=unique(tLFP.Model);
    R2=[];
    for i=1:length(m)
        R2 = [R2 tLFP.R2(...
            strcmp(tLFP.Model,m{i}) & ...
            strcmp(tLFP.SigType,sig{fb}))];
    end
    
    for m1=1:4
        for m2=m1+1:4
            subplot(length(sig),6,spn); hold on;
            plot([0 100],[0 100],'k');
            scatter(R2(v1,m1), R2(v1,m2),60,'Marker','.',...
                'MarkerEdgeColor',[.3 .3 .3]);
            scatter(R2(v4,m1), R2(v4,m2),60,'Marker','.',...
                'MarkerEdgeColor',[.3 .8 .3]);
            set(gca, 'Box','off', 'xlim', [0 100], 'ylim',[0 100]);
            xlabel(m{m1},'interpreter','none');ylabel(m{m2},'interpreter','none')
            title(sig{fb})
            if spn==1
                legend({'','V1','V4'},'location','SouthEast');
            end
            spn=spn+1;
        end
    end
end
saveas(f7,fullfile(figfld, 'EPHYS_LFP_ModelComparison.png'));

%% R2 for different ephys signals =========================================
r2th=0;

RR=[];
ephys_MOD={'linear_ephys_cv1','linear_ephys_cv1_neggain',...
    'css_ephys_cv1','dog_ephys_cv1'};
ephys_MMS = MMS(:,1);

for m=1:length(ephys_MOD)
    model=ephys_MOD{m};
    s = strcmp(tMUA.Model,model);
    RR=[RR tMUA.R2(s)];
    
    s = strcmp(tLFP.Model,model);
    sig=unique(tLFP.SigType);
    lfp_order = [3 1 2 5 4];
    for i=lfp_order
        b=strcmp(tLFP.SigType,sig{i});
        RR=[RR tLFP.R2(s & b)];
    end
    LAB=['MUA';sig(lfp_order)];
    
    f8=figure; set(f8,'Position',[100 100 1300 1200]);
    sgtitle(['R2 per Model: ' model],'interpreter','none');
    r2th=0;
    
    c=0;d=0;
    for ref=1:6
        c=c+1;
        for fb=1:6
            d=d+1;
            s=(RR(:,ref)>r2th & RR(:,fb)>r2th);
            subplot(6,6,d); hold on; plot([0 100],[0 100],'k');
            scatter(RR(s,ref),RR(s,fb),120,[0.3 0.3 0.3],'Marker','.')
            xlabel(LAB{ref});ylabel(LAB{fb});
            title(['R2 ' model],'interpreter','none');
            set(gca,'xlim',[0 100],'ylim',[0 100]);
        end
    end
    saveas(f8,fullfile(figfld, ['EPHYS_MUA_R2_' ephys_MOD{m} '.png']));  
    
    % Distance from diagonal ==============================================
    f9=figure; set(f9,'Position',[100 100 1300 1200]);
    LAB=['MUA';sig(lfp_order)];
    sgtitle(['Differences Model: ' model],'interpreter','none');

    c=0;d=0;
    for ref=1:6
        c=c+1;
        for fb=1:6
            d=d+1;
            s=(RR(:,ref)>r2th & RR(:,fb)>r2th);
            
            subplot(6,6,d); hold on;
            dRR = RR(s,fb)-RR(s,ref);
            h = histogram(dRR,-100:1:100,'FaceColor','k','FaceAlpha',1);
            YY = get(gca,'ylim');
            plot([0 0],YY,'Color',[0.5 0.5 0.5],'LineWidth',2)
            plot([mean(dRR) mean(dRR)],YY,'r','LineWidth',2)
            plot([median(dRR) median(dRR)],YY,'b','LineWidth',2)
            set(gca,'xlim',[-100 100])
            xlabel(['dRR ' model],'interpreter','none');
            ylabel('cnt','interpreter','none');
            title(['R2 ' LAB{(fb)} '-' LAB{(ref)} ],...
                'interpreter','none')
            
            if ref ==1 && fb ==1
                legend({'HIST','0','MEAN','MEDIAN'});
            end
            
        end
    end
    saveas(f8,fullfile(figfld, ['EPHYS_MUA_R2diff_' ephys_MOD{m} '.png']));  
end

%% pRF size for different ephys signals ===================================
% SZ is [ MUA_R2(1) MUA_RFS(2) 
%         THETA_R2(3) THETA_RFS(4) 
%         ALPHA_R2(5) ALPHA_RFS(6) 
%         BETA_R2(7) BETA_RFS8) 
%         LGAM_R2(9) LG_RFS(10) 
%         HGAM_R2(11) HGAM_RFS(12)]
r2th=20;

ephys_MOD={'linear_ephys_cv1','linear_ephys_cv1_neggain',...
    'css_ephys_cv1','dog_ephys_cv1'};
ephys_MMS = MMS(:,1);

for m=1:length(ephys_MOD)
    model=ephys_MOD{m};
    LAB=['MUA';sig(lfp_order)];
    
    f10=figure; set(f10,'Position',[100 100 1300 1200]);
    sgtitle(['SZ per Model: ' model],'interpreter','none');
    
    c=0;d=0;
    for ref=1:2:12
        c=c+1;
        SS(c).nSZ =[];
        for fb=1:2:12
            d=d+1;
            s=(SZ{m}(:,ref)>r2th & SZ{m}(:,fb)>r2th);
            
            subplot(6,6,d); hold on; plot([0 100],[0 100],'k');
            
            scatter(SZ{m}(s,ref+1),SZ{m}(s,fb+1),120,[0.3 0.3 0.3],'Marker','.')
            xlabel(LAB{(ref+1)/2});ylabel(LAB{(fb+1)/2});
            title(['pRF size ' model(1:3)],'interpreter','none')
            
            set(gca,'xlim',[0 10],'ylim',[0 10]);
            
            SS(c).nSZ = [SS(c).nSZ ; ...
                median(diff(SZ{m}(s,[ref+1 fb+1]),1,2)) ...
                std(diff(SZ{m}(s,[ref+1 fb+1]),1,2))./sqrt(sum(s)) ...
                median(  SZ{m}(s,fb+1)./SZ{m}(s,ref+1) ) ...
                std(  SZ{m}(s,fb+1)./SZ{m}(s,ref+1) )./sqrt(sum(s))];
        end
    end
    saveas(f10,fullfile(figfld, ['EPHYS_MUA_SZ_' ephys_MOD{m} '.png']));  

    % Distance from diagonal ==============================================
    
    f11=figure; set(f11,'Position',[100 100 1300 1200]);
    sgtitle(['SZ DIFF per Model: ' model],'interpreter','none');
    
    c=0;d=0;
    for ref=1:2:12
        c=c+1;
        SS(c).nSZ =[];
        for fb=1:2:12
            d=d+1;
            s=(SZ{m}(:,ref)>r2th & SZ{m}(:,fb)>r2th);
            
            subplot(6,6,d); hold on;
            dSz = SZ{m}(s,fb+1)-SZ{m}(s,ref+1);
            h = histogram(dSz,-5:0.1:5,'FaceColor','k','FaceAlpha',1);
            YY = get(gca,'ylim');
            plot([0 0],YY,'Color',[0.5 0.5 0.5],'LineWidth',2)
            plot([mean(dSz) mean(dSz)],YY,'r','LineWidth',2)
            plot([median(dSz) median(dSz)],YY,'b','LineWidth',2)
            set(gca,'xlim',[-6 6])
            xlabel(['Sz Diff - ' model(1:3)],'interpreter','none');
            ylabel('cnt','interpreter','none');
            title(['Size ' LAB{(fb+1)/2} '-' LAB{(ref+1)/2} ],...
                'interpreter','none')
            
            if ref ==1 && fb ==1
                legend({'HIST','0','MEAN','MEDIAN'});
            end
            
        end
    end
    saveas(f11,fullfile(figfld, ['EPHYS_MUA_SZdiff_' ephys_MOD{m} '.png']));  

end

%% Correlate MRI-ephys ====================================================
% This analysis takes a while!! Do not overuse...
rng(1); % seed the random number generator

Rth_mri = 2; % R2 threshold MRI
Rth_ephys = 30; % R2 threshold ephys
mxS = 20; % maximum size

MODS = {...
    'linhrf_cv1_mhrf','linear_ephys_cv1';...
    'linhrf_cv1_mhrf_neggain','linear_ephys_cv1_neggain';...
    'csshrf_cv1_mhrf','css_ephys_cv1';...
    'doghrf_cv1_mhrf','dog_ephys_cv1';...
    };
MRI_MODEL = MODS(:,1);
EPHYS_MODEL = MODS(:,2);
MMS={'linear','linear_ng','css','dog'};

nbtstr = 100;
np = 500;
grid_vf = [ 0 5 -5 1 ; 0 8 -8 0]; % [xmin xmax ymin ymax] [v1; v4] dva
grid_spacing = 0.25;% dva
pth = 0.10;
poscorr_only = false;

warning off;

cmROI = {'V1','V4'};
fprintf('=======================\n');
for m = 1:length(MODS)
    fprintf(['\nBootstrap Correlation for Model: ' MODS{m} '\n']);
    
    s_R2 = T(modidx.(MRI_MODEL{m})).mod.R2 > Rth_mri & ...
         T(modidx.(MRI_MODEL{m})).mod.rfs < mxS;
    
    % collect mri prfs
    for r = 1:size(cmROI,2)
        SSS = s_R2 & ismember( T(modidx.(MRI_MODELS{m})).mod.ROI,...
                ck_GetROIidx(cmROI(r),rois) );
        if strcmp(cmROI{r},'V1') % V1
            mri1(m).X = T(modidx.(MRI_MODEL{m})).mod.X(SSS);
            mri1(m).Y = T(modidx.(MRI_MODEL{m})).mod.Y(SSS);
            if strcmp(MRI_MODEL{m}(1:3),'dog')
                mri1(m).S = T(modidx.(MRI_MODEL{m})).mod.rfs(SSS);
            else
                mri1(m).S = T(modidx.(MRI_MODEL{m})).mod.rfs(SSS);
            end
        elseif strcmp(cmROI{r},'V4') % V4
            mri4(m).X = T(modidx.(MRI_MODEL{m})).mod.X(SSS);
            mri4(m).Y = T(modidx.(MRI_MODEL{m})).mod.Y(SSS);
            mri4(m).S = T(modidx.(MRI_MODEL{m})).mod.rfs(SSS);
        end
    end
               
    % collect ephys prfs
    % MUA V1
    s = strcmp(tMUA.Model,EPHYS_MODEL{m}) & ...
        tMUA.Area == 1 & tMUA.R2 > Rth_ephys & tMUA.rfs < mxS;
    mua1(m).X = tMUA.X(s); 
    mua1(m).Y = tMUA.Y(s); 
    mua1(m).S = tMUA.rfs(s);
    % MUA V4
    s = strcmp(tMUA.Model,EPHYS_MODEL{m}) & ...
        tMUA.Area == 4 & tMUA.R2 > Rth_ephys & tMUA.rfs < mxS;
    mua4(m).X = tMUA.X(s); 
    mua4(m).Y = tMUA.Y(s); 
    mua4(m).S = tMUA.rfs(s);  
    % LFP
    freqband=unique(tLFP.SigType);
    for fb = 1: length(freqband)
        % V1
        s = strcmp(tLFP.Model,EPHYS_MODEL{m}) & ...
            tLFP.Area == 1 & tLFP.R2 > Rth_ephys & tLFP.rfs < mxS & ...
            strcmp(tLFP.SigType, freqband{fb});
        lfp1(fb,m).freqband =  freqband{fb};
        lfp1(fb,m).X =  tLFP.X(s);
        lfp1(fb,m).Y =  tLFP.Y(s);
        lfp1(fb,m).S =  tLFP.rfs(s);
        
        % V4
        s = strcmp(tLFP.Model,EPHYS_MODEL{m}) & ...
            tLFP.Area == 4 & tLFP.R2 > Rth_ephys & tLFP.rfs < mxS & ...
            strcmp(tLFP.SigType, freqband{fb});
        lfp4(fb,m).freqband =  freqband{fb};
        lfp4(fb,m).X =  tLFP.X(s);
        lfp4(fb,m).Y =  tLFP.Y(s);
        lfp4(fb,m).S =  tLFP.rfs(s);
    end
   
    % Calculate  grids and do bootstrap correlation
    % =============================================
    % create XY-grid
    [x1q,y1q] = meshgrid(...
        grid_vf(1,1):grid_spacing:grid_vf(1,2),...
        grid_vf(1,3):grid_spacing:grid_vf(1,4));
    [x4q,y4q] = meshgrid(...
        grid_vf(2,1):grid_spacing:grid_vf(2,2),...
        grid_vf(2,3):grid_spacing:grid_vf(2,4));
    
    mri1(m).S_grid = griddata(mri1(m).X,mri1(m).Y,mri1(m).S,x1q,y1q,'linear');
    mri4(m).S_grid = griddata(mri4(m).X,mri4(m).Y,mri4(m).S,x4q,y4q,'linear');
    mua1(m).S_grid = griddata(mua1(m).X,mua1(m).Y,mua1(m).S,x1q,y1q,'linear');
    mua4(m).S_grid = griddata(mua4(m).X,mua4(m).Y,mua4(m).S,x4q,y4q,'linear');
    for fb = 1: length(freqband)
        lfp1(fb,m).S_grid = griddata(...
            lfp1(fb,m).X,lfp1(fb,m).Y,lfp1(fb,m).S,x1q,y1q,'linear');
        lfp4(fb,m).S_grid = griddata(...
            lfp4(fb,m).X,lfp4(fb,m).Y,lfp4(fb,m).S,x4q,y4q,'linear');
    end
    
    if false % true
        figure;
        subplot(2,2,1); hold on;
        contourf(x1q,y1q,mri1(m).S_grid,'LevelStep',0.1,'LineStyle','none');
        plot(x1q,y1q,'k.')
        
        subplot(2,2,2);hold on;
        contourf(x1q,y1q,mua1(m).S_grid,'LevelStep',0.1,'LineStyle','none');
        plot(x1q,y1q,'k.')
        
        subplot(2,2,3);hold on;
        contourf(x4q,y4q,mri4(m).S_grid,'LevelStep',0.1,'LineStyle','none');
        plot(x4q,y4q,'k.')
        
        subplot(2,2,4);hold on;
        contourf(x4q,y4q,mua4(m).S_grid,'LevelStep',0.1,'LineStyle','none');
        plot(x4q,y4q,'k.')
    end
        
    % bootstrap the correlation analysis
    fprintf('Performing a bootstrapped correlation analysis\n')
    v1 = find(~isnan(mri1(m).S_grid));
    v4 = find(~isnan(mri4(m).S_grid));
    cc1=[]; cc4=[];
    pp1=[]; pp4=[];
    
    fprintf(['nBtstr: ' num2str(nbtstr) ', nSamples: ' num2str(np) '\n'])
    plotscatter=false;
    if plotscatter; figure; end % plotting all here, selecting later
    for i=1:nbtstr
        % --- V1 ---
        c1=[];p1=[];
        V=v1(randperm(length(v1)));
        selS = [mri1(m).S_grid(:) mua1(m).S_grid(:)];
        selS = selS(V(1:np),:);
        selS = selS(~isnan(selS(:,2)),:);
        [r,p]=corrcoef(selS(:,1), selS(:,2));
        if plotscatter
            subplot(2,6,1); hold on;
            scatter(mri1(m).S_grid(V(1:np)), mua1(m).S_grid(V(1:np)),'o');
            title('V1 Map corr.');xlabel('MRI');ylabel('MUA');
        end
        c1=[c1 r(2)]; p1=[p1 p(2)];
        
        for fb=1:length(freqband)
            try
                selS = [mri1(m).S_grid(:) lfp1(fb,m).S_grid(:)];
                selS = selS(V(1:np),:);
                selS = selS(~isnan(selS(:,2)),:);
                [r,p]=corrcoef(selS(:,1), selS(:,2));
                if plotscatter
                    subplot(2,6,1+fb);hold on;
                    scatter(mri1(m).S_grid(V(1:np)), lfp1(fb,m).S_grid(V(1:np)),'o');
                end
            catch
                r=NaN(2,2);
            end
            if plotscatter
                subplot(2,6,1+fb);
                title('V1 Map corr.');xlabel('MRI');ylabel(lfp1(fb,m).freqband);
            end
            c1=[c1 r(2)]; p1=[p1 p(2)];
        end
        cc1=[cc1; c1]; pp1=[pp1; p1];
        stats(m).cc1 = cc1; stats(m).pp1 = pp1;
        
        % --- V4 ----
        c4=[];p4=[];
        V=v4(randperm(length(v4)));
        
        selS = [mri4(m).S_grid(:) mua4(m).S_grid(:)];
        selS = selS(V(1:np),:);
        selS = selS(~isnan(selS(:,2)),:);
        [r,p]=corrcoef(selS(:,1), selS(:,2));
        if plotscatter
            subplot(2,6,7);hold on;
            scatter(mri4(m).S_grid(V(1:np)), mua4(m).S_grid(V(1:np)),'o');
            title('V4 Map corr.');xlabel('MRI');ylabel('MUA');
        end
        c4=[c4 r(2)]; p4=[p4 p(2)];
        
        for fb=1:length(freqband)
            try
                selS = [mri4(m).S_grid(:) lfp4(fb,m).S_grid(:)];
                selS = selS(V(1:np),:);
                selS = selS(~isnan(selS(:,2)),:);
                [r,p]=corrcoef(selS(:,1), selS(:,2));
                if plotscatter
                    subplot(2,6,7+fb);hold on;
                    scatter(mri4(m).S_grid(V(1:np)), lfp4(fb,m).S_grid(V(1:np)),'o');
                end
            catch
                r=NaN(2,2);
            end
            if plotscatter
                subplot(2,6,7+fb);
                title('V4 Map corr.');xlabel('MRI');ylabel(lfp1(fb,m).freqband);
            end
            c4=[c4 r(2)]; p4=[p4 p(2)];
        end
        cc4=[cc4; c4]; pp4=[pp4; p4];
        stats(m).cc4 = cc4; stats(m).pp4 = pp4;
    end
    
    stats(m).c1filt=stats(m).cc1; stats(m).c4filt=stats(m).cc4;
    if poscorr_only
        stats(m).c1filt(stats(m).pp1>pth | stats(m).cc1<0)=NaN;
        stats(m).c4filt(stats(m).pp4>pth | stats(m).cc4<0)=NaN;
    else
        stats(m).c1filt(stats(m).pp1>pth)=NaN;
        stats(m).c4filt(stats(m).pp4>pth)=NaN;
    end
    stats(m).cc1_stat = [nanmean(stats(m).c1filt,1); nanstd(stats(m).c1filt,0,1)];
    stats(m).cc4_stat = [nanmean(stats(m).c4filt,1); nanstd(stats(m).c4filt,0,1)];
    
    % plot average and stdev
    f14=figure; hold on;
    hBar = bar(1:6, [stats(m).cc1_stat(1,:);stats(m).cc4_stat(1,:)]);pause(0.1)
    xBar=cell2mat(get(hBar,'XData')).' + [hBar.XOffset];
    errorbar(xBar, [stats(m).cc1_stat(1,:);stats(m).cc4_stat(1,:)]',...
        [stats(m).cc1_stat(2,:);stats(m).cc4_stat(2,:)]','k','LineStyle','none')
    GroupLabels = {'MUA',...
        lfp1(1,m).freqband,...
        lfp1(2,m).freqband,...
        lfp1(3,m).freqband,...
        lfp1(4,m).freqband,...
        lfp1(5,m).freqband};
    set(gca,'xtick',1:6,'xticklabels',GroupLabels);
    legend({'V1','V4'},'Location','NorthWest');
    title(...
        {['pRF model: ' MMS{m}],...
        ['nPoints: ' num2str(np) ', nBtstr: ' num2str(nbtstr) ...
        ', p < ' num2str(pth) ],[' R2th-mri: '  num2str(Rth_mri) ...
        ', R2th-ephys: ' num2str(Rth_ephys)]})
    
    saveas(f14,fullfile(figfld, ['MRI-EPHYS_' ephys_MOD{m} '.png']));  

    % Stats ---
    if false
        % V1
        [stats(m).p1,stats(m).t1,stats(m).s1] = ...
            anova1(stats(m).c1filt,GroupLabels);
        [stats(m).comp1, stats(m).means1, stats(m).h1, stats(m).names1] = ...
            multcompare(stats(m).s1);
        % V4
        [stats(m).p4,stats(m).t4,stats(m).s4] = ...
            anova1(stats(m).c4filt,GroupLabels);
        [stats(m).comp4, stats(m).means4, stats(m).h4, stats(m).names4] = ...
            multcompare(stats(m).s4);
    end
end
warning on;

%% What's specific about the good DoG fits ================================
% - find these channels/voxels
% - plot their location
% - plot their size
% - plot their prf profile



