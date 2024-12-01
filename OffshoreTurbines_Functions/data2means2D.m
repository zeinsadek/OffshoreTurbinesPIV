% This function converts the Matlab vector data from PIV to Means 
% and Reynolds Stresses for further processing.
% Ondrej Fercak, Zein Sadek, 3/21/2022

% out_path:     Folder where new struct file will be saved.
% out_name:     Name of new struct file.
% inst_struct:  Matlab data struct as input for calculations.

function output = data2means2D(out_path, inst_struct, waves, phase_average_struc, constants, depth)

    % Check if Save Folder Exists. [if not, create]
    if exist(out_path, 'file')
        fprintf('<data2means2D> *Save Folder was Previously Created. \n')
    else
        fprintf('<data2means2D> *Creating New Save Floder. \n')
    end
    
    if nargin == 5
        D = inst_struct.D;
    elseif nargin == 6
        D = depth;
    else
        fprintf('Input Error!')
    end

    D = depth;

    fprintf('D Check = %d! \n', D)

    % Dimensions
    X              = inst_struct.X;
    x              = unique(X);
    Y              = inst_struct.Y;
    inst_u         = inst_struct.U;
    inst_v         = inst_struct.V;
    wave_profiles  = waves.wave_profiles;
    
    left_bound_value  = constants.left_bound_value;
    right_bound_value = constants.right_bound_value;
    range             = abs(left_bound_value) + abs(right_bound_value);
    
    wave_length       = constants.wave_length;
    wave_amplitude    = constants.wave_amplitude;
    cos_fit           = @(b, v) wave_amplitude * cos(2 * pi * (v - (range/2) - b(1)) / wave_length);
    phase_offset      = constants.phase_offset;
    wave_type         = constants.wave_type;
    vertical_offset   = constants.vertical_offset;
    
    
    
    if isa(phase_average_struc, 'double') == 1
        phase_average_idx = zeros(1,D);
    elseif isa(phase_average_struc, 'struct') == 1
        phase_average_idx = phase_average_struc.phase_average_idx;
    end
    
    %%% Calculate Ensemble Average Velocities
    output.ensemble.u = mean(inst_u, 3, 'omitnan');
    output.ensemble.v = mean(inst_v, 3, 'omitnan');

    % Crop Ensembles Below Surface
    ensemble_max_wave_profile        = max(wave_profiles , [], 1);
    ensemble_max_wave_profile        = imresize(ensemble_max_wave_profile, [1, length(x)]);
    output.ensemble.max_wave_profile = ensemble_max_wave_profile;

    output.ensemble.u(Y < ensemble_max_wave_profile) = nan;
    output.ensemble.v(Y < ensemble_max_wave_profile) = nan;

    if wave_type == '0'
        output.ensemble.u(Y < 0) = nan;
        output.ensemble.v(Y < 0) = nan;
    end


    % Create Reynolds Stress Objects
    uu_ensemble = zeros(length(Y(:, 1)), length(X(1, :)), D);
    vv_ensemble = zeros(length(Y(:, 1)), length(X(1, :)), D);
    uv_ensemble = zeros(length(Y(:, 1)), length(X(1, :)), D);
    
   
    %%% Phase Average Velocities: Re-Written as Loop
    if wave_type ~= '0'
        for phase = 1:4

            % Save indicies of frames used in specific phase average
            output.phase(phase).idxs = find(phase_average_idx == phase);
            
            % Compute phase averages
            output.phase(phase).u = mean(inst_u(:, :, output.phase(phase).idxs), 3, 'omitnan');
            output.phase(phase).v = mean(inst_v(:, :, output.phase(phase).idxs), 3, 'omitnan');
            
            % Also save particular wave profiles
            output.phase(phase).waves = wave_profiles(output.phase(phase).idxs, :);
            
            % Crop Below Wave
            max_wave_profile = max(wave_profiles(output.phase(phase).idxs, :), [], 1);
            max_wave_profile = imresize(max_wave_profile, [1, length(x)]);
    
            output.phase(phase).reference_wave   = cos_fit(phase_offset(phase), x);
            output.phase(phase).max_wave_profile = max_wave_profile;
    
            output.phase(phase).u(Y < max_wave_profile) = nan;
            output.phase(phase).v(Y < max_wave_profile) = nan;
        end
    end
    
    %%% Ensemble Stresses
    % Loop Through Each Frame in Struct.
    fprintf('\n<data2means2D> Ensemble Computations \n');
    fprintf('\n<data2means2D> PROGRESS: \n');
    for frame_number = 1:D
        
        % Print Progress.
        progressbarText(frame_number/D);
        
        % Compute Fluctuations
        u_fluc = inst_u(:, :, frame_number) - output.ensemble.u;
        v_fluc = inst_v(:, :, frame_number) - output.ensemble.v;
        
        % Instantaneous Stresses
        uu_ensemble(:, :, frame_number) = u_fluc .* u_fluc;
        vv_ensemble(:, :, frame_number) = v_fluc .* v_fluc;
        uv_ensemble(:, :, frame_number) = u_fluc .* v_fluc;
        
    end

    % Mean Ensemble Stresses
    output.ensemble.uu = mean(uu_ensemble, 3, 'omitnan');
    output.ensemble.vv = mean(vv_ensemble, 3, 'omitnan');
    output.ensemble.uv = mean(uv_ensemble, 3, 'omitnan');

    % Crop Below Surface
    output.ensemble.uu(Y < ensemble_max_wave_profile) = nan;
    output.ensemble.vv(Y < ensemble_max_wave_profile) = nan;
    output.ensemble.uv(Y < ensemble_max_wave_profile) = nan;

    if wave_type == '0'
        output.ensemble.uu(Y < 0) = nan;
        output.ensemble.vv(Y < 0) = nan;
        output.ensemble.uv(Y < 0) = nan;
    end
     
    if wave_type ~= '0'
        for phase = 1:4
            fprintf('\n<data2means2D> Phase %.f Computations \n', phase);
        
            % Number of images in each phase
            phase_D = length(output.phase(phase).idxs);
    
            % Temporary phase average stress containers
            uu_phase = zeros(length(Y(:, 1)), length(X(1, :)), phase_D);
            vv_phase = zeros(length(Y(:, 1)), length(X(1, :)), phase_D);
            uv_phase = zeros(length(Y(:, 1)), length(X(1, :)), phase_D);
            
            % fprintf('\n<data2means2D> PROGRESS: \n');
            for i = 1:phase_D
                
                % Specify Frame Number
                frame_number = output.phase(phase).idxs(i);
                
                % Print Progress.
                % progressbarText(frame_number/phase_D);
    
                % Compute  Fluctuations Relative to Phase Average Mean
                u_phase_fluc = inst_u(:, :, frame_number) - output.phase(phase).u;
                v_phase_fluc = inst_v(:, :, frame_number) - output.phase(phase).v;
    
                % Instantaneous Stresses.
                uu_phase(:, :, i) = u_phase_fluc .* u_phase_fluc;
                vv_phase(:, :, i) = v_phase_fluc .* v_phase_fluc;
                uv_phase(:, :, i) = u_phase_fluc .* v_phase_fluc;
                
                % Save Phase Average Stresses
                output.phase(phase).uu = mean(uu_phase, 3, 'omitnan');
                output.phase(phase).vv = mean(vv_phase, 3, 'omitnan');
                output.phase(phase).uv = mean(uv_phase, 3, 'omitnan');
            end
            
            % Crop Below Wave
            max_wave_profile = max(wave_profiles(output.phase(phase).idxs, :), [], 1);
            max_wave_profile = imresize(max_wave_profile, [1, length(x)]);
            
            output.phase(phase).uu(Y < max_wave_profile) = nan;
            output.phase(phase).vv(Y < max_wave_profile) = nan;
            output.phase(phase).uv(Y < max_wave_profile) = nan;
        end
    end
        
    output.X = X;
    output.Y = Y;
    output.D = D;
    
    %%% Save Matlab File.
    fprintf('\n<data2means2D> Saving Data to File... \n');
    save(out_path, 'output');
    clc; fprintf('\n<data2means2D> Data Save Complete \n')
end
