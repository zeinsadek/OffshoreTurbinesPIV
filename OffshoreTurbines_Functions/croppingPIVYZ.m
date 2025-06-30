function output = croppingPIVYZ(data, waves_data, out_path)

    addpath('C:\Users\ofercak\Desktop\Zein\PIV\Inpaint_nans');
    fprintf('<croppingPIVYZ> Cropping Instantaneous Fields...\n');

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
        
        % Initial, uncropped x and y positions from DaVis
        x = X(1,:);
        y = Y(:,1);
        
        %%% LHS
        % Find index of value closest to what we want to crop to
        left_bound = 100;
        [~, left_bound_idx] = min(abs(x - left_bound));
         
        %%% RHS
        % Find index of value closest to what we want to crop to
        right_bound = -100;
        [~, right_bound_idx] = min(abs(x - right_bound));

        %%% TOP
        % Find index of value closest to what we want to crop to
        top_bound = 100;
        [~, top_bound_idx] = min(abs(y - top_bound));

        %%% BOTTOM
        bottom_bound = -150;
        [~, bottom_bound_idx] = min(abs(y - bottom_bound));


        %%% ZEIN NEW: better, cleaner way of cropping vectors
        X = X(top_bound_idx:bottom_bound_idx, left_bound_idx:right_bound_idx);
        Y = Y(top_bound_idx:bottom_bound_idx, left_bound_idx:right_bound_idx);
        U = U(top_bound_idx:bottom_bound_idx, left_bound_idx:right_bound_idx);
        V = V(top_bound_idx:bottom_bound_idx, left_bound_idx:right_bound_idx);
        W = W(top_bound_idx:bottom_bound_idx, left_bound_idx:right_bound_idx);

        %%% NEW: Fill in salt+peper holes w/ interpolation\
        U(U == 0) = nan;
        V(V == 0) = nan;
        W(W == 0) = nan;

        % U = inpaint_nans(double(U));
        % V = inpaint_nans(double(V));
        % W = inpaint_nans(double(W));
        
        % Crop below wave
        nf   = size(U);
        wave = imresize(waves_data.wave_profiles(frame,:),[1,nf(2)]);
        waves(frame, :) = fliplr(wave);

        U(Y < wave) = nan;
        V(Y < wave) = nan;
        W(Y < wave) = nan;

        %%% ZEIN: fliplr to get positive-spanwise coordinate pointing
        %%% correctly
        U = fliplr(U);
        V = fliplr(V);
        W = fliplr(W);

        % Re-written to work with matfile()
        UFs(:, :, frame) = U;
        VFs(:, :, frame) = V;
        WFs(:, :, frame) = W;

    end

    % Exclude frames where no wave was detected
    % wave_mask = ~isnan((sum(waves, 2)));
    % UFs = UFs(:, :, wave_mask);
    % VFs = VFs(:, :, wave_mask);
    % WFs = WFs(:, :, wave_mask);
    % waves = waves(wave_mask, :);
    
    % Save to matfile
    output.D = D;
    %%% ZEIN: fliplr to get positive-spanwise coordinate pointing
    %%% correctly
    output.X = -1 * X;
    output.Y = Y;
    output.U = UFs;
    output.V = VFs;
    output.W = WFs;
    output.waves = waves;

    % Save Matlab File.
    fprintf('<croppingPIVYZ> Saving Data to File... \n');
    clc; fprintf('<croppingPIVYZ> Data Save Complete \n')
end