%% Offshore Turbines: Phase averaging single plane test

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
fprintf('All Paths Imported...\n\n')

matfile_path = 'H:\Offshore';
caze = 'FWF_I_PL4_AK12_LM33';
details = namereader(caze);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
data = matfile(fullfile(matfile_path, 'cropped', 'combined', strcat(caze, '_COMBINED.mat')));

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SHIFT ORIGIN TO TURBINE AND WATER LEVEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Shift zero in x to the turbine based on the plane
x_shift = - (130 + 200 * (details.plane - 1));

% Load offset for each plane
y_shift = load(fullfile(matfile_path, 'waves', 'still_surface', sprintf('PL%1.0f_Still_Surface_Calibration.mat', details.plane)));
y_shift = y_shift.waves.offset;

% Shift coordinates
X = data.X - x_shift;
Y = data.Y - y_shift;
x = X(1,:);
y = Y(:,1);


% Plot to check
figure('color', 'white')
contourf(X, Y, data.U(:,:,1))
axis equal
xlim([0, max(x)])
title(sprintf('Plane %1.0f', details.plane));


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET WAVE PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Turbine diameter
D = 150;

% Wave length
wavelength = details.wavelength * D;

% Wave amplitude
amplitude = (wavelength * details.steepness) / (2 * pi);

% Phase shifts
phase_shifts = [0, (1/4 * wavelength), (1/2 * wavelength), (3/4 * wavelength)];

% Reference wave equation
% reference_wave = amplitude * cos(2 * pi * ((x - phase_shift) / wavelength));


% Plot to check
% clc; close all; figure('color', 'white')
% hold on
% contourf(X, Y, data.U(:,:,1), 100, 'linestyle', 'none', 'HandleVisibility', 'off')
% for i = 1:length(phase_shifts)
%     reference_wave = amplitude * cos(2 * pi * ((x - phase_shifts(i)) / wavelength));
%     plot(x, reference_wave, 'linewidth', 3, 'displayname', sprintf('Phase %1.0f', i))
%     clear i
% end
% hold off
% axis equal
% xlim([0, max(x)])
% legend('location', 'northwest')


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIME-BASED PHASE AVERAGING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Which point to probe
phase_average_index = 150;

% Tolerance for phase fits
phase_tolerance = 0.02 * wavelength;

% Phase fit function
% Only fitting phase shift
cos_fit = @(b, x) 0.75 * amplitude * cos(2 * pi * (x - b(1)) / wavelength);
% normalized_cos_fit = @(b, x) cos(2 * pi * (x - b(1)) / wavelength);

% Fittinfg for amplitude, phase shift, and vertical offset
% cos_fit = @(b, x) b(1) * cos(2 * pi * (x - b(2)) / wavelength) + b(3);

reference_wave = cos_fit(0, x);
reference_curvature = gradient(reference_wave, x);

% Crop based on plane
if details.plane == 1
    cutoff = -20;
elseif details.plane == 4
    cutoff = 50;
else
    cutoff = -100;
end

% Shift cutoff
cutoff = cutoff - x_shift;
[~, cutoff_index] = min(abs(x - cutoff));

% %% Time series
wave_time_series = data.waves(:, phase_average_index) - y_shift;
wave_time_series_gradient = gradient(wave_time_series);
wave_time_series_gradient_sign = sign(gradient(wave_time_series));

% Tolerance of phase fit in mm
tolerance = 2; % mm
% slope_tolerance = 0.5;  % Adjust based on trial (units = wave height / mm)

% Colors per phase
colors = {'red', 'green', 'blue', 'magenta'};

% Create array of indicies
frame_indicies = 1:data.D;
frame_indicies = frame_indicies.';

% Where phase average indicies will be saves
phase_average_indicies = zeros(1,data.D);

% Loop and plot 
clc; close all; figure()
hold on

% Plot wave time series
plot(frame_indicies, wave_time_series, 'color', 'black')
scatter(frame_indicies, wave_time_series, 10, 'filled', 'markerfacecolor', 'black')

% Loop through phases
for i = 1:4

    % Compute entire reference_wave
    reference_wave = cos_fit(phase_shifts(i), x);

    % Compute sign of slope (to align phases 2 and 4 properly)
    reference_wave_gradient = gradient(reference_wave);
    reference_wave_gradient_sign = sign(reference_wave_gradient);

    % Extract specific probe point value
    reference_point = reference_wave(phase_average_index);
    reference_point_gradient = reference_wave_gradient(phase_average_index);
    reference_gradient_sign = reference_wave_gradient_sign(phase_average_index);

    % Creat mask to match wave height and wave slope
    phase_mask = wave_time_series > (reference_point - tolerance) & wave_time_series < (reference_point + tolerance) & wave_time_series_gradient_sign == -reference_gradient_sign;

    % phase_mask = wave_time_series > (reference_point - tolerance) & wave_time_series < (reference_point + tolerance) & abs(wave_time_series_gradient(phase_average_index) - reference_point_gradient) < slope_tolerance;
    % phase_mask = ...
    %     abs(wave_time_series - reference_point) < tolerance & ...
    %     abs(wave_time_series_gradient - reference_point_gradient) < slope_tolerance;

    % How many images per phase
    images_per_phase = length(frame_indicies(phase_mask));
    fprintf('%4.0f images binned into Phase %1.0f\n', images_per_phase, i)

    % Save to array 
    phase_average_indicies(phase_mask) = i;

    % Plot points who only match specific phase
    scatter(frame_indicies(phase_mask), wave_time_series(phase_mask), 30, 'filled', 'MarkerFaceColor', colors{i})

    % Plot tolerance bands for each phase
    yline(reference_point, 'color', colors{i})
    yline(reference_point + tolerance, 'color', colors{i}, 'linestyle', '--')
    yline(reference_point - tolerance, 'color', colors{i}, 'linestyle', '--')

    % Fill area in between tolerance bands for aesthetic
    tmpY1 = ones(size(frame_indicies)) * (reference_point + tolerance);
    tmpY2 = ones(size(frame_indicies)) * (reference_point - tolerance);
    fill([frame_indicies.', fliplr(frame_indicies.')], [tmpY1.', fliplr(tmpY2.')], colors{i}, 'FaceAlpha', 0.2, 'EdgeColor', 'none')


end
hold off
xlim([0, data.D])
ylim([-20, 20])


clear colors cutoff cutoff_index frame_indicies i images_per_phase indicies normalized_cos_fit phase_mask phase_tolerance reference_curvature
clear reference_gradient_sign reference_point reference_point_gradient reference_wave reference_wave_gradient reference_wave_gradient_sign
clear tmpY1 tmpY2 tolerance wave_time_series wave_time_series gradient


%%% Plot detected phases
figure()
tiledlayout(4,1)

for i = 1:4
    fitted_phase_indicies = find(phase_average_indicies == i);
    h(i) = nexttile;
    hold on
    for w = 1:length(fitted_phase_indicies)
        plot(x, data.waves(fitted_phase_indicies(w), :) - y_shift, 'color', 'black')
    end
    plot(x, cos_fit(phase_shifts(i), x), 'color', 'red', 'linewidth', 2)
    xline(x(phase_average_index), 'linestyle', '--')
    hold off
    title(sprintf('Phase %1.0f', i))
    axis equal
end

linkaxes(h, 'xy')

clear h i w 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPUTE PHASE AVERAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; close all
% Loop through phases
for phase = 1:4

    % Load which frames belong to which phase
    clc; fprintf('Processing Phase %1.0f\n', phase)
    fitted_phases = find(phase_average_indicies == phase);

    % Prepare temporary structure to hold them
    tmp.X = X;
    tmp.Y = Y;

    tmp.U = nan(size(X, 1), size(X, 2), length(fitted_phases));
    tmp.V = nan(size(X, 1), size(X, 2), length(fitted_phases));
    tmp.W = nan(size(X, 1), size(X, 2), length(fitted_phases));
    tmp.waves = nan(length(fitted_phases), size(X, 2));
    tmp.D = length(fitted_phases);

    % Add respective frames to array
    for i = 1:length(fitted_phases)
        tmp.waves(i,:) = data.waves(fitted_phases(i), :) - y_shift;
        tmp.U(:,:,i) = data.U(:,:,fitted_phases(i));
        tmp.V(:,:,i) = data.V(:,:,fitted_phases(i));
        tmp.W(:,:,i) = data.W(:,:,fitted_phases(i));
    end

    % Compute actual phase average
    phase_average = data2meansphasePIVXY(tmp);

    % Save to final output
    output(phase) = phase_average;

    % Over-write the x coordinate
    output(phase).X = data.X;
end


clear phase fitted_phases i phase_average_tmp


%% Plot a quantity across all 4 phases

component = 'u';

figure()
tiledlayout(1,4)
for phase = 1:4
    h(phase) = nexttile;
    hold on
    contourf(output(phase).X, output(phase).Y, output(phase).(component), 100, 'linestyle', 'none')
    plot(output(phase).X(1,:), output(phase).max_wave, 'LineWidth', 2, 'color', 'red')
    hold off
    axis equal
    colorbar()
    clim([0.5, 3])
end

linkaxes(h, 'xy')

clear component h phase

%% Save to matfile

save_dir = 'H:\Offshore\phase_average\WESC';
save_name = strcat(caze, '_PHASE_AVERAGE.mat');

clc; fprintf('Saving to Matfile...\n')
save(fullfile(save_dir, save_name), 'output');
fprintf('Done saving to Matfile!\n')




%% Functions

function output = data2meansphasePIVXY(data)

    D = data.D;
    fprintf('D Check = %d! \n', D)

    inst_U  = data.U;
    inst_V  = data.V;
    inst_W  = data.W;
    X       = data.X;
    Y       = data.Y;


    % Calculate Velocity Means
    output.u = mean(inst_U, 3, 'omitnan');
    output.v = mean(inst_V, 3, 'omitnan');
    output.w = mean(inst_W, 3, 'omitnan');

    % Create Reynolds Stress Objects
    uu_p = zeros(size(inst_U));
    vv_p = zeros(size(inst_U));
    ww_p = zeros(size(inst_U));
    
    uv_p = zeros(size(inst_U));
    uw_p = zeros(size(inst_U));
    vw_p = zeros(size(inst_U));

    % Loop Through Each Frame in Struct.
    fprintf('\n<data2meansPIVXY> PROGRESS: \n');
    for frame_number = 1:D
        
        % Print Progress.
        progressbarText(frame_number/D);
        
        % Instantaneous Fluctuations.
        u_pi = inst_U(:, :, frame_number) - output.u;
        v_pi = inst_V(:, :, frame_number) - output.v;
        w_pi = inst_W(:, :, frame_number) - output.w;

        % Instantaneous Stresses.
        uu_pi = u_pi.*u_pi;
        vv_pi = v_pi.*v_pi;
        ww_pi = w_pi.*w_pi;

        uv_pi = u_pi.*v_pi;
        uw_pi = u_pi.*w_pi;
        vw_pi = v_pi.*w_pi;

        % Array of Mean Stresses.
        uu_p(:, :, frame_number) = uu_pi;
        vv_p(:, :, frame_number) = vv_pi;
        ww_p(:, :, frame_number) = ww_pi;

        uv_p(:, :, frame_number) = uv_pi;
        uw_p(:, :, frame_number) = uw_pi;
        vw_p(:, :, frame_number) = vw_pi;

    end

    % Mean Stresses.
    output.uu = mean(uu_p, 3, 'omitnan');
    output.vv = mean(vv_p, 3, 'omitnan');
    output.ww = mean(ww_p, 3, 'omitnan');

    output.uv = mean(uv_p, 3, 'omitnan');
    output.uw = mean(uw_p, 3, 'omitnan');
    output.vw = mean(vw_p, 3, 'omitnan');
    
    output.X = X;
    output.Y = Y;
    output.D = D;

    % Save waves for convenience
    output.max_wave = max(data.waves, [], 1);

    % Crop quantities below the wave
    output.u(output.Y < output.max_wave) = nan;
    output.v(output.Y < output.max_wave) = nan;
    output.w(output.Y < output.max_wave) = nan;

    output.uu(output.Y < output.max_wave) = nan;
    output.uv(output.Y < output.max_wave) = nan;
    output.uw(output.Y < output.max_wave) = nan;

    output.uv(output.Y < output.max_wave) = nan;
    output.uw(output.Y < output.max_wave) = nan;
    output.vw(output.Y < output.max_wave) = nan;

    
    % Save Matlab File.
    clc; fprintf('<data2meansPIVXY> Done Computing! \n')
end