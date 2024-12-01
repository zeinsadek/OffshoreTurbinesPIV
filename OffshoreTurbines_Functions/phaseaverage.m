%%% Phase Averaging Code
% Zein Sadek, 1/23

function output = phaseaverage(raw_image_path, constants, wave_path, out_path)

    % Check if Input is Readable
    if isempty(raw_image_path)
     fprintf('\n** INPUT FILES NOT FOUND! **\n')
     output = NaN;
    else
        % Check if Save Folder Exists. [if not, create]
        if exist(out_path, 'file')
            fprintf('<phaseaverage> *Save Folder was Previously Created. \n')
        else
            fprintf('<phaseaverage> *Creating New Save Folder. \n')
            %mkdir(out_path);
        end
        
        %%% CONSTANTS
        left_bound_value        = constants.left_bound_value;
        right_bound_value       = constants.right_bound_value;
        percent_phase_tolerance = constants.percent_phase_tolerance;
        phase_tolerance         = constants.phase_tolerance;                 
        range                   = abs(left_bound_value) + abs(right_bound_value);
        
        % Reference Wave
        wave_amplitude  = constants.wave_amplitude;
        wave_length     = constants.wave_length;
        %wave_type       = constants.wave_type;
        vertical_offset = constants.vertical_offset;
        phase_offset    = constants.phase_offset;     
        
        % Load Wave Profiles
        wave_struc    = load(wave_path);
        wave_struc    = wave_struc.output;       
        wave_profiles = wave_struc.wave_profiles;
        phase_fits    = wave_struc.fitted_phases;
        D             = wave_struc.D;
        x             = wave_struc.x;
        
        % Saves
        phase_average_idx = zeros(1, D);
        
        fprintf('<phaseaverage> PROGRESS: \n');
        for frame_number = 1:D
            
            % Print Progress.
            progressbarText(frame_number/D);
            
            % Fitted Phase Offest
            fitted_phase = phase_fits(frame_number);
            
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
        
        %%% OUTPUT
        % Add Image/Data Parameters to struct file
        output.phase_average_idx = phase_average_idx;

        % Save Matlab File.
        fprintf('\n<phaseaverage> Saving Data to File... \n');
        save(out_path, 'output');
        fprintf('\n<phaseaverage> Data Save Complete \n')

        %%% Plot
        clc;
        fprintf('\nTolerance Range: %4.2f mm\n', 2 * phase_tolerance)

        % Create tiled layout plot with all 4 phases
        fig = tiledlayout(4,1, 'Padding', 'compact', 'TileSpacing', 'compact');
        
        % Title include recording name and phase tolerance
        main_title = strcat(constants.recording_name, ': Tolerance +/- ', num2str(percent_phase_tolerance * 100), '% of Wavelength ');
        %sgtitle(main_title, 'Interpreter', 'none')
        title(fig, main_title, 'Interpreter', 'none')
        
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

            % Reference Wave
            reference_profile = wave_amplitude * cos(2 * pi * (x - phase_offset(phase)) / wave_length);
            plot(x + (range/2), reference_profile, 'Color', 'red', 'LineWidth', 2);

             % Plot Max Wave Profile
            plot(x + (range/2), max(wave_profiles(idx, :), [], 1), 'Color', 'green', 'LineWidth', 2)

            xline(range/2, 'LineStyle', '--')
            hold off  
            title(strcat('Phase', {' '}, num2str(phase),':', {' '}, num2str(length(idx)), ' Images'))
            ylabel('z [mm]')
            axis equal
        end
        
        % Match axes
        linkaxes(ax, 'xy')
        xlim([0, range])
        ylim([-2.5 * wave_amplitude, 2.5 * wave_amplitude])

        if phase == length(phase_offset)
            xlabel('x [mm]')
        end
    
    
        % Set size/save plot
        set(gcf, 'Units', 'Inches', 'Position', [1, 5, 10, 15])
        figure_name = strcat(constants.recording_name, '_phase_avg_wave_profiles_', num2str(percent_phase_tolerance * 100), '_percent_tol.png');
        exportgraphics(fig, strcat(constants.figure_file, '/', figure_name))   
        close all;

        %%% Figure to Visualize Max Tolerance Offset
        fig2 = tiledlayout(4,1, 'Padding', 'compact', 'TileSpacing', 'compact');

        % Title include recording name and phase tolerance
        main_title = strcat(constants.recording_name, ': Tolerance +/- ', num2str(percent_phase_tolerance * 100), '% of Wavelength');
        %sgtitle(main_title, 'Interpreter', 'none')
        title(fig2, main_title, 'Interpreter', 'none')

        % Iterate through phases
        for phase = 1:length(phase_offset)          
            ax2(phase) = nexttile;
            hold on 

            ref_profile = wave_amplitude * cos(2 * pi * (x - phase_offset(phase)) / wave_length);
            ref_plus    = wave_amplitude * cos(2 * pi * (x - phase_offset(phase) + phase_tolerance) / wave_length);
            ref_minus   = wave_amplitude * cos(2 * pi * (x - phase_offset(phase) - phase_tolerance) / wave_length);

            plot(x + (range/2), ref_profile, 'Color', 'red',   'LineWidth', 2);
            plot(x + (range/2), ref_plus,    'Color', 'black', 'LineWidth', 2);
            plot(x + (range/2), ref_minus,   'Color', 'black', 'LineWidth', 2);  

            xline((range/2), 'LineStyle', '--')
            xline((range/2) + phase_tolerance, 'LineStyle', '--')
            xline((range/2) - phase_tolerance, 'LineStyle', '--')
            hold off  
            axis equal
            title(strcat('Phase', {' '}, num2str(phase)))
            ylabel('z [mm]')
        end

        % Match axes
        linkaxes(ax2, 'xy')
        xlim([0, range])
        ylim([-2.5 * wave_amplitude, 2.5 * wave_amplitude])

        if phase == length(phase_offset)
            xlabel('x [mm]')
        end

        % Set size/save plot
        set(gcf, 'Units', 'Inches', 'Position', [1, 5, 10, 15])
        figure_name = strcat(constants.recording_name, '_phase_avg_tolerance_check_', num2str(percent_phase_tolerance * 100), '_percent.png');
        exportgraphics(fig2, strcat(constants.figure_file, '/', figure_name)) 
        close all;
    end
end


