%%% APS Stitching Figures

clear; close all; clc;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/OffshoreTurbines_Functions/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/colormaps')
fprintf('All Paths Imported...\n\n')

%%
stitch_path  = '/Volumes/ZeinResults/APS/stitch';
figure_folder = '/Volumes/ZeinResults/APS/figures';
no_waves = load(fullfile(stitch_path, 'FWF_I_AK0_STITCH.mat'));
LM50 = load(fullfile(stitch_path, 'FWF_I_AK12_LM50_STITCH.mat'));
LM33 = load(fullfile(stitch_path, 'FWF_I_AK12_LM33_STITCH.mat'));

no_waves = no_waves.stitch;
LM50 = LM50.stitch;
LM33 = LM33.stitch;

%% Plot ensemble averages

clc;
D = 150;
component = 'vw';
levels = 50;
vertline = 1.5385;

ax = figure();
tiledlayout(3,1,'TileSpacing','tight')

% No Waves
h(1) = nexttile();
contourf(no_waves.X/D, no_waves.Y/D, no_waves.(component), levels, 'linestyle', 'none')
xline(vertline, 'color', 'white', 'LineWidth', 2)
axis equal
title('$H = 0$', 'interpreter', 'latex')
xlim([0, 2.5])
ylim([-1.2, 0.55])
set(h(1),'XTick',[])

% LM50
h(2) = nexttile();
contourf(LM50.X/D, LM50.Y/D, LM50.(component), levels, 'linestyle', 'none')
xline(vertline, 'color', 'white', 'LineWidth', 2)
axis equal
title('$H = 1.0$', 'interpreter', 'latex')
xlim([0, 2.5])
ylim([-1.2, 0.55])
set(h(2),'XTick',[])
ylabel('$y / D$', 'interpreter', 'latex')

% LM33
h(3) = nexttile();
contourf(LM33.X/D, LM33.Y/D, LM33.(component), levels, 'linestyle', 'none')
xline(vertline, 'color', 'white', 'LineWidth', 2)
axis equal
title('$H = 1.5$', 'interpreter', 'latex')
xlim([0, 2.5])
ylim([-1.2, 0.55])
xlabel('$x / D$', 'interpreter', 'latex')

% Colorbar
set(h, 'Colormap', coolwarm, 'CLim', [-2E-3, 1E-3]) 
cbh = colorbar(h(end)); 
cbh.Layout.Tile = 'east';
cbh.Label.String = '$\bar{vw} / {u^2}_{\infty}$';
cbh.Label.Interpreter = 'latex';
cbh.Label.FontSize = 16;

% exportgraphics(ax, fullfile(figure_folder, 'vw_ensemble_APS.png'), 'Resolution', 200)

%%

x = LM50_