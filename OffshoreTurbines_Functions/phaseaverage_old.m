%%% Phase Averaging Code
% Zein Sadek, 1/23

function output = phaseaverage_old(raw_image_path, constants, out_path)

    % Check if Input is Readable
    if isempty(raw_image_path)
     fprintf('\n** INPUT FILES NOT FOUND! **\n')
     output = NaN;
    else
        % Check if Save Folder Exists. [if not, create]
        if exist(out_path, 'file')
            fprintf('<phaseaverage_old> *Save Folder was Previously Created. \n')
        else
            fprintf('<phaseaverage_old> *Creating New Save Folder. \n')
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
        phase_offset    = constants.phase_offset;
        cos_fit         = @(b, v) wave_amplitude * cos(2 * pi * (v - b(1)) / wave_length) + vertical_offset;
        
        % Image Path
        image_name = dir([raw_image_path, '/*.im7']);
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
        phase_average_idx = zeros(1, D);
        wave_profiles     = zeros(D, length(x));
        fitted_phases     = zeros(1, D);
        
        fprintf('<phaseaverage_old> PROGRESS: \n');
        for frame_number = 1:D
           
            % Print Progress.
            progressbarText(frame_number/D);

            % Load Images
            raw       = readimx([raw_image_path, '\', image_name(frame_number).name]);
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
            
            % Only Phase Average if Waves are Present
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
                
                fitted_phases(frame_number) = fitted_phase;

                % Bin frames to phases
                for phase = 1:length(phase_offset)   
                    lower_phase = phase_offset(phase) - phase_tolerance;
                    upper_phase = phase_offset(phase) + phase_tolerance;

                    if fitted_phase >= lower_phase && fitted_phase <= upper_phase
                        phase_average_idx(frame_number) = phase;
                    else
                    end
                end
            end    
        end
        
        %%% OUTPUT
        % Add Image/Data Parameters to struct file
        output.phase_average_idx = phase_average_idx;
        output.wave_profiles     = wave_profiles;
        output.fitted_phases     = fitted_phases;

        % Save Matlab File.
        fprintf('\n<phaseaverage_old> Saving Data to File... \n');
        save(out_path, 'output');
        clc; fprintf('\n<phaseaverage_old> Data Save Complete \n')

        %%% Plot
        clc;
        fprintf('\nTolerance Range: %4.2f mm\n', 2 * phase_tolerance)

        % Create tiled layout plot with all 4 phases
        fig = tiledlayout(4,1, 'Padding', 'compact', 'TileSpacing', 'compact');
        % Title include recording name and phase tolerance
        main_title = strcat(constants.recording_name, ': Tolerance +/- ', num2str(phase_tolerance), ' mm');
        sgtitle(main_title, 'Interpreter', 'none')
        
        % Iterate through phases
        for phase = 1:length(phase_offset)          
            ax(phase) = nexttile;
            hold on 
            % Search for frames with match with current phase
            idx = find(phase_average_idx == phase);
            fprintf('\nPhase %.f: %.f Images\n', phase, length(idx))
            
            % Loop through mateched frames and plot wave profiles
            for i = 1:length(idx)
                p = plot(x + (range/2), wave_profiles(idx(i), :), 'Color', 'black', 'HandleVisibility','off');
                p.Color(4) = 0.25;
            end
            
            % Plot reference wave profile last so it appears on top
            reference_profile = wave_amplitude * cos(2 * pi * (x - phase_offset(phase)) / wave_length) + vertical_offset - 5;
            plot(x + (range/2), reference_profile, 'Color', 'red', 'LineWidth', 2);
            xline(range/2, 'LineStyle', '--')
            hold off  
            title(strcat('Phase', {' '}, num2str(phase),':', {' '}, num2str(length(idx)), ' Images'))
            ylabel('z [mm]')
        end
        
        % Match axes
        linkaxes(ax, 'xy')
        xlim([0, range])
        ylim([min(y), -70])

        if phase == length(phase_offset)
            xlabel('x [mm]')
        end
    end
    
    % Set size/save plot
    set(gcf, 'Units', 'Inches', 'Position', [1, 5, 10, 15])
    figure_name = strcat(constants.recording_name, '_phase_avg_wave_profiles.png');
    exportgraphics(fig, strcat(constants.figure_file, '/', figure_name))       
end


