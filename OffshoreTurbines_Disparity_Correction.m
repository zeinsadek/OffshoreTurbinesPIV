%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/OffshoreTurbines/OffshoreTurbines_Functions');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/colormaps');
fprintf("All Paths Imported...\n\n");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
plane       = 1;
image_dir   = '/Volumes/ZEIN_KEYS/Stitching';
images_path = strcat(image_dir, '/Plane', num2str(plane), '/ArUcoImageCorrection/*.im7');
images      = dir(char(images_path));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD IMAGES FROM PLANES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Read .im7 file
image_path = strcat(image_dir, '/Plane', num2str(plane), '/ArUcoImageCorrection/', images(1).name);
raw_images = readimx(char(image_path));

% Load snapshots from both Cameras
CAM1.raw_image = raw_images.Frames{1,1}.Components{1,1}.Planes{1,1};
CAM2.raw_image = raw_images.Frames{2,1}.Components{1,1}.Planes{1,1};

% Get coordinates
nf     = size(CAM1.raw_image);
x      = raw_images.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*raw_images.Frames{1,1}.Grids.X + raw_images.Frames{1,1}.Scales.X.Offset;
y      = raw_images.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*raw_images.Frames{1,1}.Grids.Y + raw_images.Frames{1,1}.Scales.Y.Offset;
[X, Y] = meshgrid(x, y);
X      = -fliplr(X);

% Reorient flow left to right
CAM1.raw_image = fliplr(CAM1.raw_image.');
CAM2.raw_image = fliplr(CAM2.raw_image.');


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESIZE IMAGES TO NOT KILL COMPUTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scale = 0.1;

% Resize images
CAM1.raw_image = imresize(CAM1.raw_image, scale);
CAM2.raw_image = imresize(CAM2.raw_image, scale);

% Resize coordinates
X = imresize(X, scale);
Y = imresize(Y, scale);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT RAW IMAGES TO CHECK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure()
tiledlayout(1,3)
sgtitle(strcat('Plane', {' '}, num2str(plane)), ': Uncorrected');
nexttile
contourf(X, Y, CAM1.raw_image, 100, 'linestyle', 'none')
colormap('gray')
axis equal
title('CAM 1')

nexttile
contourf(X, Y, CAM2.raw_image, 100, 'linestyle', 'none')
colormap('gray')
axis equal
title('CAM 2')

nexttile
contourf(X, Y, CAM1.raw_image + CAM2.raw_image, 100, 'linestyle', 'none')
colormap('gray')
axis equal
title('CAM1 + CAM 2')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CROP IMAGES TO AVOID ZERO PADS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% sum along columns and compute gradient to detect the edge where the image
% starts
[~, CAM1_locs] = findpeaks(abs(gradient(sum(CAM1.raw_image, 1))));
[~, CAM2_locs] = findpeaks(abs(gradient(sum(CAM2.raw_image, 1))));

% use the biggest left index from either image and the smallest right index
left_crop_idx = max([CAM1_locs(1), CAM2_locs(1)]);
right_crop_idx = min([CAM1_locs(end), CAM2_locs(end)]);

% plot to check
figure()
tiledlayout(1,3)
sgtitle(strcat('Plane', {' '}, num2str(plane), ': Crop bounds'));
nexttile
contourf(X, Y, CAM1.raw_image, 100, 'linestyle', 'none')
colormap('gray')
axis equal
title('CAM 1')
xline(X(1,CAM1_locs(1)), 'color', 'red', 'LineWidth', 3)
xline(X(1,CAM1_locs(end)), 'color', 'red', 'LineWidth', 3)

nexttile
contourf(X, Y, CAM2.raw_image, 100, 'linestyle', 'none')
colormap('gray')
axis equal
title('CAM 2')
xline(X(1,CAM2_locs(1)), 'color', 'red', 'LineWidth', 3)
xline(X(1,CAM2_locs(end)), 'color', 'red', 'LineWidth', 3)

nexttile
contourf(X, Y, CAM1.raw_image + CAM2.raw_image, 100, 'linestyle', 'none')
colormap('gray')
axis equal
title('CAM1 + CAM 2')
xline(X(1,left_crop_idx), 'color', 'red', 'LineWidth', 3)
xline(X(1,right_crop_idx), 'color', 'red', 'LineWidth', 3)


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND TOTAL IMAGE TRANSLATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save transformation matrix
transformation_matrix = imregcorr(CAM1.raw_image(:, left_crop_idx:right_crop_idx), CAM2.raw_image(:, left_crop_idx:right_crop_idx), "translation");
image_size = imref2d(size(CAM1.raw_image));
aligned_image = CAM2.raw_image + imwarp(CAM1.raw_image, transformation_matrix, "OutputView", image_size);

% Plot to check
figure()
sgtitle(strcat('Plane', {' '}, num2str(plane), ': Aligned Image'))
contourf(X, Y, aligned_image, 100, 'linestyle', 'none')
axis equal

% extract shift (expressed in pixels)
x_shift_total = transformation_matrix.Translation(1);
y_shift_total = transformation_matrix.Translation(2);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BACK CALCULATE RELATIVE CAMERA SHIFTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get camera angles from excel
CAM1_calibration_angles = readmatrix('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/OffshoreTurbines/PIVXY_Calibrations.xlsx', 'Sheet', 'CAM1');
CAM2_calibration_angles = readmatrix('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/OffshoreTurbines/PIVXY_Calibrations.xlsx', 'Sheet', 'CAM2');

CAM1.x_rotation = CAM1_calibration_angles(plane, 3);
CAM2.x_rotation = CAM2_calibration_angles(plane, 3);

% do trig
mm_per_pixel =  mean(diff(X(1,2:end-1)), 'all', 'omitnan');
d_pixels     = x_shift_total / (tand(abs(CAM1.x_rotation)) + tand(abs(CAM2.x_rotation)));
% d_mm         = d_pixels * mm_per_pixel;

% calculate shifts for each camera
% be careful with signs of angles. cam1 needs to shift to the right, cam 2
% needs to shift to the left
CAM1.shift = -d_pixels * tand(CAM1.x_rotation);
CAM2.shift = -d_pixels * tand(CAM2.x_rotation);

%% Shift images and add

CAM1.shifted_image = imtranslate(CAM1.raw_image, [CAM1.shift, 0]);
CAM2.shifted_image = imtranslate(CAM2.raw_image, [CAM2.shift, 0]);
combined_image     = CAM1.shifted_image + CAM2.shifted_image;

figure()
contourf(X, Y, combined_image, 100, 'linestyle', 'none')
axis equal

%% Plane 1
% Get individual FOV
CAM1.shifted_image(CAM1.shifted_image == 0) = nan;
CAM2.shifted_image(CAM2.shifted_image == 0) = nan;

% Binaraize
CAM1.FOV_mask = ~isnan(CAM1.shifted_image);
CAM2.FOV_mask = ~isnan(CAM2.shifted_image);

% Get combined FOV_mask
FOV_mask = CAM1.FOV_mask + CAM2.FOV_mask;
FOV_mask(FOV_mask < 2) = 0;
FOV_mask = FOV_mask/2;

% Combined stereo image
combined_image_masked = FOV_mask .* combined_image;
% combined_image_masked(combined_image_masked == 0) = nan;

figure()
contourf(X, Y, combined_image_masked, 100, 'linestyle', 'none')
axis equal


%% Try translating
CAM1_angle = 27.69;
CAM2_angle = 9.32;
mm_per_pix = 0.4911;
d = 13;
d_pix = 34;
s_CAM1 = d_pix * tand(CAM1_angle);
s_CAM2 = -d_pix * tand(CAM2_angle);
figure()
tiledlayout(1,3)

% manual shifting
test = raw_image_CAM1 + imtranslate(raw_image_CAM2, [-29, 0]);
figure()
contourf(X, Y, test, 100, 'linestyle', 'none')
axis equal


% It is important to remove the zeroes padding the images since they will
% skew the cross-correlation. Both images need to be cropped the same also
transformation_matrix = imregcorr(raw_image_CAM1(:, 148:457), raw_image_CAM2(:, 148:457), "translation");
image_size = imref2d(size(raw_image_CAM1));
raw_image_CAM1 = imwarp(raw_image_CAM1, transformation_matrix,"OutputView",image_size);
test = raw_image_CAM1 + raw_image_CAM2;
figure()
contourf(X, Y, test, 100, 'linestyle', 'none')
axis equal








%% Combining FOV between two CAMs

%% Plane 1
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
plane1_image = FOV_mask .* (raw_image_CAM1 + raw_image_CAM2);

figure()
contourf(X, Y, plane1_image, 100, 'linestyle', 'none')
axis equal

%% Plane 2
% Get individual FOV
raw_image_plane2_CAM1(raw_image_plane2_CAM1 == 0) = nan;
raw_image_plane2_CAM2(raw_image_plane2_CAM2 == 0) = nan;

% Binaraize
CAM1_FOV_mask_plane2 = ~isnan(raw_image_plane2_CAM1);
CAM2_FOV_mask_plane2 = ~isnan(raw_image_plane2_CAM2);

% Get combined FOV_mask
FOV_mask_plane2 = CAM1_FOV_mask_plane2 + CAM2_FOV_mask_plane2;
FOV_mask_plane2(FOV_mask_plane2 < 2) = 0;
FOV_mask_plane2 = FOV_mask_plane2/2;

% Combined stereo image
plane2_image = FOV_mask_plane2 .* (raw_image_plane2_CAM1 + raw_image_plane2_CAM2);
















