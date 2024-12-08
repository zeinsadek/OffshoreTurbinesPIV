%% Brown Phase Average

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/OffshoreTurbines_Functions');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Farm/Farm_Functions/Inpaint_nans/Inpaint_nans');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/colormaps');
fprintf("All Paths Imported...\n\n");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
project_path   = '/Volumes/ZeinResults/PIV';
recording_name = 'FWF_I_PL1_AK12_LM50_A';
inpt_name      = recording_name;


% Image paths
piv_path = fullfile(project_path, recording_name);

% Save paths
results_path = '/Volumes/ZeinResults/Brown/';
mtlb_file    = strcat(results_path, 'data'   , '/', inpt_name, '_DATA.mat');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DAVIS TO MATLAB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = vector2matlabXZ(piv_path, mtlb_file);

%% Pseudo Phase Average

U_avg = mean(data.U(:,:,1:10:end), 3, 'omitnan');
V_avg = mean(data.V(:,:,3:10:end), 3, 'omitnan');
W_avg = mean(data.W(:,:,10:10:end), 3, 'omitnan');

X = data.X;
Y = data.Y;
U = U_avg.';
V = V_avg.';
W = W_avg.';


% Set ouside of calibration plate to NANs
U(X > 100 | X < -100) = nan;
U(Y < -100 | Y > 100) = nan;

V(X > 100 | X < -100) = nan;
V(Y < -100 | Y > 100) = nan;

W(X > 100 | X < -100) = nan;
W(Y < -100 | Y > 100) = nan;

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

% Flip components to have flow be left to right
U = fliplr(U);
V = fliplr(V);
W = fliplr(W);

% % Delete physically masked portion. Only for Plane 1
U(X < -25) = nan;
V(X < -25) = nan;
W(X < -25) = nan;

figure()
contourf(X, Y, W, 100, 'linestyle', 'none')
xlim([-100, 100])
ylim([-150, 100])
caxis([-0.25, 0.25])
axis equal
colorbar()






