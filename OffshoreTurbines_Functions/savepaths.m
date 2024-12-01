function output = savepaths(results_path, inpt_name)

    % Check if save folder exists, else make it
    if ~exist(results_path, 'dir')
        fprintf('<savepaths> Creating Main Save Directory\n')
        mkdir(results_path);
    end

    % Check if Frames subdirectory exist, else create
    frames_dir = fullfile(results_path, 'frames');
    if ~exist(frames_dir, 'dir')
        fprintf('<savepaths> Creating Frames Directory\n')
        mkdir(frames_dir);
    end

    % Check if Waves subdirectory exist, else create
    waves_dir = fullfile(results_path, 'waves');
    if ~exist(waves_dir, 'dir')
        fprintf('<savepaths> Creating Waves Directory\n')
        mkdir(waves_dir);
    end

    % Check if Data subdirectory exist, else create
    data_dir = fullfile(results_path, 'data');
    if ~exist(data_dir, 'dir')
        fprintf('<savepaths> Creating Data Directory\n')
        mkdir(data_dir);
    end

    % Check if Data subdirectory exist, else create
    means_dir = fullfile(results_path, 'means');
    if ~exist(means_dir, 'dir')
        fprintf('<savepaths> Creating Means Directory\n')
        mkdir(means_dir);
    end

    % Check if Cropped subdirectory exist, else create
    crop_dir = fullfile(results_path, 'cropped');
    if ~exist(crop_dir, 'dir')
        fprintf('<savepaths> Creating Crop Directory\n')
        mkdir(crop_dir);
    end

    % Check if Figure subdirectory exist, else create
    figure_dir = fullfile(results_path, 'figures');
    if ~exist(figure_dir, 'dir')
        fprintf('<savepaths> Creating Figure Directory\n')
        mkdir(figure_dir);
    end
    
    % Create file paths for mat files
    output.frame  = fullfile(frames_dir, strcat(inpt_name, '_FRAMES.mat'));
    output.wave   = fullfile(waves_dir , strcat(inpt_name, '_WAVES.mat'));
    output.data   = fullfile(data_dir  , strcat(inpt_name, '_DATA.mat'));
    output.means  = fullfile(means_dir , strcat(inpt_name, '_MEANS.mat'));
    output.crop   = fullfile(crop_dir  , strcat(inpt_name, '_CROPPED.mat'));
    output.figure = figure_dir;

end