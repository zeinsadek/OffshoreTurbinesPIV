%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\sadek\Desktop\readimx-v2.1.9-win64');
addpath('C:\Users\sadek\Desktop\ZeinPIVCodes_Github\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
addpath('C:\Program Files\MATLAB\slanCM')
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
clc;
project_path   = 'F:\Offshore_PerspectiveCorrection_Compression_Test\FWF_Inline_PL1_AK12';
recording_name = 'FWF_I_PL1_AK12_LM50_A';
details        = namereader(recording_name);

% Image paths
perspective_path = fullfile(project_path, recording_name, 'CompressAvg_4x4');
% piv_path         = fullfile(project_path, recording_name, 'StereoPIV_MPd(2x32x32_50%ov)_GPU');

% Save paths
save_path = 'F:\Offshore_PerspectiveCorrection_Compression_Test\WaveTests';
paths     = savepaths(save_path, recording_name);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIND ALL AVAILABLE FRAMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% frames = commonframes(piv_path, perspective_path, paths.frame);
% frames.common = 1:1400;
N = 100;
frames.common = "B" + compose("%05d", 1:N);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WAVE DETECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
% if exist(paths.wave.initial, 'file')
%     fprintf('* Loading INITIAL WAVES from File\n')
%     waves = load(paths.wave.initial);
%     waves = waves.output;
% else
%     tic
%     waves = wavedetectionPIVXY(frames, perspective_path, details, paths.wave.initial);
%     toc
% end

tic
waves = wavedetectionPIVXY(frames, perspective_path, details, paths.wave.initial);
toc

%% Check Waves

% Plot
figure()
hold on
% for i = 1:1:waves.D
for i = 1:waves.D
    plot(waves.x, waves.wave_profiles(i,:))
    clear i
    axis equal
    xlim([-100, 100])
    ylim([-120, -80])
    pause(0.25)
end
hold off
axis equal
xlim([-100, 100])

disp(mean(diff(waves.x)))







