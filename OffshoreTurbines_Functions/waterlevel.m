%%% Read still water images and return the average water height
% Zein Sadek, 2/2023

function water_line = waterlevel(still_water_path, still_name, constants)
    
    % Constants
   
    % addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
    background_removal = constants.background_removal;
    canny_lower        = constants.canny_lower;
    canny_upper        = constants.canny_upper;
    grad_tol           = constants.grad_tol;
    nan_dist           = constants.nan_dist;
    left_bound_value   = constants.left_bound_value;
    right_bound_value  = constants.right_bound_value;
    

    % Image Path
    % Path for MacBook
    % PIV_ref            = '/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Offshore/Water_Level/PIV_ref';

    % Path for MME Desktop
    PIV_ref            = 'G:/Other computers/Zein MacBook Pro/Offshore/Water_Level/PIV_ref';
    image_name         = dir([still_water_path, '/*.im7']);
    % piv_image_name     = dir([PIV_ref, '/*.vc7']);
    D                  = length(image_name);
    clc;
    fprintf('<waterlevel> %.f images used from %s \n', D, still_name);

    % Define Image Dimensions Based on PIV Frame
    % data             = readimx([PIV_ref, '/', piv_image_name(1).name]);
    % names            = data.Frames{1,1}.ComponentNames;        
    % U0_index         = find(strcmp(names, 'U0'));
    % UF               = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
    % nf               = size(UF);
    % 
    % x                = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).* data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
    % y                = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).* data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
    % [~, left_bound]  = min(abs(x - left_bound_value));
    % [~, right_bound] = min(abs(x - right_bound_value));
    % x                = x(left_bound:right_bound);
    % [X, Y]           = meshgrid(x, y);
    % wave_profiles    = zeros(D, length(x));

    raw              = readimx([still_water_path, '/', image_name(1).name]);
    raw_image        = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
    nf               = size(raw_image);
    x                = raw.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).* raw.Frames{1,1}.Grids.X + raw.Frames{1,1}.Scales.X.Offset;
    y                = raw.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).* raw.Frames{1,1}.Grids.Y + raw.Frames{1,1}.Scales.Y.Offset;
    [~, left_bound]  = min(abs(x - left_bound_value));
    [~, right_bound] = min(abs(x - right_bound_value));
    x                = x(left_bound:right_bound);
    % range            = abs(left_bound_value) + abs(right_bound_value);
    % [X, Y]           = meshgrid(x, y);

    for frame_number = 1:D

            % Load Images
            raw       = readimx([still_water_path, '\', image_name(frame_number).name]);
            raw_image = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
            % raw_image = imresize(raw_image, size(UF));  
            raw_image = rot90(raw_image, -1);
            raw_image = raw_image(:, left_bound:right_bound);

            % Edge Detection
            raw_image(raw_image < background_removal) = 0;
            wave_edge = edge(raw_image, 'Canny', [canny_lower, canny_upper]);
            wave_profile = zeros(1, length(x));

            for i = 1:length(x)
                vertical_slice = wave_edge(:, i);
                [ones_r, ~]    = find(vertical_slice == 1);
                size_ones      = size(ones_r);
                len            = size_ones(1);
                if len == 0
                    wave_profile(1, i) = nan;
                else
                    wave_profile(1, i) = y(min(ones_r));
                end
            end

            % Replace kinks with nan values
            spikes = find(abs(gradient(wave_profile)) >= grad_tol);
            wave_profile(spikes) = nan;
 
            % Remove values between nans
            for i = 1:length(spikes)
                first_nan = spikes(i);
                for j = 1:nan_dist
                    second_nan = first_nan + j;
                    if second_nan > length(x)
                        second_nan = length(x);
                    end
                    if isnan(wave_profile(second_nan))
                        wave_profile(first_nan:second_nan) = nan;
                    end
                end
            end
 
            % Interpolate over nans
            wave_profile(isnan(wave_profile)) = interp1(x(~isnan(wave_profile)), wave_profile(~isnan(wave_profile)), x(isnan(wave_profile)));
            
            % Save Profiles
            wave_profiles(frame_number,:) = wave_profile;
    end
    
    % Average Profiles
    water_line = mean(mean(wave_profiles, 1, 'omitnan'), 'omitnan');
    
    % Plot
%     figure()
%     hold on
%     contourf(X, Y, raw_image, 500, 'LineStyle', 'none')
%     colormap gray
%     yline(water_line, 'Color', 'red', 'LineWidth', 3)
%     hold off
%     axis equal
%     xlim([min(x), max(x)])
%     ylim([min(y), max(y)])
%     xlabel('x [mm]')
%     ylabel('z [mm]')
%     ttle = title(strcat(still_name, {': '}, 'Average Still Water Profile'));
%     set(ttle, 'Interpreter', 'none');
% 
    fprintf('\n<waterlevel> Waterline at %3.3f mm\n\n', water_line);
    
end

