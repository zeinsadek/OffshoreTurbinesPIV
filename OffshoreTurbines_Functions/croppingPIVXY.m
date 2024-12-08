function output = croppingPIVXZ(data, waves, details, out_path)

    fprintf('<croppingPIVXZ> Cropping Instantaneous Fields...\n');
    D = data.D;
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
        
        if frame == 1
            size_PIV = size(X);
            output.waves = nan(data.D, size_PIV(2));
            output.U = nan(size_PIV(1), size_PIV(2), D);
            output.V = nan(size_PIV(1), size_PIV(2), D);
            output.W = nan(size_PIV(1), size_PIV(2), D);
        end
    
        % Flip components to have flow be left to right
        U = fliplr(U);
        V = fliplr(V);
        W = fliplr(W);
        
        % Crop below wave
        nf   = size(U);
        wave = imresize(waves.wave_profiles(frame,:),[1,nf(2)]);
        
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
    
        % Save Crops
        % output.waves(frame,:) = resized_wave;
    
        % Clean up blank spots in wave
        %%% BULLETPROOF THIS PART OF THE CODE
        x = unique(X).';
        [~, interp_idx] = min(abs(x - cutoff));
        if sum(isnan(wave(interp_idx:end))) < 100 
            interp_x = x(interp_idx:end);
            % interp_wave = output.waves(frame,interp_idx:end);
            interp_wave = wave(interp_idx:end);
            interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
            
            % Save wave and fill in holes
            output.waves(frame,:) = wave;
            output.waves(frame, interp_idx:end) = interp_wave;
        end
    
        % Crop below wave
        U(Y < output.waves(frame,:)) = nan;
        V(Y < output.waves(frame,:)) = nan;
        W(Y < output.waves(frame,:)) = nan;

        % Save outputs
        output.X = X;
        output.Y = Y;
        output.U(:,:,frame) = U;
        output.V(:,:,frame) = V;
        output.W(:,:,frame) = W;
    end

    % Exclude frames where no wave was detected
    wave_mask = ~isnan((sum(output.waves(:, interp_idx:end), 2)));
    
    output.D = sum(wave_mask);
    output.U = output.U(:,:,wave_mask);
    output.V = output.V(:,:,wave_mask);
    output.W = output.W(:,:,wave_mask);
    output.waves = output.waves(wave_mask,:);


    
    % Save Matlab File.
    fprintf('<croppingPIVXZ> Saving Data to File... \n');
    save(out_path, 'output', '-v7.3');
    clc; fprintf('<croppingPIVXZ> Data Save Complete \n')
end