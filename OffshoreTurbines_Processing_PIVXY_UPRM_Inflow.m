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
project_path   = 'E:\Offshore_Inflow\PIVXY\Inflow_PL1_PIVXY_No_Waves';
recording_name = 'Inflow_PL1_PIVXY_AK0_A';
% details        = namereader(recording_name);

% Image paths
% perspective_path = fullfile(project_path, recording_name, 'ImageCorrection');
piv_path         = fullfile(project_path, recording_name, 'StereoPIV_MPd(1x32x32_50%ov)_GPU');

% Save paths
save_path = 'E:\Offshore_Inflow\results';
paths     = savepaths(save_path, recording_name);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND ALL AVAILABLE FRAMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% frames = commonframes(piv_path, perspective_path, paths.frame);
% frames.common = 1:1400;
N = 1400;
frames.common = "B" + compose("%05d", 1:N);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DAVIS TO MATLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
if exist(paths.data, 'file')
    fprintf('* Loading DATA from File\n')
    data = matfile(paths.data);
else
    data = vector2matlabPIVXY_NoWaveCropping_UPRM(frames, piv_path, paths.data);
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATLAB DATA TO ENSEMBLE/PHASE MEANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
means = data2meansPIVXY_NoWaveCropping_UPRM(data, paths.means);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

X = means.X;
Y = means.Y + 100;

% U = fliplr(means.u.');
% V = fliplr(means.v.');
% W = fliplr(means.w.');
% 
% uu = fliplr(means.uu.');
% vv = fliplr(means.vv.');
% ww = fliplr(means.ww.');
% 
% uv = fliplr(means.uv.');
% uw = fliplr(means.uw.');
% vw = fliplr(means.vw.');

U = (means.u.');
V = (means.v.');
W = (means.w.');

uu = (means.uu.');
vv = (means.vv.');
ww = (means.ww.');

uv = (means.uv.');
uw = (means.uw.');
vw = (means.vw.');



max_wave_profile = 0;
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

u_inf = 4.2;
hub_height = 117;
diameter = 150;
labelFontSize = 14;

mean_u_profile = mean(U, 2, 'omitnan') / u_inf;
mean_Ti_profile = sqrt(mean(uu, 2, 'omitnan')) / u_inf;
y = Y(:,1);
mean_u_profile(y > 204) = nan;


clear h
clc; close all
figure('color', 'white', 'units', 'centimeters', 'position', [15,15,20,10])
tile = tiledlayout(1,2,'padding', 'tight');
sgtitle('PSU Offshore Experiments Inflow: No Waves, $u_{\infty} = 4.2\, m/s$', 'interpreter', 'latex')

h(1) = nexttile;
plot(mean_u_profile, y, 'linewidth', 2)
yline(hub_height)
yline(hub_height + (diameter/2), 'linestyle', '--')
yline(hub_height - (diameter/2), 'linestyle', '--')
axis square
xlim([0, 1])
xlabel(h(1), '$u \mathbin{/} u_{\infty}$', 'interpreter', 'latex', 'fontsize', labelFontSize)
ylabel(tile, '$y$ [mm]', 'interpreter', 'latex', 'fontsize', labelFontSize)

h(2) = nexttile;
plot(mean_Ti_profile, y, 'linewidth', 2)
yline(hub_height)
yline(hub_height + (diameter/2), 'linestyle', '--')
yline(hub_height - (diameter/2), 'linestyle', '--')
axis square
xlim([0, 0.18])
xlabel(h(2), "$Ti = \sqrt{\overline{u' u'}} \mathbin{/} u_{\infty}$", 'interpreter', 'latex', 'fontsize', labelFontSize)
ylabel(tile, '$y$ [mm]', 'interpreter', 'latex', 'fontsize', labelFontSize)

linkaxes(h, 'y')
ylim([-2, 205])


%% Try some quick log-law shii

mean_uv_profile = mean(uv, 2, 'omitnan');

% get u*
nu = 1.46E-5;
u_star = max(sqrt(-mean_uv_profile), [], 'all', 'omitnan');

u_plus = mean_u_profile / u_star;
y_plus = (y * 1E-3 * u_star) / nu;

% Smooth wall reference
k = 0.41;
B = 5;
smooth_y_plus = 10:10:1E4;
smooth_u_plus = (1 / k) * log(smooth_y_plus) + B;

clc; close all
figure('color', 'white')
plot(-mean_uv_profile / (u_inf^2), y, 'LineWidth', 2)
yline(hub_height)
yline(hub_height + (diameter/2), 'linestyle', '--')
yline(hub_height - (diameter/2), 'linestyle', '--')
xlabel("$-\overline{u' v'} \mathbin{/} u_{\infty}^2$", 'interpreter', 'latex', 'fontsize', labelFontSize)
ylabel('$y$ [mm]', 'interpreter', 'latex', 'fontsize', labelFontSize)
xlim([0, 4.5E-3])
ylim([-2, 207])

%% Log-law

figure('color', 'white')
hold on
% plot(smooth_y_plus, smooth_u_plus)
plot(y_plus, u_plus)
hold off
set(gca, 'XScale', 'log')

xlabel("$y^+$", 'interpreter', 'latex', 'fontsize', labelFontSize)
ylabel('$u^+$', 'interpreter', 'latex', 'fontsize', labelFontSize)


%% Save useful values for UPRM

output.u_inf = u_inf;
output.D_mm = diameter;
output.H_mm = hub_height;
output.u_star = u_star;

output.y_mm = y;
output.u_profile_normalized = mean_u_profile;
output.Ti_profile = mean_Ti_profile;

save_folder = 'C:\Users\sadek\Desktop\ZeinScratch';
filename = 'PSU_UPRM_NoWave_Inflow_Profile.mat';
pause(3)
save(fullfile(save_folder, filename), 'output')
clc; fprintf('Matfile Saved!...\n')


%% Stresses Plots

% ax = figure();
% t  = tiledlayout(2,3);
% sgtitle(recording_name, 'interpreter', 'none')
% 
% % Normal Stresses
% nexttile()
% colormap jet
% contourf(X, Y, uu, 100, 'linestyle', 'none')
% axis equal
% xlim([-100,100])
% colorbar()
% title('uu')
% 
% nexttile()
% colormap jet
% contourf(X, Y, vv, 100, 'linestyle', 'none')
% axis equal
% xlim([-100,100])
% colorbar()
% title('vv')
% 
% nexttile()
% colormap jet
% contourf(X, Y, ww, 100, 'linestyle', 'none')
% axis equal
% xlim([-100,100])
% colorbar()
% title('ww')
% 
% 
% % Shear Stresses
% nexttile()
% colormap jet
% contourf(X, Y, uv, 100, 'linestyle', 'none')
% axis equal
% xlim([-100,100])
% colorbar()
% title('uv')
% 
% nexttile()
% colormap jet
% contourf(X, Y, uw, 100, 'linestyle', 'none')
% axis equal
% xlim([-100,100])
% colorbar()
% title('uw')
% 
% nexttile()
% colormap jet
% contourf(X, Y, vw, 100, 'linestyle', 'none')
% axis equal
% xlim([-100,100])
% colorbar()
% title('vw')





















