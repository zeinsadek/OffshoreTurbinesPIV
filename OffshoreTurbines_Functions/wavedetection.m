%%% Free Surface Detection Code
% Zein Sadek, 5/23

function output = wavedetection(raw_image_path, constants, out_path)

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
            %mkdir(out_path);
        end
        
        %%% CONSTANTS
        background_removal = constants.background_removal;
        canny_lower        = constants.canny_lower;
        canny_upper        = constants.canny_upper;
        grad_tol           = constants.grad_tol;
        nan_dist           = constants.nan_dist;
        left_bound_value   = constants.left_bound_value;
        right_bound_value  = constants.right_bound_value;
        phase_tolerance    = constants.phase_tolerance;                 
            
        % Reference Wave
        wave_amplitude  = constants.wave_amplitude;
        wave_length     = constants.wave_length;
        wave_type       = constants.wave_type;
        vertical_offset = constants.vertical_offset;
        cos_fit         = @(b, v) wave_amplitude * cos(2 * pi * (v - b(1)) / wave_length) + vertical_offset;
        
        % Image Path
        image_name = dir([raw_image_path, '\*.im7']);
        D          = length(image_name);

        % Define Image Dimensions
        raw              = readimx([raw_image_path, '\', image_name(1).name]);
        raw_image        = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
        nf               = size(raw_image);
        x                = raw.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).* raw.Frames{1,1}.Grids.X + raw.Frames{1,1}.Scales.X.Offset;
        y                = raw.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).* raw.Frames{1,1}.Grids.Y + raw.Frames{1,1}.Scales.Y.Offset;
        [~, left_bound]  = min(abs(x - left_bound_value));
        [~, right_bound] = min(abs(x - right_bound_value));
        range            = abs(left_bound_value) + abs(right_bound_value);
        x                = x(left_bound:right_bound) - left_bound_value - (range / 2);
        
        % Saves
        wave_profiles = zeros(D, length(x));
        fitted_phases = zeros(1, D);
        
        fprintf('<wavedetection> PROGRESS: ');
        for frame_number = 1:D
           
            % Print Progress.
            progressbarText(frame_number/D);
            % disp(image_name(frame_number).name)

            % Load Images
            raw       = readimx([raw_image_path, '/', image_name(frame_number).name]);
            raw_image = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
            raw_image = rot90(raw_image, -1);
            
            % Edge Detection
            raw_image(raw_image < background_removal) = 0;
            wave_edge = edge(raw_image, 'Canny', [canny_lower, canny_upper]);
            wave_profile = zeros(1, nf(1));

            for i = 1:nf(1)
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

            % Crop to avoid nans at ends
            wave_profile = wave_profile(left_bound:right_bound);  
            
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
         
            % Fit each profile with a cosine wave 
            if wave_type ~= '0'
                
                % Phase Fit
                fit_nan_crop = ~isnan(wave_profile);
                fcn          = @(b) sum((cos_fit(b, x(fit_nan_crop)) - wave_profile(fit_nan_crop)).^2);                             
                fitted_phase = fminsearch(fcn, 0);
                
                % Avoid extraneous nans in profiles
                if sum(~isnan(wave_profile)) < length(x)
                    wave_profiles(frame_number, :) = cos_fit(fitted_phase, x);
                else    
                    wave_profiles(frame_number, :) = wave_profile;
                end
              
                % Convert negative phases to positive
                if fitted_phase < -1 * phase_tolerance
                    fitted_phase = wave_length + fitted_phase;
                else
                end
               
                % Save fitted phases
                fitted_phases(frame_number) = fitted_phase;
            else
                wave_profiles(frame_number, :) = wave_profile;
            end
        end  

        % %%% For Troubleshooting
        % figure(frame_number)
        % plot(x, wave_profiles(frame_number, :))
        % axis equal
        % xlim([min(x), max(x)])
        
        %%% OUTPUT
        output.x                 = x;
        output.y                 = y;
        output.D                 = D;
        output.wave_profiles     = wave_profiles - vertical_offset; % Zero Waves to still surface
        output.fitted_phases     = fitted_phases;
        

        % Save Matlab File.
        fprintf('\n<wavedetection> Saving Data to File... \n');
        save(out_path, 'output');
        clc; fprintf('\n<wavedetection> Data Save Complete \n')
    end  
end


