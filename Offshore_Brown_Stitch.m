%%% Offshore Plane Stitching (Shitty Version for Brown)

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/OffshoreTurbines_Functions/');
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% Data paths
data_folder = '/Volumes/ZeinResults/Brown/means';

fig_folder  = 'LM33/';
save_folder = strcat('/Volumes/ZeinResults/Brown/figures/', fig_folder);

% Plane 1
plane_1_recording = 'FWF_I_PL1_AK12_LM33_A';
plane_1_data_path = fullfile(data_folder, strcat(plane_1_recording, '_MEANS.mat'));
plane_1_data      = load(plane_1_data_path);
plane_1_data      = plane_1_data.output;

% Plane 2
plane_2_recording = 'FWF_I_PL2_AK12_LM33_A';
plane_2_data_path = fullfile(data_folder, strcat(plane_2_recording, '_MEANS.mat'));
plane_2_data      = load(plane_2_data_path);
plane_2_data      = plane_2_data.output;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRIM AND CROP FRAMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Plane 1
X = plane_1_data.X;
Y = plane_1_data.Y;
U = plane_1_data.u.';
V = plane_1_data.v.';
W = plane_1_data.w.';

uu = plane_1_data.uu.';
vv = plane_1_data.vv.';
ww = plane_1_data.ww.';

uv = plane_1_data.uv.';
uw = plane_1_data.uw.';
vw = plane_1_data.vw.';


% Set ouside of calibration plate to NANs
U(X > 100 | X < -100) = nan;
U(Y < -100 | Y > 100) = nan;
V(X > 100 | X < -100) = nan;
V(Y < -100 | Y > 100) = nan;
W(X > 100 | X < -100) = nan;
W(Y < -100 | Y > 100) = nan;
uu(X > 100 | X < -100) = nan;
uu(Y < -100 | Y > 100) = nan;
vv(X > 100 | X < -100) = nan;
vv(Y < -100 | Y > 100) = nan;
ww(X > 100 | X < -100) = nan;
ww(Y < -100 | Y > 100) = nan;
uv(X > 100 | X < -100) = nan;
uv(Y < -100 | Y > 100) = nan;
uw(X > 100 | X < -100) = nan;
uw(Y < -100 | Y > 100) = nan;
vw(X > 100 | X < -100) = nan;
vw(Y < -100 | Y > 100) = nan;

% Initial, uncropped x positions from DaVis
x = X(1,:);

%%% LHS
% Find index of value closest to what we want to crop to
left_bound = -100;
[~, left_bound_idx] = min(abs(x - left_bound));

% Truncate relavant portion of array
X(:, 1:left_bound_idx) = [];
Y(:, 1:left_bound_idx) = [];
U(:, 1:left_bound_idx) = [];
V(:, 1:left_bound_idx) = [];
W(:, 1:left_bound_idx) = [];
uu(:, 1:left_bound_idx) = [];
vv(:, 1:left_bound_idx) = [];
ww(:, 1:left_bound_idx) = [];
uv(:, 1:left_bound_idx) = [];
uw(:, 1:left_bound_idx) = [];
vw(:, 1:left_bound_idx) = [];

%%% RHS
% Redefine x since it has been partially cropped
x = X(1,:);
% Find index of value closest to what we want to crop to
right_bound = 100;
[~, right_bound_idx] = min(abs(x - right_bound));

% Truncate relavant portion of array
X(:, right_bound_idx:end) = [];
Y(:, right_bound_idx:end) = [];
U(:, right_bound_idx:end) = [];
V(:, right_bound_idx:end) = [];
W(:, right_bound_idx:end) = [];
uu(:, right_bound_idx:end) = [];
vv(:, right_bound_idx:end) = [];
ww(:, right_bound_idx:end) = [];
uv(:, right_bound_idx:end) = [];
uw(:, right_bound_idx:end) = [];
vw(:, right_bound_idx:end) = [];

% Flip components to have flow be left to right
U = fliplr(U);
V = fliplr(V);
W = fliplr(W);

uu = fliplr(uu);
vv = fliplr(vv);
ww = fliplr(ww);
uv = fliplr(uv);
uw = fliplr(uw);
vw = fliplr(vw);

% Delete physically masked portion. Only Plane 1
U(X < -20) = nan;
V(X < -20) = nan;
W(X < -20) = nan;

uu(X < -20) = nan;
vv(X < -20) = nan;
ww(X < -20) = nan;

uv(X < -20) = nan;
uw(X < -20) = nan;
vw(X < -20) = nan;

% Save Trimmed and Cropped Versions
P1_Cropped.X = X;
P1_Cropped.Y = Y;

P1_Cropped.U = U;
P1_Cropped.V = V;
P1_Cropped.W = W;

P1_Cropped.uu = uu;
P1_Cropped.vv = vv;
P1_Cropped.ww = ww;

P1_Cropped.uv = uv;
P1_Cropped.uw = uw;
P1_Cropped.vw = vw;


%% Plane 2

X = plane_2_data.X;
Y = plane_2_data.Y;
U = plane_2_data.u.';
V = plane_2_data.v.';
W = plane_2_data.w.';

uu = plane_2_data.uu.';
vv = plane_2_data.vv.';
ww = plane_2_data.ww.';

uv = plane_2_data.uv.';
uw = plane_2_data.uw.';
vw = plane_2_data.vw.';


% Set ouside of calibration plate to NANs
U(X > 100 | X < -100) = nan;
U(Y < -100 | Y > 100) = nan;
V(X > 100 | X < -100) = nan;
V(Y < -100 | Y > 100) = nan;
W(X > 100 | X < -100) = nan;
W(Y < -100 | Y > 100) = nan;
uu(X > 100 | X < -100) = nan;
uu(Y < -100 | Y > 100) = nan;
vv(X > 100 | X < -100) = nan;
vv(Y < -100 | Y > 100) = nan;
ww(X > 100 | X < -100) = nan;
ww(Y < -100 | Y > 100) = nan;
uv(X > 100 | X < -100) = nan;
uv(Y < -100 | Y > 100) = nan;
uw(X > 100 | X < -100) = nan;
uw(Y < -100 | Y > 100) = nan;
vw(X > 100 | X < -100) = nan;
vw(Y < -100 | Y > 100) = nan;

% Initial, uncropped x positions from DaVis
x = X(1,:);

%%% LHS
% Find index of value closest to what we want to crop to
left_bound = -100;
[~, left_bound_idx] = min(abs(x - left_bound));

% Truncate relavant portion of array
X(:, 1:left_bound_idx) = [];
Y(:, 1:left_bound_idx) = [];
U(:, 1:left_bound_idx) = [];
V(:, 1:left_bound_idx) = [];
W(:, 1:left_bound_idx) = [];
uu(:, 1:left_bound_idx) = [];
vv(:, 1:left_bound_idx) = [];
ww(:, 1:left_bound_idx) = [];
uv(:, 1:left_bound_idx) = [];
uw(:, 1:left_bound_idx) = [];
vw(:, 1:left_bound_idx) = [];

%%% RHS
% Redefine x since it has been partially cropped
x = X(1,:);
% Find index of value closest to what we want to crop to
right_bound = 100;
[~, right_bound_idx] = min(abs(x - right_bound));

% Truncate relavant portion of array
X(:, right_bound_idx:end) = [];
Y(:, right_bound_idx:end) = [];
U(:, right_bound_idx:end) = [];
V(:, right_bound_idx:end) = [];
W(:, right_bound_idx:end) = [];
uu(:, right_bound_idx:end) = [];
vv(:, right_bound_idx:end) = [];
ww(:, right_bound_idx:end) = [];
uv(:, right_bound_idx:end) = [];
uw(:, right_bound_idx:end) = [];
vw(:, right_bound_idx:end) = [];

% Flip components to have flow be left to right
U = fliplr(U);
V = fliplr(V);
W = fliplr(W);

uu = fliplr(uu);
vv = fliplr(vv);
ww = fliplr(ww);
uv = fliplr(uv);
uw = fliplr(uw);
vw = fliplr(vw);

% Save Trimmed and Cropped Versions
P2_Cropped.X = X;
P2_Cropped.Y = Y;

P2_Cropped.U = U;
P2_Cropped.V = V;
P2_Cropped.W = W;

P2_Cropped.uu = uu;
P2_Cropped.vv = vv;
P2_Cropped.ww = ww;

P2_Cropped.uv = uv;
P2_Cropped.uw = uw;
P2_Cropped.vw = vw;

% figure()
% contourf(P2_Cropped.X, P2_Cropped.Y, P2_Cropped.U, 100, 'linestyle', 'none')
% axis equal

%% Generate Mass Meshgrid to Hold Both Planes

u_inf = 4.2;

big_X = cat(1,P1_Cropped.X(1:669, 1:405), P2_Cropped.X(1:669, 1:405) + 158);
big_Y = cat(1,P1_Cropped.Y(1:669, 1:405), P2_Cropped.Y(1:669, 1:405));

big_U = cat(1,P1_Cropped.U(1:669, 1:405), P2_Cropped.U(1:669, 1:405)) / u_inf;
big_V = cat(1,P1_Cropped.V(1:669, 1:405), P2_Cropped.V(1:669, 1:405)) / u_inf;
big_W = cat(1,P1_Cropped.W(1:669, 1:405), P2_Cropped.W(1:669, 1:405)) / u_inf;

big_uu = cat(1,P1_Cropped.uu(1:669, 1:405), P2_Cropped.uu(1:669, 1:405)) / u_inf^2;
big_vv = cat(1,P1_Cropped.vv(1:669, 1:405), P2_Cropped.vv(1:669, 1:405)) / u_inf^2;
big_ww = cat(1,P1_Cropped.ww(1:669, 1:405), P2_Cropped.ww(1:669, 1:405)) / u_inf^2;

big_uv = cat(1,P1_Cropped.uv(1:669, 1:405), P2_Cropped.uv(1:669, 1:405)) / u_inf^2;
big_uw = cat(1,P1_Cropped.uw(1:669, 1:405), P2_Cropped.uw(1:669, 1:405)) / u_inf^2;
big_vw = cat(1,P1_Cropped.vw(1:669, 1:405), P2_Cropped.vw(1:669, 1:405)) / u_inf^2;

% Offset X to be zero at turbine
big_X = big_X + 137.5;
big_Y = big_Y - 20;

%% Plotting

X_LL = -30;
X_UL = 350;
Y_UL = 100 - 20;
Y_LL = -125 - 20;


fig = figure('Position', [500, 500, 600, 1000]);
t = tiledlayout(3,1,'tilespacing', 'compact');
ax1 = nexttile();
contourf(big_X, big_Y, big_U, 100, 'linestyle', 'none');
colormap(ax1, 'parula')
axis equal
caxis([0, 0.5])
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('u')
xlabel('x [mm]')
ylabel('y [mm]')
c.Label.String = '$u / u_{\infty}$';
c.Label.Interpreter = 'Latex';

ax2 = nexttile();
contourf(big_X, big_Y, big_V, 100, 'linestyle', 'none');
colormap(ax2, 'coolwarm')
caxis([-0.07, 0.04])
axis equal
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('v')
xlabel('x [mm]')
ylabel('y [mm]')
c.Label.String = '$v / u_{\infty}$';
c.Label.Interpreter = 'Latex';

ax3 = nexttile();
contourf(big_X, big_Y, big_W, 100, 'linestyle', 'none');
colormap(ax3, 'coolwarm')
caxis([-0.05, 0.05])
axis equal
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('w')
xlabel('x [mm]')
ylabel('y [mm]')
c.Label.String = '$w / u_{\infty}$';
c.Label.Interpreter = 'Latex';

% Save Figure
exportgraphics(fig, strcat(save_folder, 'Means.png'), 'resolution', 200);


%% Normal Stresses

fig = figure('Position', [500, 500, 600, 1000]);
t = tiledlayout(3,1);
nexttile()
contourf(big_X, big_Y, big_uu, 100, 'linestyle', 'none');
axis equal
caxis([0, 0.025])
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('uu')
xlabel('x [mm]')
ylabel('y [mm]')
% c.Label.String = '$m^2/s^2$';
% c.Label.Interpreter = 'Latex';

nexttile()
contourf(big_X, big_Y, big_vv, 100, 'linestyle', 'none');
axis equal
caxis([0, 15E-3])
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('vv')
xlabel('x [mm]')
ylabel('y [mm]')
% c.Label.String = '$m^2/s^2$';
% c.Label.Interpreter = 'Latex';

nexttile()
contourf(big_X, big_Y, big_ww, 100, 'linestyle', 'none');
axis equal
caxis([0, 0.025])
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('ww')
xlabel('x [mm]')
ylabel('y [mm]')
% c.Label.String = '$m^2/s^2$';
% c.Label.Interpreter = 'Latex';

% Save Figure
exportgraphics(fig, strcat(save_folder, 'Normal_Stresses.png'), 'resolution', 200);


%% Shear Stresses

fig = figure('Position', [500, 500, 600, 1000]);
t = tiledlayout(3,1);
ax1 = nexttile();
contourf(big_X, big_Y, big_uv, 100, 'linestyle', 'none');
colormap(ax1, 'coolwarm')
axis equal
caxis([-4E-3, 11E-3])
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('uv')
xlabel('x [mm]')
ylabel('y [mm]')
% c.Label.String = '$m^2/s^2$';
% c.Label.Interpreter = 'Latex';

ax2 = nexttile();
contourf(big_X, big_Y, big_uw, 100, 'linestyle', 'none');
colormap(ax2, 'coolwarm')
caxis([-3E-3, 4E-3])
axis equal
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('uw')
xlabel('x [mm]')
ylabel('y [mm]')
% c.Label.String = '$m^2/s^2$';
% c.Label.Interpreter = 'Latex';

nexttile()
contourf(big_X, big_Y, big_vw, 100, 'linestyle', 'none');
axis equal
caxis([-2.5E-3, 0.5E-3])
xline(60 + 137.5, 'linewidth', 5, 'color', 'w')
xlim([X_LL, X_UL])
ylim([Y_LL, Y_UL])
c = colorbar();
title('vw')
xlabel('x [mm]')
ylabel('y [mm]')
% c.Label.String = '$m^2/s^2$';
% c.Label.Interpreter = 'Latex';

% Save Figure
exportgraphics(fig, strcat(save_folder, 'Shear_Stresses.png'), 'resolution', 200);
close all





















