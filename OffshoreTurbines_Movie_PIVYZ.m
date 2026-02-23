%%% Video Generator for Time-Resolved PIV Data
% Zein Sadek
% PSU + Oldenburg

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\Zein\Desktop\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\Zein\Desktop\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
addpath('C:\Users\Zein\Desktop\PIV\Colormaps')
addpath('C:\Users\Zein\Desktop\PIV\Inpaint_nans');
fprintf("All Paths Imported...\n\n");

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% Data paths
save_folder = 'F:\CrossplaneResults';
recording   = "FBT_PL2";
data_path   = "F:\CrossplaneResults\cropped\FBT_PL2_AK12_LM50_A_CROPPED.mat";
data        = load(data_path);
% data        = data.output;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERATE MOVIE (u)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_images = 100;
FPS        = 3;
levels     = 300;

v = VideoWriter(fullfile(save_folder, strcat(recording, '_U_MOVIE')),'MPEG-4');
v.FrameRate = FPS;
open(v)

clc;
for i = 1:num_images
    progressbarText(i/num_images);
    ax = figure('Visible', 'off','units','pixels','position',[0 0 1440 1080]);
    % Remove Ticks
    set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);

    % Crop
    X = data.X;
    Y = data.Y;
    wave = data.waves(i,:);
    U = data.U(:,:,i);
    % V = data.V(:,:,i);
    % W = data.W(:,:,i);

    hold on
    colormap(ax, jet)
    contourf(X, Y, U, levels, 'linestyle', 'none')
    plot(X(1,:), wave, 'color', 'black', 'linewidth', 3)
    axis equal
    axis tight
    xlim([-100,100])
    ylim([-150,100])
    clim([-1.5, 4])
    c = colorbar();
    hold off

    frame = getframe(ax);
    close all
    writeVideo(v,frame);
end
close(v);












