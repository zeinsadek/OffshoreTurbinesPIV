% This function converts the Matlab vector data from PIV to Means 
% and Reynolds Stresses for further processing.
% Ondrej Fercak, Zein Sadek, 3/21/2022

% out_path:     Folder where new struct file will be saved.
% out_name:     Name of new struct file.
% inst_struct:  Matlab data struct as input for calculations.

function output = data2meansPIVXZ(data, out_path)

    % Check if Save Folder Exists. [if not, create]
    if exist(out_path, 'file')
        fprintf('<data2meansPIVXZ> *Save Folder was Previously Created. \n')
    else
        fprintf('<data2meansPIVXZ> *Creating New Save Floder. \n')
    end

    D = data.D;
    fprintf('D Check = %d! \n', D)

    inst_U  = data.U;
    inst_V  = data.V;
    inst_W  = data.W;
    X       = data.X;
    Y       = data.Y;


    % Calculate Velocity Means
    output.u = mean(inst_U, 3, 'omitnan');
    output.v = mean(inst_V, 3, 'omitnan');
    output.w = mean(inst_W, 3, 'omitnan');

    % Create Reynolds Stress Objects
    uu_p = zeros(size(inst_U));
    vv_p = zeros(size(inst_U));
    ww_p = zeros(size(inst_U));
    
    uv_p = zeros(size(inst_U));
    uw_p = zeros(size(inst_U));
    vw_p = zeros(size(inst_U));

    % Loop Through Each Frame in Struct.
    fprintf('\n<data2meansPIVXZ> PROGRESS: \n');
    for frame_number = 1:D
        
        % Print Progress.
        progressbarText(frame_number/D);
        
        % Instantaneous Fluctuations.
        u_pi = inst_U(:, :, frame_number) - output.u;
        v_pi = inst_V(:, :, frame_number) - output.v;
        w_pi = inst_W(:, :, frame_number) - output.w;

        % Instantaneous Stresses.
        uu_pi = u_pi.*u_pi;
        vv_pi = v_pi.*v_pi;
        ww_pi = w_pi.*w_pi;

        uv_pi = u_pi.*v_pi;
        uw_pi = u_pi.*w_pi;
        vw_pi = v_pi.*w_pi;

        % Array of Mean Stresses.
        uu_p(:, :, frame_number) = uu_pi;
        vv_p(:, :, frame_number) = vv_pi;
        ww_p(:, :, frame_number) = ww_pi;

        uv_p(:, :, frame_number) = uv_pi;
        uw_p(:, :, frame_number) = uw_pi;
        vw_p(:, :, frame_number) = vw_pi;

    end

    % Mean Stresses.
    output.uu = mean(uu_p, 3, 'omitnan');
    output.vv = mean(vv_p, 3, 'omitnan');
    output.ww = mean(ww_p, 3, 'omitnan');

    output.uv = mean(uv_p, 3, 'omitnan');
    output.uw = mean(uw_p, 3, 'omitnan');
    output.vw = mean(vw_p, 3, 'omitnan');
    
    % output.u(output.u==0)   = NaN;
    % output.v(output.v==0)   = NaN;
    % output.w(output.w==0)   = NaN;
    % output.uu(output.uu==0) = NaN;
    % output.vv(output.vv==0) = NaN;
    % output.ww(output.ww==0) = NaN;
    % output.uv(output.uv==0) = NaN;
    % output.uw(output.uw==0) = NaN;
    % output.vw(output.vw==0) = NaN;

    output.X = X;
    output.Y = Y;
    output.D = D;

    % Save waves for convenience
    output.Waves = data.waves;
    
    % Save Matlab File.
    fprintf('<data2meansPIVXZ> Saving Data to File... \n');
    save(out_path, 'output');
    clc; fprintf('<data2meansPIVXZ> Data Save Complete \n')
end
