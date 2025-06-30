%%% Free Surface Detection Code
% Zein Sadek, 5/23

function output = wavedetectionPIVXY(frames, raw_image_path, details, out_path)

    % Check if Input is Readable
    if isempty(raw_image_path)
        fprintf('\n** INPUT FILES NOT FOUND! **\n')
        output = NaN;
    else
        % Check if Save Folder Exists. [if not, create]
        if exist(out_path, 'file')
            fprintf('<wavedetection> *Save Folder was Previously Created. \n')
        else
            fprintf('<wavedetection> *Creating New Save Folder. \n')
        end
        

        % Image Path
        image_names = strcat(frames.common, '.im7');
        D = length(image_names);

        % Saves
        % wave_profiles = zeros(D, length(x));       
        fprintf('<wavedetection> PROGRESS: ');

        % Counter for the number of frames skipped
        skip_count = 1;

        % Counter for frames used
        frame_counter = 1;

        % Loop through all currently common frames
        for frame_number = 1:D
           
            % Print Progress.
            % progressbarText(frame_number/D);
            disp(image_names(frame_number))

            % Try to grab image
            try
                raw = readimx(char(strcat(raw_image_path, '/', image_names(frame_number))));
            catch ME
                warning('Skipping frame %d (%s): %s', frame_number, image_names(frame_number), ME.message);
                % Record which frames are skipped
                skipped_frames(skip_count) = frame_number;
                % Increment skip count
                skip_count = skip_count + 1;
                continue;
            end

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

            % Mask Plane 4 because of tape
            if details.plane == 5
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
            x = X(1,:);

            % Canny Params
            canny_lower = 0.1;
            canny_upper = 0.4;
            background  = 40;
            
            % Normal Gauss
            blur_size = 15;
            
            % Get Image Size before Blurring
            nf = size(combined_image);
            
            % Blur and Threshold
            combined_image_blurred = imgaussfilt(combined_image, blur_size);
            combined_image_blurred(combined_image_blurred < background) = 0;
            
            % Canny Edge Detection
            wave_edge = edge(combined_image_blurred, 'Canny', [canny_lower, canny_upper]);
            wave_profile = zeros(1, nf(2));
            
            % Seperate free surface
            y = Y(:,1);
            
            % Clean up detected edge
            for i = 1:nf(2)
                [ones_r, ~] = find(wave_edge(:, i) == 1);
                size_ones   = size(ones_r);
                len         = size_ones(1);
                if len == 0
                    wave_profile(1, i) = nan;
                else
                    wave_profile(1, i) = y(min(ones_r));
                end
            end
            
            % Clean profile
            wave_profile(wave_profile > 0) = nan;

            % Save profile
            wave_profiles(frame_counter, :) = wave_profile;

            % Increment frame counter
            frame_counter = frame_counter + 1;
        end

        %%% OUTPUT
        output.x             = x;
        output.y             = y;
        output.D             = (frame_counter - 1);
        output.wave_profiles = wave_profiles;

        if skip_count == 1
            output.skip = nan;
        else 
            output.skip = skipped_frames;
            fprintf('\n<wavedetection> Unreadable frames: \n')
            disp(image_names(skipped_frames))
            fprintf('\n')
        end

        % Save Matlab File.         
        fprintf('\n<wavedetection> Saving Data to File... \n');
        save(out_path, 'output');
        fprintf('\n<wavedetection> Data Save Complete \n')
        
    end
end


