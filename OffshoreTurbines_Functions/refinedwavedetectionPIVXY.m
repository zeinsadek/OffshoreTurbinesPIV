function output = refinedwavedetectionPIVXY(perspective_path, details, crop, skipped_frames_idxs, settings, frames, out_path)

    addpath('C:\Users\sadek\Desktop\readimx-v2.1.9-win64');

    % Halim edit to be able to open
    output = matfile(out_path, 'Writable', true);

    % Pull in data
    UFs = crop.U;
    VFs = crop.V;
    waves = crop.waves;
    PIV_X = crop.X;
    PIV_Y = crop.Y;

    fprintf('<refinedwavedetectionPIVXY> Refining bad waves...\n');

    % In case there are no waves to be fixed
    if ~isnan(skipped_frames_idxs)

        skipped_frames = skipped_frames_idxs;
        skipped_frame_names = strcat(frames.common(skipped_frames), '.im7');
        skipped_U = UFs(:, :, skipped_frames);
        skipped_V = VFs(:, :, skipped_frames);
        magnitude = sqrt(skipped_U.^2 + skipped_V.^2);

        % Look at a single frame
        for f = 1:length(skipped_frame_names)
    
             % h = figure();
        
            % Progress bar
            progressbarText(f / length(skipped_frame_names));
            % disp(f)
        
            % PIV Wave profile: find minimum velocity across columns
            amplitude = (details.wavelength * 150 * details.steepness) / (4 * pi);
            still_water = -100;    % Roughly
    
            upper_crop_limit = still_water + 4*amplitude;
            lower_crop_limit = still_water - 4*amplitude;
            maskedmagnitude = magnitude(:, :, f);
            maskedmagnitude(PIV_Y > upper_crop_limit) = nan;
            maskedmagnitude(PIV_Y < lower_crop_limit) = nan;
    
            [~, minVIdx] = min(maskedmagnitude, [], 1);
        
        
            %%% Load RAW image
            % Try to grab image
            frame_name = skipped_frame_names(f);
            raw = readimx(char(strcat(perspective_path, '/', frame_name)));
            
            % Load both camera images
            raw_image_CAM1 = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
            raw_image_CAM2 = raw.Frames{2,1}.Components{1,1}.Planes{1,1};
            
            % Get coordinates
            nf = size(raw_image_CAM1);
            x = raw.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*raw.Frames{1,1}.Grids.X + raw.Frames{1,1}.Scales.X.Offset;
            y = raw.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*raw.Frames{1,1}.Grids.Y + raw.Frames{1,1}.Scales.Y.Offset;
            [X, Y] = meshgrid(x, y);
            X = -fliplr(X);
            raw_image_CAM1 = fliplr(raw_image_CAM1.');
            raw_image_CAM2 = fliplr(raw_image_CAM2.');
            
            % Get individual FOV
            raw_image_CAM1(raw_image_CAM1 == 0) = nan;
            raw_image_CAM2(raw_image_CAM2 == 0) = nan;
            
            % Binaraize
            CAM1_FOV_mask = ~isnan(raw_image_CAM1);
            CAM2_FOV_mask = ~isnan(raw_image_CAM2);
            
            % Get combined FOV_mask
            FOV_mask = CAM1_FOV_mask + CAM2_FOV_mask;
            FOV_mask(FOV_mask < 2) = 0;
            FOV_mask = FOV_mask/2;
            
            % Combined stereo image
            combined_image = FOV_mask .* (raw_image_CAM1 + raw_image_CAM2);
            
            % Mask Plane 1 because of tape
            if details.plane == 1
                % Floating
                if contains(details.arrangement, 'Floating') == 1
                    combined_image(X < -35) = nan;
                end

                % Fixed-Bottom
                if contains(details.arrangement, 'Fixed') == 1
                    combined_image(X < -80) = nan;
                end
            end

            % Mask Plane 4 because of tape
            if details.plane == 4
                if contains(details.arrangement, 'Floating') == 1
                    combined_image(X > 65) = nan;
                end
            end
            
            % Crop array dimensions
            %%% LHS
            % Find index of value closest to what we want to crop to
            % Initial, uncropped x positions from DaVis
            x = X(1,:);
            left_bound = -100;
            [~, left_bound_idx] = min(abs(x - left_bound));
            
            % Truncate relavant portion of array
            X(:, 1:left_bound_idx) = [];
            Y(:, 1:left_bound_idx) = [];
            combined_image(:, 1:left_bound_idx) = [];
            
            %%% RHS
            % Redefine x since it has been partially cropped
            x = X(1,:);
            % Find index of value closest to what we want to crop to
            right_bound = 100;
            [~, right_bound_idx] = min(abs(x - right_bound));
            
            % Truncate relavant portion of array
            X(:, right_bound_idx:end) = [];
            Y(:, right_bound_idx:end) = [];
            combined_image(:, right_bound_idx:end) = [];
        
        
        
            %%% Use the velocity wave profile to crop the RAW
            %%% Perform edge detection on this cropped region
            % Seperate free surface
            x = PIV_X(1,:);
            y = PIV_Y(:,1);
            nf = size(PIV_X);
    
            PIV_profile = y(minVIdx,:);
            RAW_downscaled = imresize(combined_image, size(PIV_X));
            masked_RAW = RAW_downscaled;
            
            % Pixels above and below initial guess
            % search_margin = 30;  
            
            % For each x-column:
            %%% Instead of this try just masking it with a buffer at top and
            %%% bottom
    
            % for col = 1:size(masked_RAW,2)
            % 
            %     y_guess = PIV_profile(col);
            %     RAW_profile = masked_RAW(:, col);
            % 
            %     % Define vertical range in pixels (row indices)
            %     y_min = y_guess - search_margin;
            %     y_max = y_guess + search_margin;
            % 
            %     % Extract this ROI from raw image
            %     RAW_profile(PIV_Y(:,1) > y_max | PIV_Y(:,1) < y_min) = nan;
            %     masked_RAW(:, col) = RAW_profile;
            % end
            masked_RAW(PIV_Y > upper_crop_limit) = nan;
            masked_RAW(PIV_Y < lower_crop_limit) = nan;
            
        
            %%% Mask FWF Plane 1
            % Ignore cropped region of FWF Plane 1
            if details.plane == 1
                % Floating
                if contains(details.arrangement, 'Floating') == 1
                    cutoff = -20;
                end
                
                % Fixed-Bottom
                if contains(details.arrangement, 'Fixed') == 1
                    cutoff = -80;
                end
            elseif details.plane == 4
                if contains(details.arrangement, 'Floating') == 1
                    cutoff = 50;
                end
            else
                cutoff = -100;
            end


            % Try to clean up blank spots in wave
            [~, cutoff_index] = min(abs(x - cutoff));
    
            % Planes 1, 2, 3
            if ismember(details.plane, [1,2,3])
                masked_RAW(PIV_X < cutoff) = nan;
                PIV_profile(1:cutoff_index - 1) = still_water;

            % Plane 4
            else
                masked_RAW(PIV_X > cutoff) = nan;
                PIV_profile(cutoff_index + 1:end) = still_water;
            end
        
            
            
        



    
            % ChatGPT: Parameter optimization for best edge detection results
            best_score = Inf;
            best_wave_profile = zeros(1, nf(2));
    
            for low = 0.05:0.05:0.25
                for high = 0.3:0.05:0.6
                    wave_profile = nan(1, nf(2));
                    edges = edge(masked_RAW, 'Canny', [low high]);
        
                    % Clean up detected edge
                    for col = 1:nf(2)
                        [ones_r, ~] = find(edges(:, col) == 1);
                        size_ones   = size(ones_r);
                        len         = size_ones(1);
                        if len == 0
                            wave_profile(1, col) = nan;
                        else
                            wave_profile(1, col) = y(min(ones_r));
                        end
                    end
                
                    % Remove Any NaNs for Planes 1, 2, 3
                    if ismember(details.plane, [1,2,3])

                        % Check if detected wave is all nans
                        % if sum(isnan(wave_profile(cutoff_index:end))) == length(wave_profile(cutoff_index:end)) - cutoff_index\
                        %%% Need at least two non-nan values to interpolate
                        if sum(~isnan(wave_profile(cutoff_index:end))) < 2
                            % Replace with still surface
                            wave_profile(cutoff_index:end) = still_water;

                        % Otherwise fill in nans
                        elseif isnan(sum(wave_profile(cutoff_index:end))) 
                            interp_x = x(cutoff_index:end);
                            interp_wave = wave_profile(cutoff_index:end);
                            interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
                    
                            % Fill in holes
                            wave_profile(cutoff_index:end) = interp_wave;
                        end

                        % Compare to inferred_wave (or a smoothed version)
                        deviation = std(wave_profile(cutoff_index:end) - PIV_profile(cutoff_index:end));

                    % Remove Any NaNs for Planes 4
                    else
                        % Check if detected wave is all nans
                        % if sum(isnan(wave_profile(1:cutoff_index))) > (length(wave_profile(1:cutoff_index)) - cutoff_index)
                        %%% Need at least two non-nan values to interpolate
                        if sum(~isnan(wave_profile(1:cutoff_index))) < 2
                            fprintf('All nan wave\n')
                            % Replace with still surface
                            wave_profile(1:cutoff_index) = still_water;

                        % Otherwise fill in nans
                        elseif isnan(sum(wave_profile(1:cutoff_index))) 
                            interp_x = x(1:cutoff_index);
                            interp_wave = wave_profile(1:cutoff_index);
                            interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
                    
                            % Fill in holes
                            wave_profile(1:cutoff_index) = interp_wave;
                        end

                        % Compare to inferred_wave (or a smoothed version)
                        deviation = std(wave_profile(1:cutoff_index) - PIV_profile(1:cutoff_index));
                    end
        

                    
                    if deviation < best_score
                        % Update score
                        best_score = deviation;

                        % Smooth appropriate portion of profile for Planes
                        % 1, 2, 3
                        best_wave_profile = wave_profile;

                        if ismember(details.plane, [1,2,3])
                            best_wave_profile(cutoff_index:end) = imgaussfilt(wave_profile(cutoff_index:end), settings.wave_smoothing_kernel);
                            % Mask unused part of profile
                            best_wave_profile(1:cutoff_index - 1) = nan;
                        else
                            best_wave_profile(1:cutoff_index) = imgaussfilt(wave_profile(1:cutoff_index), settings.wave_smoothing_kernel);
                            % Mask unused part of profile
                            best_wave_profile(cutoff_index + 1) = nan;
                        end

                        
                    end
                end
            end
    
    

            % Ignore frames where there was a misfire
            if abs(mean(masked_RAW, 'all', 'omitnan')) > 100
                fprintf('<refinewavedetectionPIVXY> Skipping Frame %5.0\n', skipped_frames(f));
                waves(skipped_frames(f), :) = nan(1, nf(2));
            else
                 % Save best waves
                 waves(skipped_frames(f), :) = best_wave_profile;
            end
    
            %%% Plotting to troubleshoot
            % disp(image_mean)
            % hold on
            % contourf(PIV_X, PIV_Y, masked_RAW, 30, 'linestyle', 'none')
            % plot(x, waves(skipped_frames(f), :), 'color', 'blue')
            % plot(x, PIV_profile, 'color', 'green')
            % plot(x, best_wave_profile, 'color', 'red')
            % hold off
            % colorbar()
            % title(num2str(skipped_frame_names(f)))
            % axis equal
            % waitfor(h)
    
        end

        % Smooth all other waves that were not refined
        for f = 1:length(waves)
            % Only have this here so we dont double smooth the fixed waves
            if ~ismember(f, skipped_frames)
                if ismember(details.plane, [1,2,3])
                    waves(f, cutoff_index:end) = imgaussfilt(waves(f, cutoff_index:end), settings.wave_smoothing_kernel);
                else
                    waves(f, 1:cutoff_index) = imgaussfilt(waves(f, 1:cutoff_index), settings.wave_smoothing_kernel);
                end
            end
        end


    %%% In case no waves need to be refined, still crop and smooth
    % Crop and smooth waves even though we didnt have to fix them
    % Ignore cropped region of FWF Plane 1
    else
        clc;
        fprintf('<refinewavedetectionPIVXY> No waves were refined!\n\n');

        if details.plane == 1
            if contains(details.arrangement, 'Floating') == 1
                cutoff = -20;
            end
        elseif details.plane == 4
            if contains(details.arrangement, 'Floating') == 1
                cutoff = 60;
            end
        else
            cutoff = -100;
        end

        % Define where we will crop
        x = PIV_X(1,:);
        [~, cutoff_index] = min(abs(x - cutoff));

        % Smooth all other waves that were not refined
        if ismember(details.plane, [1,2,3])
            for f = 1:length(waves)
                waves(f, cutoff_index:end) = imgaussfilt(waves(f, cutoff_index:end), settings.wave_smoothing_kernel);
            end
        else
            for f = 1:length(waves)
                waves(f, 1:cutoff_index) = imgaussfilt(waves(f, 1:cutoff_index), settings.wave_smoothing_kernel);
            end
        end 
    end

    % Crop the left\right of all waves
    if ismember(details.plane, [1,2,3])
        waves(:, 1:cutoff_index - 1) = nan;
    else
        waves(:, cutoff_index + 1:end) = nan;
    end

    % Combine outputs
    output.waves = waves;
    output.x = crop.X(1,:);
    output.refined = skipped_frames_idxs;
    output.settings = settings;

    fprintf('<refinewavedetectionPIVXY> Done refining\n');

    % Save Matlab File.
    fprintf('\n<refinedwavedetectionPIVXY> Saving Data to File... \n');
    fprintf('<refinedwavedetectionPIVXY> Data Save Complete \n')

end