%% Measuring where the still water is per plane
% Zein Sadek
% Offshore Turbines, PSU

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
fprintf('All Paths Imported...\n\n')

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data paths
clc;
plane = 1;

if ismember(plane, [1,2])
    project_path = strcat('G:\FWF_AK12_Inline_PIVXY\FWF_Inline_PL', num2str(plane), '_AK12');
elseif ismember(plane, [3,4])
    project_path = strcat('I:\FWF_AK12_Inline_PIVXY\FWF_Inline_PL', num2str(plane), '_AK12');
end

% Image paths
perspective_path = fullfile(project_path, 'Still_Surface_Calibration\ImageCorrection');

% Save paths
save_path = 'H:\Offshore\waves\still_surface';
save_name = strcat('PL', num2str(plane), '_Still_Surface_Calibration.mat');
out_path  = fullfile(save_path, save_name);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DETECT WAVES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Frames to look at
for f = 1:10
    frames.common(f) = string(strcat('B', num2str(f,'%05.f')));
    clear f
end

% Plane details
details.plane = plane;

% Wave detection
clc;
waves = stillsurfacewavedetectionPIVXY(frames, perspective_path, details, out_path);

% Plot and clean waves
if plane == 1
    cutoff = -20;
elseif plane == 4
    cutoff = 50;
else
    cutoff = -100;
end

% Plot
clc; figure()
hold on
for i = 1:5:waves.D

    % Select wave
    wave = waves.wave_profiles(i,:);

    % Look at specific region of data
    x = waves.x;
    [~, cutoff_index] = min(abs(x - cutoff));
    
    % Crop differently based on plane
    if ismember(plane, [1,2,3])
        wave(cutoff_index:end) = fillmissing(filloutliers(wave(cutoff_index:end), nan), 'nearest');
        waves.wave_profiles(i,:) = wave;
    else
        wave(1:cutoff_index) = fillmissing(filloutliers(wave(1:cutoff_index), nan), 'nearest');
        waves.wave_profiles(i,:) = wave;
    end

    plot(x, wave)
    clear i
end
hold off
axis equal
xlim([-100, 100])

%% Compute and save scalar offset
still_surface_offset = mean(waves.wave_profiles, 'all', 'omitnan');
waves.offset = still_surface_offset;
fprintf('Plane %1.0f Still Surface is at %2.5f mm\n\n', plane, still_surface_offset)

fprintf('\n<stillsurfacecalibration> Saving Data to File... \n');
save(out_path, 'waves');
fprintf('\n<stillsurfacecalibration> Data Save Complete \n')














