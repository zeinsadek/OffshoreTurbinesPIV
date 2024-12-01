% This function converts DaVis vector data (.vc7) files into a Matlab
% Struct file for easy manipulation in Matlab.
% Zein Sadek, 1/2023

% file_path:    Folder where DaVis (.vc7) files are stored.
% out_path:     Folder where new struct file will be saved.
% out_name:     Name of new struct file.

function output = vector2matlab2D(waves, piv_path, constants, out_path)

    % Phase Average Wave Profiles
    wave_profiles      = waves.wave_profiles;
    
    % Edge Detection Constantss
    left_bound_value   = constants.left_bound_value;
    right_bound_value  = constants.right_bound_value;
    top_bound_value    = constants.top_bound_value;
    vertical_offset    = constants.vertical_offset;

    PIV_height_correction = constants.PIV_height_correction;
    
    % Filtering
    std_tol = constants.std_tol;

    % Check if Input is Readable
    if isempty(piv_path)
     fprintf('\n** INPUT FILES NOT FOUND! **\n')
     output = NaN;
    else
        % Check if Save Folder Exists. [if not, create]
        if exist(out_path, 'file')
            fprintf('<vector2matlab2D> *Save Folder was Previously Created. \n')
        else
            fprintf('<vector2matlab2D> *Creating New Save Folder. \n')
        end

        % Define Image Depth/Length [L] from First Frame.
        piv_image_name = dir([piv_path, '/*.vc7']);
        D              = length(piv_image_name);
        
        % Define Image Dimensions
        data     = readimx([piv_path, '\', piv_image_name(1).name]);
        names    = data.Frames{1,1}.ComponentNames;        
        U0_index = find(strcmp(names, 'U0'));
        UF       = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
        nf       = size(UF);
        x        = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).* data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
        y        = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).* data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
        [X, Y]   = meshgrid(x, y);

        % Align PIV with wave Images
        Y        = Y - PIV_height_correction - vertical_offset;
        
        % Loop Through Each Frame in Folder.
        fprintf('\n<vector2matlab2D> PROGRESS: \n');
        for frame_number = 1:D

            % Print Progress.
            progressbarText(frame_number/D);

            %%% Load data.
            data     = readimx([piv_path, '\', piv_image_name(frame_number).name]);
            names    = data.Frames{1,1}.ComponentNames;        
            U0_index = find(strcmp(names, 'U0'));
            V0_index = find(strcmp(names, 'V0'));
            
            % Load Raw Image and PIV Vectors
            UF = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
            VF = data.Frames{1,1}.Components{V0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{V0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{V0_index,1}.Scale.Offset;
           
            % Align Images: Flip 'n Dip
            UF = -1 * (rot90(UF, -1));
            VF = -1 * (rot90(VF, -1));
            
            % Wave Profile: Resize Wave Profiles to Fit into PIV Frame
            wave_profile = imresize(wave_profiles(frame_number,:), [1, length(x)]);

            %%% TESTINGGG
            wave_profile = wave_profile + vertical_offset;

             
            %%% Cropping
            % Crop below water
            UF(Y <= wave_profile) = nan;
            VF(Y <= wave_profile) = nan;
            
            % Crop Left/Right of Data
            UF(X < left_bound_value - 1)  = nan;
            UF(X > right_bound_value + 1) = nan;
            
            VF(X < left_bound_value - 1)  = nan;
            VF(X > right_bound_value + 1) = nan;
            
            % Crop tip/top of Data
            UF(Y > top_bound_value + 1) = nan;
            VF(Y > top_bound_value + 1) = nan;
         
            % Add Data to Object.
            output.U(:, :, frame_number) =  UF;
            output.V(:, :, frame_number) =  VF;
            
            % Plot for Testing
            % figure(frame_number)
            % hold on
            % contourf(X, Y, UF, 500, 'lineStyle', 'none');
            % axis equal
            % colormap parula
            % plot(x, wave_profile - vertical_offset, 'Color', 'red', 'LineWidth', 2)
            % xline(left_bound_value)
            % xline(right_bound_value)
            % yline(top_bound_value + vertical_offset);
            % hold off
            % title(frame_number)
            % xlim([-150, 150])
     
        end
        

        %%% Statistical Filtering in Time
        dirty_U_time_mean = mean(output.U, 3, 'omitnan');
        dirty_V_time_mean = mean(output.V, 3, 'omitnan');
        
        dirty_U_time_stdv = std(output.U, 1, 3, 'omitnan');
        dirty_V_time_stdv = std(output.V, 1, 3, 'omitnan');
        
        fprintf('\n<vector2matlab2D> Applying Statistical Filter... \n');
        for frame_number = 1:D
            
            % Print Progress.
            progressbarText(frame_number/D);
            
            % Take instantaneous images of u, v
            u_slice = output.U(:, :, frame_number);
            v_slice = output.V(:, :, frame_number);
            
            % Fiter statistically through time
            u_slice(u_slice < (dirty_U_time_mean - std_tol * dirty_U_time_stdv)) = nan;
            u_slice(u_slice > (dirty_U_time_mean + std_tol * dirty_U_time_stdv)) = nan;

            v_slice(v_slice < (dirty_V_time_mean - std_tol * dirty_V_time_stdv)) = nan;
            v_slice(v_slice > (dirty_V_time_mean + std_tol * dirty_V_time_stdv)) = nan;
            
            % Reassign values to output 
            output.U(:, :, frame_number) = u_slice;
            output.V(:, :, frame_number) = v_slice;
        end
        
   
        % Add Image/Data Parameters to struct file.
        output.X = X - left_bound_value;        % Place x = 0 at left corner
        output.Y = Y;                           % Place y = 0 at still surface
        output.D = D;
        
        % Save Matlab File.
        fprintf('\n<vector2matlab2D> Saving Data to File... \n');
        save(out_path, 'output');
        fprintf('<vector2matlab2D> Data Save Complete \n\n')
        
    end
end
    