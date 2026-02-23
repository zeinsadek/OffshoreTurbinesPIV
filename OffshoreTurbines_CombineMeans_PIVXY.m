%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
clc;
recording_name = 'FWF_I_PL4_AK12_LM33';

% Save paths
combined_save_path = 'H:\Offshore\cropped\combined';
paths = savepaths('H:\Offshore', recording_name);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD BOTH RECORDINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
recordings = {'A', 'B'};

for r = 1:length(recordings)

    % Load data for each measurement
    recording  = recordings{r};
    experiment = strcat(recording_name, '_', recording);
    disp(experiment)
    tmp = matfile(fullfile('H:\Offshore\cropped\final', strcat(experiment, '_FINAL_CROPPED.mat')));

    % Add to structure
    fprintf('Loading data...\n')
    data(r).U = tmp.U;
    data(r).V = tmp.V;
    data(r).W = tmp.W;
    data(r).X = tmp.X;
    data(r).Y = tmp.Y;
    data(r).waves = tmp.waves;
    fprintf('\n')
end

clear r experiment recording tmp recordings
clc; fprintf('Done loading data!\n\n')


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMBINE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Write to a matfile
clc; fprintf('Writing to matfile..\n')
combined = matfile(fullfile(combined_save_path, strcat(recording_name, '_COMBINED.mat')), 'Writable', true);

% Combine A + B recordings
combined.U = cat(3, data(:).U);
combined.V = cat(3, data(:).V);
combined.W = cat(3, data(:).W);
combined.X = data(1).X;
combined.Y = data(1).Y;
combined.D = length(combined.U);
combined.waves = cat(1, data(:).waves);

fprintf('Done writing to matfile!\n\n')
fprintf('Number of frames: %4.0f\n', combined.D);
fprintf('Number of Waves: %4.0f\n\n', length(combined.waves))

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE MEANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clc;
% if exist(paths.means, 'file')
%      fprintf('* Loading MEANS from File\n')
%      means = load(paths.means); 
%      means = means.output;
% else
%      means = data2meansPIVXY(combined, paths.means);
% end

clc;
means = data2meansPIVXY(combined, paths.means);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT MEANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X = means.X;
Y = means.Y;
U = means.u;
V = means.v;
W = means.w;

uu = means.uu;
vv = means.vv;
ww = means.ww;

uv = means.uv;
uw = means.uw;
vw = means.vw;

%% Means Plots

ax = figure();
t  = tiledlayout(1,3);
sgtitle(recording_name, 'interpreter', 'none')

nexttile()
colormap jet
contourf(X, Y, U, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('u')

nexttile()
colormap jet
contourf(X, Y, V, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('v')

nexttile()
colormap jet
contourf(X, Y, W, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('w')

%% Stresses Plots

ax = figure();
t  = tiledlayout(2,3);
sgtitle(recording_name, 'interpreter', 'none')

% Normal Stresses
nexttile()
colormap jet
contourf(X, Y, uu, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('uu')

nexttile()
colormap jet
contourf(X, Y, vv, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('vv')

nexttile()
colormap jet
contourf(X, Y, ww, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('ww')


% Shear Stresses
nexttile()
colormap jet
contourf(X, Y, uv, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('uv')

nexttile()
colormap jet
contourf(X, Y, uw, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('uw')

nexttile()
colormap jet
contourf(X, Y, vw, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
% ylim([-100,100])
colorbar()
title('vw')




