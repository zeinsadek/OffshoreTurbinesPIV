% This function converts DaVis vector data (.vc7) files into a Matlab
% Struct file for easy manipulation in Matlab.
% Ondrej Fercak, Zein Sadek, 3/21/2022

% file_path:    Folder where DaVis (.vc7) files are stored.
% out_path:     Folder where new struct file will be saved.
% out_name:     Name of new struct file.

function output = vector2matlabPIVXZ(frames, file_path, out_path)

    % Path for All Instantenious Snapshots for Specified Conditions\
    file_name = strcat(frames.common, '.vc7');
    D = length(frames.common);

    % Check if Input is Readable
    if isempty(dir([file_path,'/*.vc7']))
     fprintf('\n** INPUT FILES NOT FOUND! **\n')
     output = NaN;

    else

        % Check if Save Folder Exists. [if not, create]
        if exist(out_path, 'file')
            fprintf('<vector2matlab> *Save Folder was Previously Created. \n')
        else
            fprintf('<vector2matlab> *Creating New Save Folder. \n')
        end
    
        % Loop Through Each Frame in Folder.
        fprintf('\n<vector2matlab> PROGRESS: ');
        for frame_number = 1:D

            % Print Progress.
            progressbarText(frame_number/D);

            % Load data.
            data        = readimx(char(strcat(file_path, '/', file_name(frame_number))));
            names       = data.Frames{1,1}.ComponentNames;        
            U0_index    = find(strcmp(names, 'U0'));
            V0_index    = find(strcmp(names, 'V0'));
            W0_index    = find(strcmp(names, 'W0'));
    
            UF = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
            VF = data.Frames{1,1}.Components{V0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{V0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{V0_index,1}.Scale.Offset;
            WF = data.Frames{1,1}.Components{W0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{W0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{W0_index,1}.Scale.Offset;
    
            % Correct Sign, Direction, and Add Data to Object.
            output.U(:, :, frame_number) =  -UF;
            output.V(:, :, frame_number) =  VF;
            output.W(:, :, frame_number) =  WF;

        end
        
        %%% Statistical Filtering in Time
        U_mean = mean(output.U, 3, 'omitnan');
        V_mean = mean(output.V, 3, 'omitnan');
        W_mean = mean(output.W, 3, 'omitnan');

        U_stdv = std(output.U, 1, 3, 'omitnan');
        V_stdv = std(output.V, 1, 3, 'omitnan');
        W_stdv = std(output.W, 1, 3, 'omitnan');

        std_tol = 4;
        fprintf('\n<vector2matlab2D> Applying Statistical Filter... STD = %1.0f\n', std_tol);
        for frame_number = 1:D

            % Print Progress.
            progressbarText(frame_number/D);

            % Take instantaneous images of u, v, w
            u = output.U(:, :, frame_number);
            v = output.V(:, :, frame_number);
            w = output.W(:, :, frame_number);

            % Fiter statistically through time
            u(u < (U_mean - std_tol * U_stdv)) = nan;
            u(u > (U_mean + std_tol * U_stdv)) = nan;

            v(v < (V_mean - std_tol * V_stdv)) = nan;
            v(v > (V_mean + std_tol * V_stdv)) = nan;

            w(w < (W_mean - std_tol * W_stdv)) = nan;
            w(w > (W_mean + std_tol * W_stdv)) = nan;

            % Reassign values to output 
            output.U(:, :, frame_number) = u;
            output.V(:, :, frame_number) = v;
            output.W(:, :, frame_number) = w;
        end
    
        % Add Image/Data Parameters to struct file.
        nf = size(output.U);
        x = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
        y = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
        [X, Y] = meshgrid(x, y);
        output.X = X;
        output.Y = Y;
        output.D = D;
        
        % Save Matlab File.
        fprintf('\n<vector2matlab> Saving Data to File... \n');
        save(out_path, 'output', '-v7.3');
        clc; fprintf('<vector2matlab> Data Save Complete \n')
        
    end
end
    