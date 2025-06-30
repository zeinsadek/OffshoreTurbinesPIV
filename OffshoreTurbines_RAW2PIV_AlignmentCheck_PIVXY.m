%%% Checking alignment of rectified images to PIV images by plotting ontop
%%% of each other;

%%

clc; clear; close all
addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
fprintf('All Paths Imported...\n\n')

% From the final cropped PIV open the corresponding raw image
caze = 'FWF_I_PL4_AK12_LM50_A';
frames = load(fullfile('H:\Offshore\frames', strcat(caze, '_FRAMES.mat')));
frames = frames.output;
PIV = matfile(fullfile('H:\Offshore\cropped\final', strcat(caze, '_FINAL_CROPPED.mat')));

common_frames = frames.common;

frame = 10;

%%

raw_path = fullfile(strcat('I:\FWF_AK12_Inline_PIVXY\FWF_Inline_PL4_AK12\', caze, '\ImageCorrection'), strcat(common_frames(frame), '.im7'));

% Try to grab image
fprintf('Loading RAW frame...\n')
raw = readimx(char(raw_path));

% Load both camera images
raw_image_CAM1 = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
raw_image_CAM2 = raw.Frames{3,1}.Components{1,1}.Planes{1,1};

% Get coordinates
nf = size(raw_image_CAM1);
RAW_x = raw.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*raw.Frames{1,1}.Grids.X + raw.Frames{1,1}.Scales.X.Offset;
RAW_y = raw.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*raw.Frames{1,1}.Grids.Y + raw.Frames{1,1}.Scales.Y.Offset;
[RAW_X, RAW_Y] = meshgrid(RAW_x, RAW_y);
RAW_X = -fliplr(RAW_X);
raw_image_CAM1 = fliplr(raw_image_CAM1.');
raw_image_CAM2 = fliplr(raw_image_CAM2.');

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
fprintf('Loaded and combined Stereo images!\n')


clear CAM1_FOV_mask CAM2_FOV_mask FOV_mask nf raw raw_image_CAM1 raw_image_CAM2 raw_path RAW_x RAW_y


%% Load corresponding instantaneous image

u = PIV.U(:,:,frame);
PIV_X = PIV.X;
PIV_Y = PIV.Y;

wave = PIV.waves(frame, :);
PIV_x = PIV_X(1,:);

%% Resize raw image to plot

RAW_image_resized = imresize(combined_image, size(u));
RAW_X_resized = imresize(RAW_X, size(u));
RAW_Y_resized = imresize(RAW_Y, size(u));

figure()
contourf(RAW_X_resized, RAW_Y_resized, RAW_image_resized, 100, 'linestyle', 'none')
colormap('Bone')
axis equal
colorbar
xlim([-100, 100])
ylim([-160, 100])

%% Plot together

figure();
hold on

% Plot RAW: resized
contourf(RAW_X_resized, RAW_Y_resized, RAW_image_resized / 25, 100, 'linestyle', 'none', 'FaceAlpha', 1.0);

% Plot RAW: full size
% contourf(RAW_X, RAW_Y, combined_image / 25, 100, 'linestyle', 'none', 'FaceAlpha', 1.0);


% Plot PIV
contourf(PIV_X, PIV_Y, u, 100, 'linestyle', 'none', 'FaceAlpha', 1.0);
colormap(gca, "parula")
clim(gca, [0 3])

% Plot wave
plot(PIV_x, wave, 'linewidth', 2, 'color', 'red')

hold off
axis equal
xlim([-100, 100])
ylim([-160, 100])











