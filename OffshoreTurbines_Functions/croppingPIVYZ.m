function output = croppingPIVYZ(data, waves_data, details, out_path)

    fprintf('<croppingPIVXZ> Cropping Instantaneous Fields...\n');

    % Halim edit to be able to open
    output = matfile(out_path, 'Writable', true);

    % Number of images
    D = data.D;

    % Loop thorugh frames
    for frame = 1:D

        % Print Progress. 
        progressbarText(frame/D);
    
        % Load frames
        X = data.X;
        Y = data.Y;
        U = data.U(:,:,frame).';
        V = data.V(:,:,frame).';
        W = data.W(:,:,frame).';
        
        % Set ouside of calibration plate to NANs
        U(X > 100 | X < -100) = nan;
        V(X > 100 | X < -100) = nan;
        W(X > 100 | X < -100) = nan;
        
        % Initial, uncropped x positions from DaVis
        x = X(1,:);
        
        %%% LHS
        % Find index of value closest to what we want to crop to
        left_bound = -100;
        [~, left_bound_idx] = min(abs(x - left_bound));
        
        % Truncate relavant portion of array
        X(:, 1:left_bound_idx) = [];
        Y(:, 1:left_bound_idx) = [];
        U(:, 1:left_bound_idx) = [];
        V(:, 1:left_bound_idx) = [];
        W(:, 1:left_bound_idx) = [];
        
        %%% RHS
        % Redefine x since it has been partially cropped
        x = X(1,:);
        % Find index of value closest to what we want to crop to
        right_bound = 100;
        [~, right_bound_idx] = min(abs(x - right_bound));
        
        % Truncate relavant portion of array
        X(:, right_bound_idx:end) = [];
        Y(:, right_bound_idx:end) = [];
        U(:, right_bound_idx:end) = [];
        V(:, right_bound_idx:end) = [];
        W(:, right_bound_idx:end) = [];
    
        % Flip components to have flow be left to right
        U = fliplr(U);
        V = fliplr(V);
        W = fliplr(W);
        
        % Crop below wave
        nf   = size(U);
        wave = imresize(waves_data.wave_profiles(frame,:),[1,nf(2)]);
        waves(frame, :) = wave;
        
        % Delete physically masked portion. Only for Plane 1
        if details.plane == 1
            if contains(details.arrangement, 'Floating') == 1
                cutoff = -20;
                U(X < cutoff) = nan;
                V(X < cutoff) = nan;
                W(X < cutoff) = nan;
                wave(unique(X) < cutoff) = nan;
            end
        else
            cutoff = -100;
        end
        
        % Clean up blank spots in wave
        %%% BULLETPROOF THIS PART OF THE CODE
        x = unique(X).';
        [~, interp_idx] = min(abs(x - cutoff));
        if sum(isnan(wave(interp_idx:end))) < 100 
            interp_x = x(interp_idx:end);
            interp_wave = wave(interp_idx:end);
            interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
            
            % Fill in holes
            waves(frame, interp_idx:end) = interp_wave;
        end
    
        % Crop below wave
        U(Y < waves(frame,:)) = nan;
        V(Y < waves(frame,:)) = nan;
        W(Y < waves(frame,:)) = nan;

        % Re-written to work with matfile()
        UFs(:, :, frame) = U;
        VFs(:, :, frame) = V;
        WFs(:, :, frame) = W;

    end

    % Exclude frames where no wave was detected
    wave_mask = ~isnan((sum(waves(:, interp_idx:end), 2)));

    UFs = UFs(:, :, wave_mask);
    VFs = VFs(:, :, wave_mask);
    WFs = WFs(:, :, wave_mask);
    waves = waves(wave_mask, :);
    
    % Save to matfile
    output.D = sum(wave_mask);
    output.U = UFs;
    output.V = VFs;
    output.W = WFs;
    output.waves = waves;

    % Save Matlab File.
    fprintf('<croppingPIVXZ> Saving Data to File... \n');
    clc; fprintf('<croppingPIVXZ> Data Save Complete \n')
end