%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/OffshoreTurbines/OffshoreTurbines_Functions/');
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
clc;
project_path   = '/Volumes/ZeinResults/PIV/FBT_PL2_AK12_1';
recording_name = 'FBT_PL2_AK12_LM50_A';
details        = namereader(recording_name);

% Image paths
% perspective_path = fullfile(project_path, 'Perspective', strcat(recording_name, '_Perspective'));
perspective_path = fullfile(project_path, recording_name, 'ImageCorrection');
piv_path         = fullfile(project_path, recording_name, 'StereoPIV_MPd(2x12x12_50%ov)_GPU');

% Save paths 
save_path = '/Volumes/ZeinResults/CrossplaneResults';
paths     = savepaths(save_path, recording_name);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMMON FRAMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.frame, 'file')
     fprintf('* Loading FRAMES from File\n')
     frames = load(paths.frame);
     frames = frames.output;
else
     frames = commonframes(piv_path, perspective_path, paths.frame);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WAVE DETECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.wave, 'file')
     fprintf('* Loading WAVES from File\n')
     waves = load(paths.wave);
     waves = waves.output;
else
     waves = wavedetectionPIVYZ(frames, perspective_path, details, paths.wave);
end

%% Check Waves

% % Replace last nan value with previous value
% waves.wave_profiles(:,end) = waves.wave_profiles(:, end - 1);
% 
% % Plot
% figure()
% hold on
% for i = 1:5:waves.D
%     % Remove small bumps by filtering derivative
%     wave = waves.wave_profiles(i,:);
%     grad_wave = gradient(wave);
%     wave(grad_wave > 0.5) = nan;
%     wave(grad_wave < -0.5) = nan;
%     waves.wave_profiles(i,:) = wave;
%     plot(waves.x, wave)
% end
% xline(-20)
% hold off
% axis equal
% xlim([-100, 100])

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DAVIS TO MATLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.data, 'file')
    fprintf('* Loading DATA from File\n')
    data = matfile(paths.data);
    data = data.output;
else
    data = vector2matlabPIVXY(frames, piv_path, paths.data);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROP INSTANTANEOUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.crop, 'file')
    fprintf('* Loading CROP from File\n')
    crop = load(paths.crop);
    crop = crop.output;
else
    crop = croppingPIVXY(data, waves, details, paths.crop);
end

% OG CODE
% for frame = 1:data.D
% for frame = 1:5
% 
%     % Print Progress. 
%     progressbarText(frame/data.D);
% 
%     % Load frames
%     X = data.X;
%     Y = data.Y;
%     U = data.U(:,:,frame).';
%     V = data.V(:,:,frame).';
%     W = data.W(:,:,frame).';
% 
%     % Set ouside of calibration plate to NANs
%     U(X > 100 | X < -100) = nan;
%     V(X > 100 | X < -100) = nan;
%     W(X > 100 | X < -100) = nan;
% 
%     % Initial, uncropped x positions from DaVis
%     x = X(1,:);
% 
%     %%% LHS
%     % Find index of value closest to what we want to crop to
%     left_bound = -100;
%     [~, left_bound_idx] = min(abs(x - left_bound));
% 
%     % Truncate relavant portion of array
%     X(:, 1:left_bound_idx) = [];
%     Y(:, 1:left_bound_idx) = [];
%     U(:, 1:left_bound_idx) = [];
%     V(:, 1:left_bound_idx) = [];
%     W(:, 1:left_bound_idx) = [];
% 
%     %%% RHS
%     % Redefine x since it has been partially cropped
%     x = X(1,:);
%     % Find index of value closest to what we want to crop to
%     right_bound = 100;
%     [~, right_bound_idx] = min(abs(x - right_bound));
% 
%     % Truncate relavant portion of array
%     X(:, right_bound_idx:end) = [];
%     Y(:, right_bound_idx:end) = [];
%     U(:, right_bound_idx:end) = [];
%     V(:, right_bound_idx:end) = [];
%     W(:, right_bound_idx:end) = [];
% 
%     if frame == 1
%         size_PIV = size(X);
%         cropped.waves = nan(data.D, size_PIV(2));
%         cropped.U = nan(size_PIV(1), size_PIV(2), data.D);
%         cropped.V = nan(size_PIV(1), size_PIV(2), data.D);
%         cropped.W = nan(size_PIV(1), size_PIV(2), data.D);
%     end
% 
%     % Flip components to have flow be left to right
%     U = fliplr(U);
%     V = fliplr(V);
%     W = fliplr(W);
% 
%     % Crop below wave
%     nf = size(U);
%     resized_wave = imresize(waves.wave_profiles(frame,:),[1,nf(2)]);
% 
%     % Delete physically masked portion. Only for Plane 1
%     if details.plane == 1
%         if contains(details.arrangement, 'Floating') == 1
%             cutoff = -20;
%             U(X < cutoff) = nan;
%             V(X < cutoff) = nan;
%             W(X < cutoff) = nan;
%             resized_wave(unique(X) < cutoff) = nan;
%         end
%     end
% 
%     % Save Crops
%     cropped.waves(frame,:) = resized_wave;
%     cropped.X = X;
%     cropped.Y = Y;
%     cropped.U(:,:,frame) = U;
%     cropped.V(:,:,frame) = V;
%     cropped.W(:,:,frame) = W;
% 
%     % Clean up blank spots in wave
%     x = unique(X).';
%     [~, interp_idx] = min(abs(x - cutoff));
%     if sum(isnan(resized_wave(interp_idx:end))) < 100 
%         interp_x = x(interp_idx:end);
%         interp_wave = cropped.waves(frame,interp_idx:end);
%         interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
%         cropped.waves(frame, interp_idx:end) = interp_wave;
%     end
% 
%     U(Y < cropped.waves(frame,:)) = nan;
%     V(Y < cropped.waves(frame,:)) = nan;
%     W(Y < cropped.waves(frame,:)) = nan;
%     cropped.U(:,:,frame) = U;
%     cropped.V(:,:,frame) = V;
%     cropped.W(:,:,frame) = W;
% end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATLAB DATA TO ENSEMBLE/PHASE MEANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.means, 'file')
     fprintf('* Loading MEANS from File\n')
     means = load(paths.means); 
     means = means.output;
else
     means = data2meansPIVXY(crop, paths.means);
end

% frame = 500;
% 
% % Plot
% figure()
% hold on
% contourf(crop.X, crop.Y, crop.U(:,:,frame), 100, 'linestyle', 'none')
% plot(unique(crop.X), crop.waves(frame,:), 'linewidth', 3, 'color', 'blue')
% % xline(cutoff)
% hold off
% xlim([-100, 100])
% ylim([-150, 100])
% axis equal
% colorbar()
% clim([0, 2.5])
% Fixing Holes in Waves
% x = unique(cropped.X).';
% 
% [~, interp_idx] = min(abs(x - cutoff));
% interp_x = x(interp_idx:end);
% interp_wave = cropped.waves(12,interp_idx:end);
% interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
% cropped.waves(1,interp_idx:end) = interp_wave;
% 
% figure()
% hold on
% plot(interp_x, interp_wave)
% plot(x, cropped.waves(1,:) + 2)
% hold off
% xlim([-100, 100])
% xline(-20)
% % plot()
% Test Video
% v = VideoWriter('test2.avi');
% v.FrameRate = 3;
% open(v);
% 
% for k = 1:100
%    figure()
%    hold on
%    contourf(cropped.X, cropped.Y, cropped.U(:,:,k), 50, 'linestyle', 'none')
%    plot(unique(cropped.X), cropped.waves(k,:), 'linewidth', 3, 'color', 'blue')
%    hold off
%    xlim([-100, 100])
%    ylim([-150, 100])
%    axis equal
%    title(strcat('Frame ', num2str(k)))
%    colorbar()
%    clim([0, 2.5])
%    frame = getframe;
%    writeVideo(v,frame);
%    close all
% end
% close(v);

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





















