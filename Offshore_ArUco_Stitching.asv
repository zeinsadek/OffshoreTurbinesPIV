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
image_directory = '/Volumes/ZEIN_KEYS/Stitching';
images1 = dir([image_directory, '/Plane1/ArUcoImageCorrection/*.im7']);
images2 = dir([image_directory, '/Plane2/ArUcoImageCorrection/*.im7']);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD IMAGES FROM PLANES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

raw1 = readimx([image_directory, '/Plane1/ArUcoImageCorrection/', images1(1).name]);
raw2 = readimx([image_directory, '/Plane2/ArUcoImageCorrection/', images2(1).name]);

% Load snapshots from both Cameras
raw_image_plane1_CAM1 = raw1.Frames{1,1}.Components{1,1}.Planes{1,1};
raw_image_plane2_CAM1 = raw2.Frames{1,1}.Components{1,1}.Planes{1,1};

raw_image_plane1_CAM2 = raw1.Frames{2,1}.Components{1,1}.Planes{1,1};
raw_image_plane2_CAM2 = raw2.Frames{2,1}.Components{1,1}.Planes{1,1};

% Get coordinates
% Plane 1
nf = size(raw_image_plane1_CAM1);
x1 = raw1.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*raw1.Frames{1,1}.Grids.X + raw1.Frames{1,1}.Scales.X.Offset;
y1 = raw1.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*raw1.Frames{1,1}.Grids.Y + raw1.Frames{1,1}.Scales.Y.Offset;
[X1, Y1] = meshgrid(x1, y1);
X1 = -fliplr(X1);

% Plane 2
nf = size(raw_image_plane2_CAM1);
x2 = raw2.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*raw2.Frames{1,1}.Grids.X + raw2.Frames{1,1}.Scales.X.Offset;
y2 = raw2.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*raw2.Frames{1,1}.Grids.Y + raw2.Frames{1,1}.Scales.Y.Offset;
[X2, Y2] = meshgrid(x2, y2);
X2 = -fliplr(X2);

% Reorient flow left to right
raw_image_plane1_CAM1 = fliplr(raw_image_plane1_CAM1.');
raw_image_plane1_CAM2 = fliplr(raw_image_plane1_CAM2.');
raw_image_plane2_CAM1 = fliplr(raw_image_plane2_CAM1.');
raw_image_plane2_CAM2 = fliplr(raw_image_plane2_CAM2.');

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESIZE IMAGES TO NOT KILL COMPUTER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scale = 0.1;
raw_image_plane1_CAM1 = imresize(raw_image_plane1_CAM1, scale);
raw_image_plane1_CAM2 = imresize(raw_image_plane1_CAM2, scale);
raw_image_plane2_CAM1 = imresize(raw_image_plane2_CAM1, scale);
raw_image_plane2_CAM2 = imresize(raw_image_plane2_CAM2, scale);

X1 = imresize(X1, scale);
Y1 = imresize(Y1, scale);
X2 = imresize(X2, scale);
Y2 = imresize(Y2, scale);


%%
% raw_image_plane1_CAM1(raw_image_plane1_CAM1 == 0) = nan;
% raw_image_plane1_CAM2(raw_image_plane1_CAM2 == 0) = nan;

%% Try translating

CAM1_angle = 15;
CAM2_angle = 30;
mm_per_pix = 0.4911;
d = 13;
% d_pix = d/mm_per_pix;
d_pix = 34;

s_CAM1 = round(d_pix * tand(CAM1_angle), 2);
s_CAM2 = -round(d_pix * tand(CAM2_angle), 2);


figure()
tiledlayout(1,3)

% OG
% nexttile
% contourf(X1, Y1, raw_image_plane1_CAM1, 100, 'linestyle', 'none')
% axis equal
% title('cam 1')
% 
% nexttile
% contourf(X1, Y1, raw_image_plane1_CAM2, 100, 'linestyle', 'none')
% axis equal
% title('cam 2')
% 
% nexttile
% contourf(X1, Y1, raw_image_plane1_CAM1 + raw_image_plane1_CAM2, 100, 'linestyle', 'none')
% axis equal
% title('cam 1 + cam 2')


% Translated
nexttile
contourf(X1, Y1, imtranslate(raw_image_plane1_CAM1, [s_CAM1, 0], 'bilinear'), 100, 'linestyle', 'none')
axis equal
title('cam 1 translated')
xline(X1(1,148), 'color', 'white', 'linewidth', 3)
xline(X1(1,457), 'color', 'white', 'linewidth', 3)

nexttile
contourf(X1, Y1, imtranslate(raw_image_plane1_CAM2, [s_CAM2, 0]), 100, 'linestyle', 'none')
axis equal
title('cam 2 translated')
xline(X1(1,126), 'color', 'white', 'linewidth', 3)
xline(X1(1,442), 'color', 'white', 'linewidth', 3)

nexttile
contourf(X1, Y1, imtranslate(raw_image_plane1_CAM1, [s_CAM1, 0]) + imtranslate(raw_image_plane1_CAM2, [s_CAM2, 0]), 100, 'linestyle', 'none')
axis equal
title('cam 1 translated + cam 2 translated')

%% manual shifting

test = raw_image_plane1_CAM1 + imtranslate(raw_image_plane1_CAM2, [-29, 0]);

figure()
contourf(X1, Y1, test, 100, 'linestyle', 'none')
axis equal




%%

% It is important to remove the zeroes padding the images since they will
% skew the cross-correlation. Both images need to be cropped the same also

tformEstimate = imregcorr(raw_image_plane1_CAM1(:, 148:457), raw_image_plane1_CAM2(:, 148:457), "translation");
Rfixed = imref2d(size(raw_image_plane1_CAM1));

movingReg = imwarp(raw_image_plane1_CAM1, tformEstimate,"OutputView",Rfixed);

test = movingReg + raw_image_plane1_CAM2;
figure()
contourf(X1, Y1, test, 100, 'linestyle', 'none')
axis equal
% imshowpair(movingReg, raw_image_plane1_CAM2,"montage")


%%
test = raw_image_plane1_CAM1 + raw_image_plane1_CAM2;
figure()
contourf(X1, Y1, test, 100, 'linestyle', 'none')
axis equal






% %% Combining FOV between two CAMs
% 
% %% Plane 1
% % Get individual FOV
% raw_image_plane1_CAM1(raw_image_plane1_CAM1 == 0) = nan;
% raw_image_plane1_CAM2(raw_image_plane1_CAM2 == 0) = nan;
% 
% % Binaraize
% CAM1_FOV_mask_plane1 = ~isnan(raw_image_plane1_CAM1);
% CAM2_FOV_mask_plane1 = ~isnan(raw_image_plane1_CAM2);
% 
% % Get combined FOV_mask
% FOV_mask_plane1 = CAM1_FOV_mask_plane1 + CAM2_FOV_mask_plane1;
% FOV_mask_plane1(FOV_mask_plane1 < 2) = 0;
% FOV_mask_plane1 = FOV_mask_plane1/2;
% 
% % Combined stereo image
% plane1_image = FOV_mask_plane1 .* (raw_image_plane1_CAM1 + raw_image_plane1_CAM2);
% 
% %% Plane 2
% % Get individual FOV
% raw_image_plane2_CAM1(raw_image_plane2_CAM1 == 0) = nan;
% raw_image_plane2_CAM2(raw_image_plane2_CAM2 == 0) = nan;
% 
% % Binaraize
% CAM1_FOV_mask_plane2 = ~isnan(raw_image_plane2_CAM1);
% CAM2_FOV_mask_plane2 = ~isnan(raw_image_plane2_CAM2);
% 
% % Get combined FOV_mask
% FOV_mask_plane2 = CAM1_FOV_mask_plane2 + CAM2_FOV_mask_plane2;
% FOV_mask_plane2(FOV_mask_plane2 < 2) = 0;
% FOV_mask_plane2 = FOV_mask_plane2/2;
% 
% % Combined stereo image
% plane2_image = FOV_mask_plane2 .* (raw_image_plane2_CAM1 + raw_image_plane2_CAM2);
















