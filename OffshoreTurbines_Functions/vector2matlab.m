% This function converts DaVis vector data (.vc7) files into a Matlab
% Struct file for easy manipulation in Matlab.
% Ondrej Fercak, Zein Sadek, 3/21/2022

% file_path:    Folder where DaVis (.vc7) files are stored.
% out_path:     Folder where new struct file will be saved.
% out_name:     Name of new struct file.

function output = vector2matlab(file_path, out_path)

    % Path for All Instantenious Snapshots for Specified Conditions.
    file_name   = dir([file_path,'/*.vc7']); 

    % Check if Input is Readable
    if isempty(file_name)
     fprintf('\n** INPUT FILES NOT FOUND! **\n')
     output = NaN;

    else

        % Check if Save Folder Exists. [if not, create]
        if exist(out_path, 'file')
            fprintf('<vector2matlab> *Save Folder was Previously Created. \n')
        else
            fprintf('<vector2matlab> *Creating New Save Folder. \n')
            %mkdir(out_path);
        end

        % Define Image Depth/Length [L] from First Frame.
        D           = length(file_name);
    
        % Loop Through Each Frame in Folder.
        fprintf('\n<vector2matlab> PROGRESS: ');
        for frame_number = 1:D

            % Print Progress.
            progressbarText(frame_number/D);

            % Load data.
            data        = readimx([file_path, '\', file_name(frame_number).name]);
            names       = data.Frames{1,1}.ComponentNames;        
            U0_index    = find(strcmp(names, 'U0'));
            V0_index    = find(strcmp(names, 'V0'));
            W0_index    = find(strcmp(names, 'W0'));
    
            UF = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
            VF = data.Frames{1,1}.Components{V0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{V0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{V0_index,1}.Scale.Offset;
            WF = data.Frames{1,1}.Components{W0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{W0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{W0_index,1}.Scale.Offset;
    
            % Correct Sign, Direction, and Add Data to Object.
            output.U(:, :, frame_number) =  rot90(WF);
            output.V(:, :, frame_number) =  -1 * rot90(UF);
            output.W(:, :, frame_number) =  rot90(VF);
        
    
        end
    
        % Add Image/Data Parameters to struct file.
        nf = size(output.U);
        x = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).*data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
        y = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).*data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
        [Y, X] = meshgrid(x, y);
        output.X = (rot90(-X));
        output.Y = (rot90(-Y));
        output.D = D;
        
        % Save Matlab File.
        fprintf('\n<vector2matlab> Saving Data to File... \n');
        %file_save = strcat(out_path, '/', out_name, '.mat');
        save(out_path, 'output');
        clc; fprintf('<vector2matlab> Data Save Complete \n')
        
    end
end
    