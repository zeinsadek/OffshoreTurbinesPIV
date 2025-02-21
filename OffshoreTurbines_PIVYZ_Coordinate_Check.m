%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\Zein\Desktop\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\Zein\Desktop\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
addpath('C:\Users\Zein\Desktop\PIV\Colormaps')
fprintf('All Paths Imported...\n\n')

%% Paths

PIV_path = "F:\PIV\FBT_PL2_AK12_1\FBT_PL2_AK12_LM50_A\StereoPIV_MPd(2x12x12_50%ov)_GPU";
perspective_path = "F:\PIV\FBT_PL2_AK12_1\FBT_PL2_AK12_LM50_A\ImageCorrection";
image_name = "B0001";

PIV = fullfile(PIV_path, strcat(image_name, '.vc7'));

data = readimx(char(PIV));

%% Load Single Image

names       = data.Frames{1,1}.ComponentNames;        
U0_index    = find(strcmp(names, 'U0'));
V0_index    = find(strcmp(names, 'V0'));
W0_index    = find(strcmp(names, 'W0'));

UF = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
VF = data.Frames{1,1}.Components{V0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{V0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{V0_index,1}.Scale.Offset;
WF = data.Frames{1,1}.Components{W0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{W0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{W0_index,1}.Scale.Offset;


% Add Image/Data Parameters to struct file.
nf = size(UF);
x = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
y = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
[X, Y] = meshgrid(x, y);

%%

UF(UF == 0) = nan;
VF(VF == 0) = nan;
WF(WF == 0) = nan;

figure()
t = tiledlayout(1,1);

% nexttile()
% contourf(X, Y, UF.', 100, 'linestyle', 'none')
% axis equal
% colorbar
% colormap coolwarm
% clim([-1,1])
% xlim([-100, 100])
% ylim([-120, 100])

% nexttile()
% contourf(X, Y, VF.', 100, 'linestyle', 'none')
% axis equal
% colorbar
% colormap coolwarm
% clim([-1,1])
% % xlim([-100, 100])
% % ylim([-120, 100])
 
nexttile()
contourf(-X, Y, WF.', 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-1.5,4.5])
xline(0)
% xlim([-100, 100])
% ylim([-120, 100])

%% Loop over a couple images to see rough means


inst = vector2matlab('F:\PIV\FBT_PL2_AK12_1\FBT_PL2_AK12_LM50_A\StereoPIV_MPd(2x12x12_50%ov)_GPU', 'F:\test.mat');

%%

u_mean = mean(inst.U, 3, 'omitnan');
v_mean = mean(inst.V, 3, 'omitnan');
w_mean = mean(inst.W, 3, 'omitnan');


v_mean(u_mean == 0) = nan;
w_mean(u_mean == 0) = nan;
u_mean(u_mean == 0) = nan;


figure()
t = tiledlayout(1,3);

nexttile()
contourf(-X, Y, u_mean.', 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-0.5,0.5])
% xlim([-100, 100])
% ylim([-120, 100])

nexttile()
contourf(-X, Y, v_mean.', 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-0.5,0.5])
% % xlim([-100, 100])
% % ylim([-120, 100])
 
nexttile()
contourf(-X, Y, w_mean.', 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-1.5,4.5])
xline(0)
% xlim([-100, 100])
% ylim([-120, 100])

%% Reassign to tunnel coordinates

X = -X;
Y = Y;

U = w_mean.';     
V = v_mean.';
W = u_mean.'; 

%%

figure()
t = tiledlayout(1,3);

nexttile()
contourf(X, Y, U, 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-1.5,4.5])
xlim([-100, 100])
ylim([-120, 100])

nexttile()
contourf(X, Y, V, 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-0.5,0.5])
xlim([-100, 100])
ylim([-120, 100])
 
nexttile()
contourf(X, Y, W, 100, 'linestyle', 'none')
axis equal
colorbar
colormap coolwarm
clim([-0.5,0.5])
xlim([-100, 100])
ylim([-120, 100])








