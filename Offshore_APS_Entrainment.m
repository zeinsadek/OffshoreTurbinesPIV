%%% APS Stitching Figures

clear; close all; clc;
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/OffshoreTurbines_Functions/');
addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/colormaps')
fprintf('All Paths Imported...\n\n')

%%
stitch_path  = '/Users/zeinsadek/Desktop/APS2024_Data/stitch';
figure_folder = '/Users/zeinsadek/Desktop/APS2024_Data/figures';
no_waves = load(fullfile(stitch_path, 'FWF_I_AK0_STITCH.mat'));
LM50 = load(fullfile(stitch_path, 'FWF_I_AK12_LM50_STITCH.mat'));
LM33 = load(fullfile(stitch_path, 'FWF_I_AK12_LM33_STITCH.mat'));

no_waves = no_waves.stitch;
LM50 = LM50.stitch;
LM33 = LM33.stitch;

%% Test Entrainment

D = 150;

linewidth = 2;
% No Waves
uv_x_no_waves = mean(no_waves.('uv'), 2, 'omitnan');
u_x_no_waves  = mean(no_waves.('u'), 2, 'omitnan');
entrainment_profile_no_waves = uv_x_no_waves .* u_x_no_waves;

% No Waves
uv_x_LM50 = mean(LM50.('uv'), 2, 'omitnan');
u_x_LM50  = mean(LM50.('u'), 2, 'omitnan');
entrainment_profile_LM50 = uv_x_LM50 .* u_x_LM50;

% No Waves
uv_x_LM33 = mean(LM33.('uv'), 2, 'omitnan');
u_x_LM33  = mean(LM33.('u'), 2, 'omitnan');
entrainment_profile_LM33 = uv_x_LM33 .* u_x_LM33;


ax = figure(position = [300,300,400,600]);
hold on
plot(entrainment_profile_no_waves, no_waves.('Y')(:,1)/D, 'DisplayName', 'No Waves', 'LineWidth', linewidth)
plot(entrainment_profile_LM50, LM50.('Y')(:,1)/D, 'DisplayName', 'H = 1.0', 'LineWidth', linewidth)
plot(entrainment_profile_LM33, LM33.('Y')(:,1)/D, 'DisplayName', 'H = 1.5', 'LineWidth', linewidth)
yline(-0.5, 'HandleVisibility', 'off');
yline(0.5, 'HandleVisibility', 'off')
hold off
legend('location', 'southeast')
ylim([-0.8 0.6])
xlabel("$< \bar{u'v'} > <\bar{u}>$", 'interpreter', 'latex')
ylabel("$y / D$", "Interpreter", "latex")

% exportgraphics(ax, fullfile(figure_folder, "Entrainment_Profiles.png"), 'Resolution', 200)

%% Bar Chart Representation

[~, top_idx_no_waves] = min(abs(no_waves.('Y')(:,1)/D - 0.5));
[~, bottom_idx_no_waves] = min(abs(no_waves.('Y')(:,1)/D + 0.5));

[~, top_idx_LM50] = min(abs(LM50.('Y')(:,1)/D - 0.5));
[~, bottom_idx_LM50] = min(abs(LM50.('Y')(:,1)/D + 0.5));

[~, top_idx_LM33] = min(abs(LM33.('Y')(:,1)/D - 0.5));
[~, bottom_idx_LM33] = min(abs(LM33.('Y')(:,1)/D + 0.5));

entrainment_no_waves = (entrainment_profile_no_waves(top_idx_no_waves) - entrainment_profile_no_waves(bottom_idx_no_waves)) / (D*1E-3);
entrainment_LM50 = (entrainment_profile_LM50(top_idx_LM50) - entrainment_profile_LM50(bottom_idx_LM50)) / (D*1E-3);
entrainment_LM33 = (entrainment_profile_LM33(top_idx_LM33) - entrainment_profile_LM33(bottom_idx_LM33)) / (D*1E-3);


names = ["No Waves", "H = 1.0", "H = 1.5"];
ax = figure();
b = bar(names, [entrainment_no_waves/entrainment_no_waves, entrainment_LM50/entrainment_no_waves, entrainment_LM33/entrainment_no_waves]);
b(1).Labels = b(1).YData;
ylim([0, 1.2])

b.FaceColor = 'flat';
b.CData(1,:) = [0.00, 0.44, 0.74];
b.CData(2,:) = [0.85, 0.32, 0.10];
b.CData(3,:) = [0.92, 0.69, 0.12];

exportgraphics(ax, fullfile(figure_folder, "Entrainment_Bar_Chart.png"), 'Resolution', 200)










