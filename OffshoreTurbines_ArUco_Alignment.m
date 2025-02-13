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
% Inputs
planes   = 1:4;
mat_path = '/Users/zeinsadek/Desktop/Experiments/PIV/Processing/OffshoreTurbines/Calibration/PIVXY_Stitching';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = planes
    fprintf("Loading Plane %s\n", num2str(i))
    name = strcat('Plane', num2str(i));
    path = fullfile(mat_path, name, strcat(name, '_Stitching.mat'));

    tmp = load(path);
    tmp = tmp.output;
    data(i) = tmp;
end

clear tmp

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT ALL IMAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ax = figure();
tiledlayout(1, 4, 'Padding', 'tight')

for i = planes
    nexttile
    tmp = data(i).combined - 20;
    tmp(tmp < 0) = 0;
    contourf(data(i).X, data(i).Y, tmp, 100, 'linestyle', 'none')
    axis equal
    % xlim([-125, 125])
    % ylim([-110, 110])
    xline(-100, 'color', 'red', 'linewidth', 3)
    xline(100, 'color', 'red', 'linewidth', 3)
    title(strcat('Plane', {' '}, num2str(i)))
    colormap('gray')
    clim([0, 10])
end

%% Compare Disparities

clc;
for i = planes
    fprintf("Plane %1.0f Disparity = %3.2f\n", i, data(i).d * data(i).mm_per_pix);   
end

%% crop images to smallest number of rows

% image_rows = [];

for i = planes
    img_size = size(data(i).combined);
    image_rows(i) = img_size(1);
end

row_crop = min(image_rows, [], 'all');


%% Stitch Plane 1 and 2


plane1_image = data(1).combined;
plane2_image = data(2).combined;

% Allow for roation but only apply the translations
transformation_matrix = imregcorr(plane2_image, plane1_image);
x_shift = transformation_matrix.Translation(1);
y_shift = transformation_matrix.Translation(2);

% image_size = imref2d(size(plane2_image));
% test = imwarp(plane2_image, transformation_matrix, "OutputView", "full");

%%
% translate image and padd with zeros
test = imtranslate(plane2_image, [x_shift, 0], "OutputView", "full");
disp(size(test))

% need to figure out how to also extend the meshgrid



figure()
tiledlayout(1,2)
nexttile
contourf(plane2_image, 100, 'linestyle', 'none')
axis equal

nexttile
contourf(test, 100, 'linestyle', 'none')
axis equal



%%

figure()
contourf(data(2).X(1:row_crop,:), data(2).Y(1:row_crop,:), test)
axis equal

%% how to add images

%%
% try padding slid image with zeros in order to add
aligned_image = plane2_image + imwarp(plane1_image, transformation_matrix, "OutputView", image_size);


