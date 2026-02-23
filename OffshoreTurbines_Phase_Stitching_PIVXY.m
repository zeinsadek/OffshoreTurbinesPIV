%% Stitching the ensemble mean of the 4 planes of the XY PIV of Offshore Turbines
% Zein Sadek
% Offshore Turbines, PSU

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
matfile_path = 'H:\Offshore';
arrangement = 'FWF_I';
wave_type   = 'AK12_LM33';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA AND OFFSETS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for plane = 1:4

    % Load PIV data
    PIV_caze    = sprintf('%s_PL%1.0f_%s', arrangement, plane, wave_type);
    PIV_tmp     = load(fullfile(matfile_path, 'phase_average/WESC', strcat(PIV_caze, '_PHASE_AVERAGE.mat')));

    PIV_tmp = PIV_tmp.output;

    for phase = 1:4
        data(plane, phase) = PIV_tmp(phase);
    end
end

clear PIV_tmp PIV_caze SS_caze SS_tmp plane

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST WITHOUT BLENDING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

phase = 4;
component = 'u';
center2center = 160;

clc; figure()
hold on
for plane = 1:4
    u = data(plane, phase).(component);

    % The center-to-center shift between planes is 160mm
    contourf(data(plane, phase).X + center2center * plane, data(plane, phase).Y, u, 100, 'linestyle', 'none')
    plot(data(plane, phase).X(1,:) + center2center * plane, data(plane, phase).max_wave, 'color', 'red', 'linewidth', 2)

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
Plane1_X = data(interpolate_onto_plane, 1).X;
Plane1_Y = data(interpolate_onto_plane,1).Y;
Plane1_x = Plane1_X(1,:);
Plane1_y = Plane1_Y(:,1);

% Everything gets zeroed in Y here
clc;
components = {'u', 'v', 'w', 'uu', 'vv', 'ww', 'uv', 'uw', 'vw'};

for phase = 1:4
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
            interpolated_data(plane, phase).(component) = interp2(data(plane, phase).X, data(plane, phase).Y, data(plane, phase).(component), Plane1_X, Plane1_Y);
        end
    
        % Interpolate max wave
        interpolated_data(plane, phase).max_wave = interp1(data(plane, phase).X(1,:), data(plane, phase).max_wave, Plane1_x);
    
        % Save coordinates
        interpolated_data(plane, phase).X = Plane1_X;
        interpolated_data(plane, phase).Y = Plane1_Y;
        interpolated_data(plane, phase).D = data(plane).D;
    end
end

clear c component cutoff cutoff_index plane Plane1_X Plane1_x Plane1_Y Plane1_y w interpolate_onto_plane

%% Check

center2center = 160;
component = 'u';
phase = 1;

clc; figure()
hold on
for plane = 1:4
    u = interpolated_data(plane, phase).(component);

    % The center-to-center shift between planes is 160mm
    contourf(interpolated_data(plane, phase).X + center2center * plane, interpolated_data(plane, phase).Y + 200 * plane, u, 100, 'linestyle', 'none')
    plot(interpolated_data(plane, phase).X(1,:) + center2center * plane, interpolated_data(plane, phase).max_wave + 200 * plane, 'color', 'red', 'linewidth', 2)

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

for phase = 1:4
    for plane = 1:4
        for c = 1:length(components)
    
            % Load data
            component = components{c};
            tmp = interpolated_data(plane, phase).(component);
        
            % Blur edges of data
            fadeMask = ones(imageHeight, imageWidth);
            fadeMask(:, 1:overlap) = repmat(linspace(0, 1, overlap), imageHeight, 1);
            fadeMask(:, end - overlap + 1:end) = repmat(linspace(1, 0, overlap), imageHeight, 1);
            tmp = tmp .* fadeMask;
        
            % Zero Pads
            leftZeroPad  = zeros(imageHeight, ((plane - 1) * (imageWidth - overlap)));
            rightZeroPad = zeros(imageHeight, ((4 - plane) * (imageWidth - overlap)));
            
            % Padded images
            padded_frames(plane, phase).(component) = horzcat(leftZeroPad, tmp, rightZeroPad);
    
        end
    end
end

clear plane c tmp fadeMask leftZeroPad rightZeroPad


% Extend coordinates
X = interpolated_data(1,1).X;
X = X - min(X, [], 'all');
x  = X(1,:);
Y = interpolated_data(1,1).Y;
extendedY = horzcat(Y, Y, Y, Y(:, 1:end - 3 * overlap));
extendedX = horzcat(X, X + 1*x(end), X + 2*x(end), X(:, 1:end - 3 * overlap) + 3*x(end));

%%% Stitching max wave profile
for phase = 1:4
    for plane = 1:4
        % max_wave_profile = max(interpolated_data(plane, phase).Waves, [], 1);
    
        % Pad to global stitched coordinates
        left_pad_len  = (plane - 1) * (imageWidth - overlap);
        right_pad_len = (4 - plane) * (imageWidth - overlap);
        padded_wave = [nan(1, left_pad_len), interpolated_data(plane, phase).max_wave, nan(1, right_pad_len)];
        max_wave(plane, :) = padded_wave;
    end
    % Combine all planes by taking max at each X
    stitched(phase).max_wave = max(max_wave, [], 1, 'omitnan');
end




% Join all the padded frames
[~, vertical_cutoff] = min(abs(extendedY(:,1) - 200));
for phase = 1:4
    for c = 1:length(components)
        component = components{c};
        tmp = padded_frames(1, phase).(component) + padded_frames(2, phase).(component) + padded_frames(3, phase).(component) + padded_frames(4, phase).(component);
    
        % Flatten the top of frame
        stitched(phase).(component) = tmp(vertical_cutoff:end, :);
    end
end

% Flatten the top of frame
extendedY = extendedY(vertical_cutoff:end, :);
extendedX = extendedX(vertical_cutoff:end, :);

% Save coordinates
for phase = 1:4
    stitched(phase).X = extendedX;
    stitched(phase).Y = extendedY;
end

clear c component dx imageHeight imageWidth overlap padded_frames tmp vertical_cutoff 
clear x X Y left_pad_len max_wave_profile plane right_pad_len max_wave


%%% Brute force fill in nan columns from interpolating: 
% There is a pure column of nans at column 556 + 657 until about row 270
for phase = 1:4
    for c = 1:length(components)
        component = components{c};
        tmp = stitched(phase).(component);
        % tmp(1:270, 554:558) = fillmissing(tmp(1:270, 554:558), 'linear');
        tmp(1:270, 656:658) = fillmissing(tmp(1:270, 656:658), 'linear', 2);
        stitched(phase).(component) = tmp;
    
        clear c component tmp
    end
end

% %%% Save a wave-cropped version
% for c = 1:length(components)
%     component = components{c};
%     max_wave_profile = stitched.max_wave;
%     tmp = stitched.(component);
%     tmp(extendedY < max_wave_profile) = nan;
% 
%     cropped_stitched.(component) = tmp;
% end

% Save wave
% cropped_stitched.max_wave = stitched.max_wave;
% 
% % Save coordinates
% cropped_stitched.X = extendedX;
% cropped_stitched.Y = extendedY;

clear c component max_wave_profile tmp phase

%% Final stitch

% Turbine diameter in mm
D = 150;

% Hub height in mm
hub_height = 117;

% What to plot
component = 'u';
phase = 2;

figure()
hold on
contourf(stitched(phase).X / D, stitched(phase).Y / D, stitched(phase).(component), 100, 'linestyle', 'none')
plot(stitched(phase).X(1,:) / D, stitched(phase).max_wave / D, 'color', 'red', 'linewidth', 2)
hold off
axis equal
colorbar()
ylim([-60 / 150, 200 / 150])
xlim([-10 / 150, 5])

yline(hub_height/D)
yline(hub_height/D + 1/2, 'linestyle', '--')
yline(hub_height/D - 1/2, 'linestyle', '--')

%% Save to matfile

save_name = strcat(arrangement, '_', wave_type, '_PHASE_STITCHED.mat');
save_dir  = fullfile(matfile_path, 'stitched', 'phase');

output.cropped = stitched;

save(fullfile(save_dir, save_name), 'output');
clc; fprintf("Saved %s!\n", save_name)









