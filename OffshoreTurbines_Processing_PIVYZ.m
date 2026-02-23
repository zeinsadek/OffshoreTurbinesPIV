%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
% addpath('C:\Users\Zein\Desktop\PIV\Colormaps')
% addpath('C:\Users\ofercak\Desktop\Zein\PIV\Inpaint_nans');
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
clc;
project_path   = 'H:\PIV\FBT_PL2_AK12_2';
recording_name = 'FBT_PL2_AK12_LM25_A';
details        = namereader(recording_name);

% Image paths
% perspective_path = fullfile(project_path, 'Perspective', strcat(recording_name, '_Perspective'));
perspective_path = fullfile(project_path, recording_name, 'ImageCorrection');
piv_path         = fullfile(project_path, recording_name, 'StereoPIV_MPd(2x12x12_50%ov)_GPU');

% Save paths 
save_path = 'H:\CrossplaneResults';
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
     waves = wavedetectionPIVYZ(frames, perspective_path, paths.wave);
end

%% Check Waves

% % Replace last nan value with previous value
% waves.wave_profiles(:,end) = waves.wave_profiles(:, end - 1);
% 
% Plot
lw = 3;
figure()
hold on
for i = 1:10:waves.D
    plot(waves.x, waves.wave_profiles(i,:), 'linewidth', lw);
    % plot(waves.x, fillmissing(filloutliers(waves.wave_profiles(i,:), "linear"), "linear"), 'displayname', num2str(i), 'LineWidth', lw)
end
hold off
% legend()
axis equal
xlim([-100, 100])

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DAVIS TO MATLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.data, 'file')
    fprintf('* Loading DATA from File\n')
    data = matfile(paths.data);
else
    data = vector2matlabPIVYZ(frames, piv_path, paths.data);
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROP INSTANTANEOUS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.crop, 'file')
    fprintf('* Loading CROP from File\n')
    crop = matfile(paths.crop);
else
    crop = croppingPIVYZ(data, waves, paths.crop);
end

%%

% frame = 50;
% 
% u = crop.U(:,:,frame);
% v = crop.V(:,:,frame);
% w = crop.W(:,:,frame);
% wave = crop.waves(frame, :);
% 
% X = crop.X;
% Y = crop.Y;
% 
% figure()
% hold on
% contourf(X, Y, w, 100, 'linestyle', 'none');
% plot(X(1,:), wave, 'linewidth', 3)
% hold off
% axis equal
% colorbar()



%%

waves = crop.waves;

figure()
hold on
for i = 1:length(waves)
    plot(X(1,:), waves(i,:))
end
hold off

%%

figure()
plot(sum(waves, 2))


%%
u = crop.U;
v = crop.V;
w = crop.W;
X = crop.X;
Y = crop.Y;
x = X(1,:);

% means
% u_mean = mean(u(:,:,~isnan(sum(crop.waves, 2))), 3, 'omitnan');
% v_mean = mean(v(:,:,~isnan(sum(crop.waves, 2))), 3, 'omitnan');
% w_mean = mean(w(:,:,~isnan(sum(crop.waves, 2))), 3, 'omitnan');

logical_idx = abs(mean(waves + 100, 2)) < 20 | ~isnan(sum(waves, 2));
u_mean = mean(u(:,:,logical_idx), 3, "omitnan");


disp(sum(~isnan(sum(crop.waves, 2)), 'all'))
% u_mean = mean(u, 3, 'omitnan');

% idx = 89;
% snapshot = u(:,:,idx);
% snapshot(snapshot == 0) = nan;
% wave = crop.waves(idx,:);

% snapshot = inpaint_nans(double(snapshot));
% snapshot(Y < wave) = nan;

figure()
hold on
contourf(X, Y, u_mean, 300, 'linestyle', 'none')
% plot(x, wave, 'black', 'linewidth', 3)
hold off
axis equal
colormap parula
colorbar
% clim([-0.5, 0.5])
% clim([-1.5, 4.5])
xlim([-100, 100])
ylim([-150, 100])

%%

% u = data.U;
% v = data.V;
% w = data.W;
% 
% X = data.X;
% Y = data.Y;
% 
% x = crop.X(1,:);
% 
% idx = 5;
% snapshot = u(:,:,idx);
% snapshot(snapshot == 0) = nan;
% wave = crop.waves(idx,:);
% 
% figure()
% hold on
% contourf(X, Y, snapshot.', 300, 'linestyle', 'none')
% plot(x, wave, 'black', 'linewidth', 3)
% hold off
% axis equal
% colormap coolwarm
% clim([-1.5, 4.5])
% xlim([-100, 100])
% ylim([-150, 100])

%% Find frames with bad waves

badFrames = char(frames.common(isnan(sum(waves.wave_profiles, 2))));
badWaves = waves.wave_profiles((isnan(sum(waves.wave_profiles, 2))));


figure()
hold on
for i = 1:length(badWaves)
    plot(badWaves(i,:))
end
hold off

%% Remove snapshots with no waves


wave_mask = ~isnan(sum(waves.wave_profiles, 2));

tmp_U = crop.U;
tmp_V = crop.V;
tmp_W = crop.W;

crop.U = tmp_U(:,:,wave_mask);
crop.V = tmp_V(:,:,wave_mask);
crop.W = tmp_W(:,:,wave_mask);

U = mean(crop.U, 3, 'omitnan');

%%
figure()
contourf(crop.X, crop.Y, U, 100, 'linestyle', 'none')
axis equal
xlim([-100, 100])
clim([-1.5, 4])




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


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X = means.X;
Y = means.Y;
U = means.u;
V = means.v;
W = means.w;

% W(U == 0) = nan;
% V(U == 0) = nan;
% U(U == 0) = nan;

uu = means.uu;
vv = means.vv;
ww = means.ww;

uv = means.uv;
uw = means.uw;
vw = means.vw;

%% check if there are bad waves

wave_profiles = waves.wave_profiles(1:100,:);
sum(wave_profiles, 2)



%% Means Plots

ax = figure();
t  = tiledlayout(1,3);
sgtitle(recording_name, 'interpreter', 'none')

nexttile()
colormap jet
contourf(X, Y, U, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
clim([-1.5, 4.5])
% ylim([-100,100])
colorbar()
title('u')

nexttile()
colormap coolwarm
contourf(X, Y, V, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
clim([-0.5, 0.5])
% ylim([-100,100])
colorbar()
title('v')

nexttile()
colormap coolwarm
contourf(X, Y, W, 100, 'linestyle', 'none')
axis equal
xlim([-100,100])
clim([-0.5, 0.5])
% ylim([-100,100])
colorbar()
title('w')

%% Stresses Plots

uu(uu == 0) = nan;
vv(vv == 0) = nan;
ww(ww == 0) = nan;

uv(uv == 0) = nan;
uw(uw == 0) = nan;
vw(vw == 0) = nan;

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





















