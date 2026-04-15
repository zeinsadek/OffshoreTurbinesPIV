%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\sadek\Desktop\readimx-v2.1.9-win64');
addpath('C:\Users\sadek\Desktop\ZeinPIVCodes_Github\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
addpath('C:\Program Files\MATLAB\slanCM')
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
clc;
project_path   = 'E:\FixedBottomFarm\FBF_Inline_PL1_AK12';
recording_name = 'FBF_I_PL1_AK12_LM33_A';
details        = namereader(recording_name);

% Image paths
% perspective_path = fullfile(project_path, recording_name, 'ImageCorrection');
perspective_path = fullfile(project_path, recording_name, 'CompressAvg_4x4');
piv_path         = fullfile(project_path, recording_name, 'StereoPIV_MPd(1x32x32_50%ov)');

% Save paths
save_path = 'E:\FixedBottomFarm_Results';
paths     = savepaths(save_path, recording_name);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND ALL AVAILABLE FRAMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
frames = commonframes(piv_path, perspective_path, paths.frame);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WAVE DETECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.wave.initial, 'file')
    fprintf('* Loading INITIAL WAVES from File\n')
    waves = load(paths.wave.initial);
    waves = waves.output;
else
    tic
    waves = wavedetectionPIVXY(frames, perspective_path, details, paths.wave.initial);
    toc
end

%% Check Waves

% Plot
figure()
hold on
for i = 1:5:waves.D
    plot(waves.x, waves.wave_profiles(i,:))
    clear i
end
hold off
axis equal
xlim([-100, 100])


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE FILES THAT HAVE BEEN SKIPPED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Re-run the original commonframes() function so that if the
% udatecommonframes() function gets run multiple times it wont delete
% additional images

clc;
frames = commonframes(piv_path, perspective_path, paths.frame);
frames = updatecommonframes(frames, waves, paths.frame, 'RAW');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DAVIS TO MATLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.data, 'file')
    fprintf('* Loading DATA from File\n')
    data = matfile(paths.data);
else
    tic
    data = vector2matlabPIVXY(frames, piv_path, waves, paths.data);
    toc
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE FILES THAT HAVE BEEN SKIPPED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf('<Counting Existing Frames>\n\n')
frames = commonframes(piv_path, perspective_path, paths.frame);
fprintf('\n<Counting Corrupted RAW Frames>\n')
frames = updatecommonframes(frames, waves, paths.frame, 'RAW');
fprintf('\n<Counting Corrupted PIV Frames>\n')
frames = updatecommonframes(frames, data, paths.frame, 'PIV');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROP INSTANTANEOUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Will only crop the left and right of the images here. Will seperate out
% which waves need to be fixed and then crop below all the waves after all
% the profiles have been fixed.

clc;
if exist(paths.crop.initial, 'file')
    fprintf('* Loading INITIAL CROP from File\n')
    crop = load(paths.crop.initial);
else
    tic
    crop = croppingPIVXY(data, details, paths.crop.initial);
    toc
end

%% check

f = 100;
figure()
hold on
contourf(crop.X, crop.Y, crop.U(:, :, f), 100, 'linestyle', 'none')
plot(crop.X(1,:), crop.waves(f,:), 'color', 'black')
hold off
axis equal
colorbar()
% clim([-1, 1])
% xline(60)
clear f

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IDENTIFY POORLY DETECTED WAVES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PIV waves
low_res_waves = crop.waves;

% test different criteria for catching bad waves
lin_count = 0;
nan_count = 0;
spike_count = 0;
refine_count = 1;
clear wave_correction

% Parameters
% This is the largest allowable jump between two consecutive points along
% the wave
settings.spike_threshold = 1.0;

% This is the allowable slope slope for the first/last N points of the wave
settings.N = 50;
settings.slope_threshold = 0.08;

% This smooths the final wave
settings.wave_smoothing_kernel = 3;


% Plot
close all; clc;
figure('color', 'white')
tiledlayout(2,1)
nexttile()
title('Waves to be refined')
hold on
for i = 1:length(low_res_waves)

    % Ignore cropped region of Plane 1 Floating
    if details.plane == 1
        % Floating
        if contains(details.arrangement, 'Floating') == 1
            cutoff = -20;
        end

        % Fixed-Bottom
        if contains(details.arrangement, 'Fixed') == 1
            cutoff = -80;
        end

    % Ignore cropped region of Plane 4 Floating
    elseif details.plane == 4
        if contains(details.arrangement, 'Floating') == 1
            cutoff = 50;
        end
    else
        cutoff = -100;
    end

    % Try to clean up blank spots in wave
    x = crop.X(1,:);
    [~, cutoff_index] = min(abs(x - cutoff));

    % Planes 1, 2, 3
    if ismember(details.plane, [1,2,3])
        % Load wave
        wave = low_res_waves(i, cutoff_index:end);
        x = x(cutoff_index:end);

    % Plane 4
    else 
        % Load wave
        wave = low_res_waves(i, 1:cutoff_index - 1);
        x = x(1:cutoff_index - 1);
    end


    % Fit linear models to ends of profile
    left_slope = polyfit(x(1:settings.N), wave(1:settings.N), 1);
    right_slope = polyfit(x(end - settings.N+1:end), wave(end - settings.N+1:end), 1);

 
    % Check if there are nans
    if isnan(sum(wave))
        color = 'red';
        alpha = 1.0;
        nan_count = nan_count + 1;
        wave_correction(refine_count) = i;
        refine_count = refine_count + 1;

    % Check if the ends start to wander
    elseif abs(left_slope(1)) > settings.slope_threshold || abs(right_slope(1)) > settings.slope_threshold
        color = 'green';
        alpha = 1.0;
        lin_count = lin_count + 1;
        wave_correction(refine_count) = i;
        refine_count = refine_count + 1;

    %%% Try to only make this trigger if a case with waves is being
    %%% processed
    % Check if there are big spikes
    elseif any(abs(diff(wave)) > settings.spike_threshold)
        color = 'blue';
        alpha = 1.0;
        spike_count = spike_count + 1;
        wave_correction(refine_count) = i;
        refine_count = refine_count + 1;


    % Wave passes
    else
        color = 'black';
        alpha = 0.05;
    end

    P = plot(x, wave, 'color', color);
    P.Color(4) = alpha;
end
hold off
axis equal
xlim([-100, 100])
ylim([-120, -80])

% Plot the waves that passed check
% Easier to see
nexttile()
title('Passing Waves')
hold on
for i = 1:length(low_res_waves)
    if ~ismember(i, wave_correction)
        P = plot(crop.X(1,:), low_res_waves(i,:), 'color', 'black', 'linewidth', 0.5);
        P.Color(4) = 0.25;
    end
end
hold off
axis equal
xlim([-100, 100])
ylim([-120, -80])


fprintf("<waverefinement> %3.0f waves detected for having nans\n", nan_count)
fprintf("<waverefinement> %3.0f waves detected for having sloped ends\n", lin_count)
fprintf("<waverefinement> %3.0f waves detected for having big spikes\n", spike_count)
fprintf("<waverefinement> %3.0f bad waves detected out of %4.0f (%2.0f%% of all waves)\n\n", refine_count - 1, length(low_res_waves), ((refine_count - 1) / length(low_res_waves)) * 100)

% In case no waves need to be fixed
if refine_count == 1
    fprintf("<waverefinement> No waves need to be refined!\n")
    wave_correction = nan;
end

clear k i x lin_count nan_count refine_count t axs wave left_slope right_slope idx color 
clear spike_count spike_threshold tit N slope_threshold P alpha cutoff cutoff_index

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REFINE POORLY DETECTED WAVES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clc;
% tic
% refined = refinedwavedetectionPIVXY(perspective_path, details, crop, wave_correction, settings, frames, paths.wave.refined);
% toc

clc;
if exist(paths.wave.refined, 'file')
     fprintf('* Loading REFINED WAVES from File\n')
     refined = load(paths.wave.refined);
else
     refined = refinedwavedetectionPIVXY(perspective_path, details, crop, wave_correction, settings, frames, paths.wave.refined);
end

figure()
hold on
for i = 1:length(refined.waves)
    plot(crop.X(1,:), refined.waves(i,:))
    clear i 
end
hold off
axis equal
xlim([-100, 100])
ylim([-120, -80])

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RE-REFINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make a copy of the refined_waves
rerefined_waves = refined.waves;

% No waves
% grad_threshold = 0.15;
% grad_threshold = 0.0001;

% Waves
% grad_threshold = 0.22;
grad_threshold = 0.5;

% Fill method
method = 'nearest';

clc;
figure()
tiledlayout(2,1)

nexttile
hold on
for i = 1:length(rerefined_waves)
    
    % Ignore cropped region of Plane 1 Floating
    if details.plane == 1
        % Floating
        if contains(details.arrangement, 'Floating') == 1
            cutoff = -20;
        end

        % Fixed-Bottom
        if contains(details.arrangement, 'Fixed') == 1
            cutoff = -80;
        end

    % Ignore cropped region of Plane 4 Floating
    elseif details.plane == 4
        if contains(details.arrangement, 'Floating') == 1
            cutoff = 50;
        end
    else
        cutoff = -100;
    end

    % Try to clean up blank spots in wave
    x = crop.X(1,:);
    [~, cutoff_index] = min(abs(x - cutoff));

    % Planes 1, 2, 3
    if ismember(details.plane, [1,2,3])
        % Load wave
        ref_wave = rerefined_waves(i, cutoff_index:end);
        x = x(cutoff_index:end);

    % Plane 4
    else 
        % Load wave
        ref_wave = rerefined_waves(i, 1:cutoff_index);
        x = x(1:cutoff_index);
    end


    % Check gradient for spikes
    if any(abs(gradient(ref_wave, x)) > grad_threshold) 
        disp(i)

        masked_ref_wave = ref_wave;

        % Brute force
        % masked_ref_wave(masked_ref_wave < -100) = nan;

        % Gradient detection
        mask = abs(gradient(ref_wave, x)) > grad_threshold;
        masked_ref_wave(mask) = nan;

        % Fill in
        plot(x, ref_wave, 'color', 'black')
        plot(x, fillmissing(masked_ref_wave, method), 'color', 'red')

        % Save profiles back into refined_waves
        if ismember(details.plane, [1,2,3])
            rerefined_waves(i, cutoff_index:end) = fillmissing(masked_ref_wave, method);
        else
            rerefined_waves(i, 1:cutoff_index) = fillmissing(masked_ref_wave, method);
        end
    end
end


hold off
axis equal
xlim([-100, 100])
title('Re-refined Waves')

nexttile
clc;
hold on
for i = 1:length(refined.waves)
    plot(crop.X(1,:), rerefined_waves(i,:))
end
hold off
axis equal
xlim([-100, 100])
title('All re-refined waves')


clear i x cutoff grad_threshold cutoff_index mask masked_ref_wave mins ref_wave spike_count spike_threshold wave_correction

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE A MOVIE OF THE WAVE PROFILES TO CHECK THEM ALL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Saving at 15 FPS to make playback smoother
clc;
FPS = 15;
tic
waveprofilemoviePIVXY(rerefined_waves, crop.X(1,:), frames, paths.wave.rerefined, FPS)
toc
clear FPS


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROP BELOW WAVE AND SAVE TO CROPPED/FINAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Final, fully nan waves are are noted and skipped here
clc;
tic
wavecrop = wavecropPIVXY(crop, rerefined_waves, details, paths.crop.final);
toc

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UPDATE WHICH FRAMES ARE USED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf('<Counting Existing Frames>\n\n')
frames = commonframes(piv_path, perspective_path, paths.frame);
fprintf('\n<Counting Corrupted RAW Frames>\n')
frames = updatecommonframes(frames, waves, paths.frame, 'RAW');
fprintf('\n<Counting Corrupted PIV Frames>\n')
frames = updatecommonframes(frames, data, paths.frame, 'PIV');
fprintf('\n<Counting Misfired RAW Frames>\n')
frames = updatecommonframes(frames, wavecrop, paths.frame, 'RAW');

%% check that frames are cropped below the wave

f = 3;
levels = 100;

figure()
tiledlayout(1,3)
nexttile()
hold on
contourf(wavecrop.X, wavecrop.Y, wavecrop.U(:,:,f), levels, 'linestyle', 'none')
plot(wavecrop.X(1,:), wavecrop.waves(f,:), 'color', 'red', 'linewidth', 2)
colorbar()
clim([0, 4])
hold off
axis equal
title('U')

nexttile()
hold on
contourf(wavecrop.X, wavecrop.Y, wavecrop.V(:,:,f), levels, 'linestyle', 'none')
plot(wavecrop.X(1,:), wavecrop.waves(f,:), 'color', 'red', 'linewidth', 2)
colorbar()
clim([-1, 1])
hold off
axis equal
title('V')

nexttile()
hold on
contourf(wavecrop.X, wavecrop.Y, wavecrop.W(:,:,f), levels, 'linestyle', 'none')
plot(wavecrop.X(1,:), wavecrop.waves(f,:), 'color', 'red', 'linewidth', 2)
colorbar()
clim([-1, 1])
hold off
axis equal
title('W')

clear f levels

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATLAB DATA TO ENSEMBLE/PHASE MEANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% if exist(paths.means, 'file')
%      fprintf('* Loading MEANS from File\n')
%      means = load(paths.means); 
%      means = means.output;
% else
%      means = data2meansPIVXY(wavecrop, paths.means);
% end

means = data2meansPIVXY(wavecrop, paths.means);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTS
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

max_wave_profile = max(rerefined_waves, [], 1);
U(Y < max_wave_profile) = nan;
V(Y < max_wave_profile) = nan;
W(Y < max_wave_profile) = nan;

uu(Y < max_wave_profile) = nan;
vv(Y < max_wave_profile) = nan;
ww(Y < max_wave_profile) = nan;

uv(Y < max_wave_profile) = nan;
uw(Y < max_wave_profile) = nan;
vw(Y < max_wave_profile) = nan;

%% Means Plots

levels = 100;
ax = figure();
t  = tiledlayout(1,3);
sgtitle(recording_name, 'interpreter', 'none')

nexttile()
colormap jet
contourf(X, Y, U, levels, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('u')

nexttile()
colormap jet
contourf(X, Y, V, levels, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('v')

nexttile()
colormap jet
contourf(X, Y, W, levels, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('w')

clear levels

%% Test profiles of u

figure()
plot(U(:, 200), Y(:,1))
xlim([0, 4])

%% Mean u with al waves plotted on top

figure()
hold on
contourf(X, Y, U, 100, 'linestyle', 'none')
for f = 1:length(frames.common)
    plot(X(1,:), wavecrop.waves(f, :), 'color',  'black')
end
hold off
axis equal

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
colorbar()
title('uu')

nexttile()
colormap jet
contourf(X, Y, vv, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('vv')

nexttile()
colormap jet
contourf(X, Y, ww, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('ww')


% Shear Stresses
nexttile()
colormap jet
contourf(X, Y, uv, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('uv')

nexttile()
colormap jet
contourf(X, Y, uw, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('uw')

nexttile()
colormap jet
contourf(X, Y, vw, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
colorbar()
title('vw')





















