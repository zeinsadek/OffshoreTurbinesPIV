%%% Stereo-PIV Wave Detection and Cropping
% Zein Sadek, PSU

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/Offshore_Turbines_PIV/FWF_I_PL1_AK12_LM50_A_perspective%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/OffshoreTurbines/OffshoreTurbines_Functions');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/colormaps');
fprintf("All Paths Imported...\n\n");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
image_directory = '/Volumes/ZeinResults/Perspective/FWF_I_PL1_AK12_LM50_A_Perspective';
images = dir([image_directory, '/*.im7']);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD IMAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

raw = readimx([image_directory, '\', images(101).name]);

% Load snapshots from both Cameras
raw_image_CAM1 = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
% raw_image_CAM1 = flipud((raw_image_CAM1));

raw_image_CAM2 = raw.Frames{3,1}.Components{1,1}.Planes{1,1};
% raw_image_CAM2 = flipud((raw_image_CAM2));

% Get coordinates
nf = size(raw_image_CAM1);
x = raw.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*raw.Frames{1,1}.Grids.X + raw.Frames{1,1}.Scales.X.Offset;
y = raw.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*raw.Frames{1,1}.Grids.Y + raw.Frames{1,1}.Scales.Y.Offset;

% Old
% [Y, X] = meshgrid(x, y);
% X = (rot90(-X));
% Y = (rot90(-Y));

% New
[X, Y] = meshgrid(x, y);
raw_image_CAM1 = fliplr(raw_image_CAM1.');
raw_image_CAM2 = fliplr(raw_image_CAM2.');
X = -fliplr(X);

%%

figure()
contourf(X,Y,raw_image_CAM1)
colorbar()
axis equal


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMBINING STEREO IMAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get individual FOV
raw_image_CAM1(raw_image_CAM1 == 0) = nan;
raw_image_CAM2(raw_image_CAM2 == 0) = nan;

% Binaraize
CAM1_FOV_mask = ~isnan(raw_image_CAM1);
CAM2_FOV_mask = ~isnan(raw_image_CAM2);

% Get combined FOV_mask
FOV_mask = CAM1_FOV_mask + CAM2_FOV_mask;
FOV_mask(FOV_mask < 2) = 0;
FOV_mask = FOV_mask/2;

% Combined stereo image
combined_image = FOV_mask .* (raw_image_CAM1 + raw_image_CAM2);

% Mask Plane 1 because of tape
combined_image(X < -20) = nan;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROP ARRAY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Crop array dimensions
%%% LHS
% Find index of value closest to what we want to crop to
% Initial, uncropped x positions from DaVis
x = X(1,:);
left_bound = -100;
[~, left_bound_idx] = min(abs(x - left_bound));

% Truncate relavant portion of array
X(:, 1:left_bound_idx) = [];
Y(:, 1:left_bound_idx) = [];
combined_image(:, 1:left_bound_idx) = [];

%%% RHS
% Redefine x since it has been partially cropped
x = X(1,:);
% Find index of value closest to what we want to crop to
right_bound = 100;
[~, right_bound_idx] = min(abs(x - right_bound));

% Truncate relavant portion of array
X(:, right_bound_idx:end) = [];
Y(:, right_bound_idx:end) = [];
combined_image(:, right_bound_idx:end) = [];
x = X(1,:);

%% Testing Different Gaussian Blurs

tst = combined_image;
tst_blur = juliaan_smooth(combined_image, 25);

tst(tst < 50) = nan;
tst_blur(tst_blur < 50) = nan;

figure()
t = tiledlayout(1,2);
nexttile()
contourf(X,Y,tst, 'LineStyle', 'none')
xline(0)
axis equal
title('OG')
xlim([-100, 100])
colorbar()

nexttile()
contourf(X,Y,tst_blur, 'LineStyle', 'none')
xline(0)
axis equal
title('Blurred')
xlim([-100, 100])
colorbar()

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EDGE DETECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Canny Params
canny_lower = 0.1;
canny_upper = 0.4;
background  = 40;

% Normal Gauss
blur_size = 15;

% Juliaan
% blur_size   = 25;

% Get Image Size before Blurring
nf = size(combined_image);

% Blur and Threshold
combined_image_blurred = imgaussfilt(combined_image, blur_size);
% combined_image_blurred = juliaan_smooth(combined_image, blur_size);
combined_image_blurred(combined_image_blurred < background) = 0;

% Canny Edge Deetection
wave_edge = edge(combined_image_blurred, 'Canny', [canny_lower, canny_upper]);
wave_profile = zeros(1, nf(2));

% Seperate free surface
y = Y(:,1);

% Clean up detected edge
for i = 1:nf(2)
    [ones_r, ~] = find(wave_edge(:, i) == 1);
    size_ones   = size(ones_r);
    len         = size_ones(1);
    if len == 0
        wave_profile(1, i) = nan;
    else
        wave_profile(1, i) = y(min(ones_r));
    end
end

% Clean profile
wave_profile(wave_profile > 0) = nan;

% Crop Real Image
wave_cropped_image = combined_image;
wave_cropped_image(Y < wave_profile) = nan;

% Plot
figure()
t = tiledlayout(1,2);
nexttile()
hold on
contourf(X,Y,combined_image, 'linestyle', 'none')
plot(x, wave_profile, 'red')
xline(0)
hold off
axis equal
xlim([-100, 100])

nexttile()
hold on
contourf(X,Y,wave_cropped_image, 'linestyle', 'none')
plot(x, wave_profile, 'red')
xline(0)
hold off
axis equal
xlim([-100, 100])



%%
% figure()
% t = tiledlayout(1,4);
% nexttile()
% contourf(X, Y, CAM1_FOV_mask)
% axis equal
% colorbar()
% title("CAM 1 FOV_mask")
% xlim([-100, 100])
% ylim([-100, 100])
% 
% nexttile()
% contourf(X, Y, CAM2_FOV_mask)
% axis equal
% colorbar()
% title("CAM 2 FOV_mask")
% xlim([-100, 100])
% ylim([-100, 100])
% 
% nexttile()
% contourf(X, Y, FOV_mask)
% xline(-30)
% axis equal
% colorbar()
% title("Total FOV_mask")
% xlim([-100, 100])
% ylim([-100, 100])
% 
% nexttile()
% contourf(X, Y, combined_image)
% % xline(-30)
% axis equal
% colorbar()
% title("Combined Images")
% xlim([-100, 100])
% ylim([-100, 100])







