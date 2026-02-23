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

% Import waves
wave_path = "C:\Users\ofercak\Desktop\Zein\Results\waves\FBT_PL2_AK12_LM50_A_WAVES.mat";
waves = load(wave_path);
waves = waves.output;

% Import cropped data
crop_path = "C:\Users\ofercak\Desktop\Zein\Results\cropped\FBT_PL2_AK12_LM50_A_CROPPED.mat";
% crop = load(crop_path);
% crop = crop.output;
crop = matfile(crop_path);

%%

X = crop.X;
Y = crop.Y;
%%

D = 150;

figure()
contourf(X / D, (Y - 17) / D, crop.U(:,:,1), 100, 'linestyle', 'none')
circle(0,0,0.5);
axis equal
colorbar()
% clim([1,4])


%% Plot all waves

% 'High-Res' waves
figure()
hold on
for i = 1:waves.D
    plot(waves.x, waves.wave_profiles(i,:))
end
hold off
axis equal
xlim([-100, 100])

% 'PIV-Res' waves
figure()
hold on
for i = 1:waves.D
    plot(crop.X(1,:), crop.waves(i,:))
end
hold off
axis equal
xlim([-100, 100])

clear i

%% Try to find bad waves by looking at mean

avg_wave_profiles = mean(crop.waves, 2) + 100;

bad_waves_idxs = isnan(avg_wave_profiles) | abs(avg_wave_profiles) > 15;
bad_waves_frames = find(bad_waves_idxs);
bad_waves_avg = avg_wave_profiles(bad_waves_idxs);

% sort bad frames into nan-frames and not
bad_nan_waves_frames = bad_waves_frames(isnan(bad_waves_avg));
bad_not_nan_waves_frames = bad_waves_frames(~isnan(bad_waves_avg));

% figure()
% plot(1:1400, avg_wave_profiles)

%%
figure()
hold on
for i = 1:length(bad_waves_frames)
    plot(waves.x, waves.wave_profiles(bad_waves_frames(i),:))
end
hold off


%%

for i = 1:length(bad_waves_frames)
    idx = bad_waves_frames(i);
    figure()
    hold on
    contourf(crop.X / D, (crop.Y - 17) / D, crop.U(:,:,idx), 100, 'linestyle', 'none')
    plot(crop.X / D, crop.waves(idx,:) / D);
    hold off
    circle(0,0,0.5);
    axis equal
    clim([-1,4.5])
    title(idx)
end


%% Functions

function h = circle(x,y,r)
    hold on
    th = 0:pi/50:2*pi;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    h = plot(xunit, yunit);
    hold off
end








