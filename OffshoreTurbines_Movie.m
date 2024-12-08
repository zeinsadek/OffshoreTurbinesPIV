%%% Video Generator for Time-Resolved PIV Data
% Zein Sadek
% PSU + Oldenburg

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/OffshoreTurbines_Functions');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Farm/Farm_Functions/Inpaint_nans/Inpaint_nans');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/colormaps');
fprintf("All Paths Imported...\n\n");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% Data paths
data_folder = '/Volumes/ZeinResults/Brown/data';
recording   = 'FWF_I_PL1_AK0_A';
save_folder = '/Volumes/ZeinResults/Brown/movies';

data_path   = fullfile(data_folder, strcat(recording, '_DATA.mat'));
data        = load(data_path);
data        = data.output;

% % Coordinates
% X = data.X.';
% Y = data.Y.';
% 
% % Means
% U = data.U;
% V = data.V;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE MOVIE (u)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_images = 10;
FPS        = 14;
levels     = 500;

v = VideoWriter(fullfile(save_folder, strcat(recording, '_U_MOVIE')),'MPEG-4');
v.FrameRate = FPS;
open(v)

clc;
for i = 1:num_images
    progressbarText(i/num_images);
    ax = figure('Visible', 'off');
    % Remove Ticks
    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);

    % Crop
    X = data.X;
    Y = data.Y;
    U = data.U(:,:,i).';
    V = data.V(:,:,i).';
    W = data.W(:,:,i).';


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

    % Delete physically masked portion
    U(X < -25) = nan;
    V(X < -25) = nan;
    W(X < -25) = nan;

    hold on
    colormap(ax, parula)
    contourf(X, Y, U, levels, 'linestyle', 'none')
    axis equal
    axis tight
    xlim([-100,100])
    ylim([-150,100])
    caxis ([0, 4])
    c = colorbar();
    hold off

    frame = getframe(ax);
    close all
    writeVideo(v,frame);
end
close(v);












