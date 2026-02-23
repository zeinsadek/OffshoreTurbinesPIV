%% Stitching the ensemble mean of the 4 planes of the XY PIV of Offshore Turbines
% Zein Sadek
% Offshore Turbines, PSU

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
matfile_path = 'H:\Offshore';
arrangement = 'FWF_I';
wave_type   = 'AK12_LM50';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA AND OFFSETS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for plane = 1:4

    % Load PIV data
    PIV_caze    = sprintf('%s_PL%1.0f_%s', arrangement, plane, wave_type);
    PIV_tmp     = load(fullfile(matfile_path, 'means', strcat(PIV_caze, '_MEANS.mat')));
    data(plane) = PIV_tmp.output;

    % Load still surface offset
    SS_caze = sprintf('PL%1.0f_Still_Surface_Calibration', plane);
    SS_tmp  = load(fullfile(matfile_path, 'waves\still_surface', strcat(SS_caze, '.mat')));
    offsets(plane) = SS_tmp.waves.offset;
end

clear PIV_tmp PIV_caze SS_caze SS_tmp plane

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST WITHOUT BLENDING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

component = 'u';
center2center = 160;

clc; figure()
hold on
for plane = 1:4
    u = data(plane).(component);
    max_wave_profile = max(data(plane).Waves, [], 1);
    u(data(plane).Y < max_wave_profile) = nan;

    % The center-to-center shift between planes is 160mm
    contourf(data(plane).X + center2center * plane, data(plane).Y - offsets(plane), u, 100, 'linestyle', 'none')
    plot(data(plane).X(1,:) + center2center * plane, max_wave_profile - offsets(plane), 'color', 'red', 'linewidth', 2)

    clear u max_wave_profile plane
end
hold off
axis equal
ylim([-60, 200])


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BLENDING: INTERPOLATE ONTO COMMON GRID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Interpolate all planes onto a the same grid. Using PL1 for this
interpolate_onto_plane = 1;
Plane1_X = data(interpolate_onto_plane).X;
Plane1_Y = data(interpolate_onto_plane).Y;
Plane1_x = Plane1_X(1,:);
Plane1_y = Plane1_Y(:,1);

% Everything gets zeroed in Y here
clc;
components = {'u', 'v', 'w', 'uu', 'vv', 'ww', 'uv', 'uw', 'vw'};
for plane = 1:4

    % Where to fill in nans for wave
    if plane == 1
        cutoff = -20;
    elseif plane == 4
        cutoff = 50;
    else
        cutoff = -100;
    end
    [~, cutoff_index] = min(abs(Plane1_x - cutoff));

    % Interpolate velocity/stresses
    for c = 1:length(components)
        component = components{c};
        interpolated_data(plane).(component) = interp2(data(plane).X, data(plane).Y - offsets(plane), data(plane).(component), Plane1_X, Plane1_Y - offsets(interpolate_onto_plane));
    end

    % Interpolate waves
    for w = 1:length(data(plane).Waves)
        interpolated_data(plane).Waves(w,:) = interp1(data(plane).X(1,:), data(plane).Waves(w,:) - offsets(plane), Plane1_x);

        % Fill in any nans from interpolating
        if plane == 1
            interpolated_data(plane).Waves(w,cutoff_index:end) = fillmissing(interpolated_data(plane).Waves(w,cutoff_index:end), 'linear');
        elseif plane == 4
            interpolated_data(plane).Waves(w,1:cutoff_index) = fillmissing(interpolated_data(plane).Waves(w,1:cutoff_index), 'linear');
        else
            interpolated_data(plane).Waves(w,:) = fillmissing(interpolated_data(plane).Waves(w,:), 'linear');
        end

    end

    % Save coordinates
    interpolated_data(plane).X = Plane1_X;
    interpolated_data(plane).Y = Plane1_Y - offsets(interpolate_onto_plane);
    interpolated_data(plane).D = data(plane).D;
end

clear c component cutoff cutoff_index plane Plane1_X Plane1_x Plane1_Y Plane1_y w interpolate_onto_plane

%% Check

center2center = 160;
component = 'u';

clc; figure()
hold on
for plane = 1:4
    u = interpolated_data(plane).(component);
    max_wave_profile = max(interpolated_data(plane).Waves, [], 1);
    u(interpolated_data(plane).Y < max_wave_profile) = nan;

    % The center-to-center shift between planes is 160mm
    contourf(interpolated_data(plane).X + center2center * plane, interpolated_data(plane).Y + 200 * plane, u, 100, 'linestyle', 'none')
    plot(interpolated_data(plane).X(1,:) + center2center * plane, max_wave_profile + 200 * plane, 'color', 'red', 'linewidth', 2)

    xline(-100 + center2center * (plane))
    xline(100 + center2center * (plane))

    clear u max_wave_profile plane
end
hold off
axis equal
% ylim([0, 200])
colorbar()

clear component


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BLENDING: SHIFTING AND BLURRING EDGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dx = mean(diff(data(1).X(1,:)));
[imageHeight, imageWidth] = size(interpolated_data(1).X);
overlap = round(40 / dx);

for plane = 1:4
    for c = 1:length(components)

        % Load data
        component = components{c};
        tmp = interpolated_data(plane).(component);
    
        % Blur edges of data
        fadeMask = ones(imageHeight, imageWidth);
        fadeMask(:, 1:overlap) = repmat(linspace(0, 1, overlap), imageHeight, 1);
        fadeMask(:, end - overlap + 1:end) = repmat(linspace(1, 0, overlap), imageHeight, 1);
        tmp = tmp .* fadeMask;
    
        % Zero Pads
        leftZeroPad  = zeros(imageHeight, ((plane - 1) * (imageWidth - overlap)));
        rightZeroPad = zeros(imageHeight, ((4 - plane) * (imageWidth - overlap)));
        
        % Padded images
        padded_frames(plane).(component) = horzcat(leftZeroPad, tmp, rightZeroPad);

    end
end
clear plane c tmp fadeMask leftZeroPad rightZeroPad


% Extend coordinates
X = interpolated_data(1).X;
X = X - min(X, [], 'all');
x  = X(1,:);
Y = interpolated_data(1).Y;
extendedY = horzcat(Y, Y, Y, Y(:, 1:end - 3 * overlap));
extendedX = horzcat(X, X + 1*x(end), X + 2*x(end), X(:, 1:end - 3 * overlap) + 3*x(end));

%%% Stitching max wave profile
for plane = 1:4
    max_wave_profile = max(interpolated_data(plane).Waves, [], 1);

    % Pad to global stitched coordinates
    left_pad_len  = (plane - 1) * (imageWidth - overlap);
    right_pad_len = (4 - plane) * (imageWidth - overlap);
    padded_wave = [nan(1, left_pad_len), max_wave_profile, nan(1, right_pad_len)];
    max_wave(plane, :) = padded_wave;
end

% Combine all planes by taking max at each X
stitched.max_wave = max(max_wave, [], 1, 'omitnan');


% Join all the padded frames
[~, vertical_cutoff] = min(abs(extendedY(:,1) - 200));
for c = 1:length(components)
    component = components{c};
    tmp = padded_frames(1).(component) + padded_frames(2).(component) + padded_frames(3).(component) + padded_frames(4).(component);

    % Flatten the top of frame
    stitched.(component) = tmp(vertical_cutoff:end, :);
end

% Flatten the top of frame
extendedY = extendedY(vertical_cutoff:end, :);
extendedX = extendedX(vertical_cutoff:end, :);

% Save coordinates
stitched.X = extendedX;
stitched.Y = extendedY;

clear c component dx imageHeight imageWidth overlap padded_frames tmp vertical_cutoff 
clear x X Y left_pad_len max_wave_profile plane right_pad_len max_wave


%%% Brute force fill in nan columns from interpolating: 
% There is a pure column of nans at column 556 + 657 until about row 270
for c = 1:length(components)
    component = components{c};
    tmp = stitched.(component);
    % tmp(1:270, 554:558) = fillmissing(tmp(1:270, 554:558), 'linear');
    tmp(1:270, 656:658) = fillmissing(tmp(1:270, 656:658), 'linear', 2);
    stitched.(component) = tmp;

    clear c component tmp
end

%%% Save a wave-cropped version
for c = 1:length(components)
    component = components{c};
    max_wave_profile = stitched.max_wave;
    tmp = stitched.(component);
    tmp(extendedY < max_wave_profile) = nan;

    cropped_stitched.(component) = tmp;
end

% Save wave
cropped_stitched.max_wave = stitched.max_wave;

% Save coordinates
cropped_stitched.X = extendedX;
cropped_stitched.Y = extendedY;

clear c component max_wave_profile tmp

%% Final stitch

% Turbine diameter in mm
D = 150;

% Hub height in mm
hub_height = 117;

figure()
hold on
contourf(cropped_stitched.X / D, cropped_stitched.Y / D, cropped_stitched.u, 100, 'linestyle', 'none')
plot(cropped_stitched.X(1,:) / D, cropped_stitched.max_wave / D, 'color', 'red', 'linewidth', 2)
hold off
axis equal
colorbar()
ylim([-60 / 150, 200 / 150])
xlim([-10 / 150, 5])

yline(hub_height/D)
yline(hub_height/D + 1/2, 'linestyle', '--')
yline(hub_height/D - 1/2, 'linestyle', '--')

%% Save to matfile

save_name = strcat(arrangement, '_', wave_type, '_ENSEMBLE_STITCHED.mat');
save_dir  = fullfile(matfile_path, 'stitched', 'ensemble');

output.uncropped = stitched;
output.cropped   = cropped_stitched;

save(fullfile(save_dir, save_name), 'output');
clc; fprintf("Saved %s!\n", save_name)


%% Phase average







