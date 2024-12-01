%%% Offshore APS Plane Stitching
% No blending in overlap. Will place frames side by side, deleating overlap

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/OffshoreTurbines_Functions/');
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Image paths
means_path = '/Volumes/ZeinResults/APS/means';

% Save paths
figures_path = '/Volumes/ZeinResults/APS/figures';
stitch_path  = '/Volumes/ZeinResults/APS/stitch';

% Load Planes
experiment = 'FWF_I_AK12_LM50';
plane1 = load(fullfile(means_path, 'FWF_I_PL1_AK12_LM50_A_MEANS.mat'));
plane2 = load(fullfile(means_path, 'FWF_I_PL2_AK12_LM50_A_MEANS.mat'));
plane1 = plane1.output;
plane2 = plane2.output;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRUNCATE PLANE 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x = plane1.X(1,:);
left_bound = -60;
[~, left_bound_idx] = min(abs(x - left_bound));

fields = {'u', 'v', 'w', 'uu', 'vv', 'ww', 'uv', 'uw', 'vw', 'X', 'Y', 'Waves'};
for i = 1:length(fields)
    plane2.(fields{i})(:, 1:left_bound_idx) = [];
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STACK PLANES  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

D = 150;
U_inf = 4.2;

plane1_X = plane1.('X') + 130;
plane2_X = plane2.('X') + 290;

% make sizes match
plane1_size = size(plane1_X);
plane2_size = size(plane2_X);
row_size    = min(plane1_size(1), plane2_size(1));


X = [plane1_X(1:row_size,:), plane2_X(1:row_size,:)];
Y = [plane1.('Y')(1:row_size,:), plane2.('Y')(1:row_size,:)];
Y = Y - 20;

components = {'u', 'v', 'w', 'uu', 'vv', 'ww', 'uv', 'uw', 'vw'};
for i = 1:length(components)
    if ismember(components{i}, {'u', 'v', 'w'})
        stitch.(components{i}) = [plane1.(components{i})(1:row_size,:), plane2.(components{i})(1:row_size,:)] / U_inf;
    else
        stitch.(components{i}) = [plane1.(components{i})(1:row_size,:), plane2.(components{i})(1:row_size,:)] / (U_inf^2);
    end
end

stitch.X = X;
stitch.Y = Y;

% Save stiched planes
save(fullfile(stitch_path, strcat(experiment, '_STITCH.mat')), 'stitch');

% ax = figure();
% contourf(X/D, Y/D, stitch.('u'), 50, 'LineStyle', 'none')
% xline(plane2_X(1,1)/D, 'color', 'white', 'LineWidth', 2)
% axis equal
% colorbar()
% xlim([0, 2.5])
% ylim([-1.2, 0.55])
% xlabel('$x / D$', 'interpreter', 'latex')
% ylabel('$y / D$', 'Interpreter', 'latex')









