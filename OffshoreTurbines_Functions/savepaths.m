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

    %%% Waves
    % Check if Waves subdirectory exist, else create
    waves_dir = fullfile(results_path, 'waves');
    if ~exist(waves_dir, 'dir')
        fprintf('<savepaths> Creating Waves Directory\n')
        mkdir(waves_dir);
    end

    % Check if Waves/Initial subdirectory exist, else create
    waves_init_dir = fullfile(waves_dir, 'initial');
    if ~exist(waves_init_dir, 'dir')
        fprintf('<savepaths> Creating Waves/Initial Directory\n')
        mkdir(waves_init_dir);
    end

    % Check if Waves/Refined subdirectory exist, else create
    waves_refined_dir = fullfile(waves_dir, 'refined');
    if ~exist(waves_refined_dir, 'dir')
        fprintf('<savepaths> Creating Waves/Refined Directory\n')
        mkdir(waves_refined_dir);
    end

    % Check if Waves/Refined/Rerefined Waves subdirectory exist, else create
    waves_refined_movie_dir = fullfile(waves_refined_dir, 'rerefined_movies');
    if ~exist(waves_refined_movie_dir, 'dir')
        fprintf('<savepaths> Creating Waves/Refined/Rerefined Movies Directory\n')
        mkdir(waves_refined_movie_dir);
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



    %%% CROP
    % Check if Cropped subdirectory exist, else create
    crop_dir = fullfile(results_path, 'cropped');
    if ~exist(crop_dir, 'dir')
        fprintf('<savepaths> Creating Crop Directory\n')
        mkdir(crop_dir);
    end

    % Check if Cropped/Initial subdirectory exist, else create
    crop_init_dir = fullfile(crop_dir, 'initial');
    if ~exist(crop_dir, 'dir')
        fprintf('<savepaths> Creating Crop/Initial Directory\n')
        mkdir(crop_init_dir);
    end

    % Check if Cropped/Final subdirectory exist, else create
    crop_final_dir = fullfile(crop_dir, 'final');
    if ~exist(crop_dir, 'dir')
        fprintf('<savepaths> Creating Crop/Final Directory\n')
        mkdir(crop_final_dir);
    end


    % Check if Figure subdirectory exist, else create
    figure_dir = fullfile(results_path, 'figures');
    if ~exist(figure_dir, 'dir')
        fprintf('<savepaths> Creating Figure Directory\n')
        mkdir(figure_dir);
    end
    
    % Create file paths for mat files
    output.frame  = fullfile(frames_dir, strcat(inpt_name, '_FRAMES.mat'));

    %%% Waves
    % Initial waves path
    output.wave.initial = fullfile(waves_init_dir , strcat(inpt_name, '_INITIAL_WAVES.mat'));
    % Refined waves path
    output.wave.refined = fullfile(waves_refined_dir , strcat(inpt_name, '_REFINED_WAVES.mat'));
    % Rerefined wave movie path
    output.wave.rerefined = fullfile(waves_refined_movie_dir , strcat(inpt_name, '_REREFINED_WAVES_MOVIE.mp4'));


    output.data   = fullfile(data_dir  , strcat(inpt_name, '_DATA.mat'));
    output.means  = fullfile(means_dir , strcat(inpt_name, '_MEANS.mat'));
    output.figure = figure_dir;

    %%% Crop
    % Initial crop path
    output.crop.initial = fullfile(crop_init_dir, strcat(inpt_name, '_INITIAL_CROPPED.mat'));
    % Final crop path
    output.crop.final   = fullfile(crop_final_dir, strcat(inpt_name, '_FINAL_CROPPED.mat'));
    

end