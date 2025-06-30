%% Testing how to detect waves which were poorly detected using LIF by incorporating velocity information


addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
fprintf('All Paths Imported...\n\n')


skipped_frame_names = strcat(frames.common(crop.skip), '.im7');
skipped_U = crop.skippedU;
skipped_V = crop.skippedV;
skipped_W = crop.skippedW;
magnitude = sqrt(skipped_U.^2 + skipped_V.^2);

PIV_X = crop.X;
PIV_Y = crop.Y;

wave_profiles = nan(length(skipped_frame_names), size(PIV_X, 2));

% Look at a single frame
% for f = 1:length(skipped_frame_names)
for f = 1:5

    % Progress bar
    progressbarText(f/length(skipped_frame_names));

    % PIV Wave profile: find minimum velocity across columns
    crop_limit = -80;
    maskedmagnitude = magnitude(:,:,f);
    maskedmagnitude(PIV_Y > crop_limit) = nan;
    [~, minVIdx] = min(maskedmagnitude, [], 1);


    %%% Load RAW image
    % Try to grab image
    raw = readimx(char(strcat(perspective_path, '/', skipped_frame_names(f))));
    
    % Load both camera images
    raw_image_CAM1 = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
    raw_image_CAM2 = raw.Frames{3,1}.Components{1,1}.Planes{1,1};
    
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
        if contains(details.arrangement, 'Floating') == 1
            combined_image(X < -35) = nan;
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
    PIV_profile = PIV_Y(minVIdx,:);
    RAW_downscaled = imresize(combined_image, size(PIV_X));
    masked_RAW = RAW_downscaled;
    
    % Pixels above and below initial guess
    search_margin = 30;  
    
    % For each x-column:
    for col = 1:size(masked_RAW,2)
    
        y_guess = PIV_profile(col);
        RAW_profile = masked_RAW(:, col);
        
        % Define vertical range in pixels (row indices)
        y_min = y_guess - search_margin;
        y_max = y_guess + search_margin;
        
        % Extract this ROI from raw image
        RAW_profile(PIV_Y(:,1) > y_max | PIV_Y(:,1) < y_min) = nan;
        masked_RAW(:, col) = RAW_profile;
    
    end



    %%% Perform edge detection on this cropped region
    % Seperate free surface
    x = PIV_X(1,:);
    y = PIV_Y(:,1);
    nf = size(PIV_X);
   

    %%% ChatGPT: Parameter optimization for best edge detection results
    best_score = Inf;
 
    for blur = 1:3:30
        for low = 0.05:0.05:0.2
            for high = 0.3:0.1:0.5
                wave_profile = zeros(1, nf(2));
                % masked_RAW = juliaan_smooth(masked_RAW, blur);
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
            
                % Remove Any NaNs
                if isnan(sum(wave_profile)) 
                    interp_x = x;
                    interp_wave = wave_profile;
                    interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
            
                    % Fill in holes
                    wave_profile = interp_wave;
                end
    
                % Compare to inferred_wave (or a smoothed version)
                deviation = std(wave_profile - PIV_profile);
                
                if deviation < best_score
                    best_score = deviation;
                    disp([blur, low, high])
                    wave_profiles(f, :) = wave_profile;
                end
            end
        end
    end
end

%% Plot all detected waves

figure()
hold on
for f = 1:length(skipped_frame_names)
    % plot(x, wave_profiles(i,:))
    plot(x, imgaussfilt(wave_profiles(f,:), 3))
end
hold off
axis equal

%% check cropped velocity images

for f = 1:length(skipped_frame_names)

    u = skipped_U(:,:,f);
    v = skipped_V(:,:,f);
    w = skipped_W(:,:,f);
    wave = wave_profiles(f,:);
    wave = imgaussfilt(wave, 3);

    u(PIV_Y < wave) = nan;
    v(PIV_Y < wave) = nan;
    w(PIV_Y < wave) = nan;

    h = figure();
    tiledlayout(1,3)
    sgtitle(skipped_frame_names(f))

    nexttile
    hold on
    contourf(PIV_X, PIV_Y, u, 100, 'linestyle', 'none')
    plot(x, wave, 'color', 'red', 'linewidth', 2)
    hold off
    axis equal
    title('u')
    colorbar()
    clim([0, 4])

    nexttile
    hold on
    contourf(PIV_X, PIV_Y, v, 100, 'linestyle', 'none')
    plot(x, wave, 'color', 'red', 'linewidth', 2)
    hold off
    axis equal
    title('u')
    colorbar()
    clim([-1, 1])

    nexttile
    hold on
    contourf(PIV_X, PIV_Y, w, 100, 'linestyle', 'none')
    plot(x, wave, 'color', 'red', 'linewidth', 2)
    hold off
    axis equal
    title('u')   
    colorbar()
    clim([-1, 1])

    waitfor(h)
end

    

















