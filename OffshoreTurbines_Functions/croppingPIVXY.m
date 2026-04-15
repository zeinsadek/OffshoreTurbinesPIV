function output = croppingPIVXY(data, details, out_path)

    fprintf('<croppingPIVXY> Cropping Instantaneous Fields...\n');

    % Halim edit to be able to open
    output = matfile(out_path, 'Writable', true);

    % Number of images
    D = data.D;

    % % Keep track of frames that are skipped becase of missed waves
    % skip_count = 1;

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

       

        % Delete physically masked portion for Floating Plane 1
        if details.plane == 1
            % Floating
            if contains(details.arrangement, 'Floating') == 1
                cutoff = -20;
                U(X < cutoff) = nan;
                V(X < cutoff) = nan;
                W(X < cutoff) = nan;
                wave(X(1,:) < cutoff) = nan;
            end
            % Fixed-Bottom
            if contains(details.arrangement, 'Fixed') == 1
                cutoff = -80;
                U(X < cutoff) = nan;
                V(X < cutoff) = nan;
                W(X < cutoff) = nan;
                wave(X(1,:) < cutoff) = nan;
            end

        % Delete physically masked portion for Floating Plane 4
        elseif details.plane == 4
            if contains(details.arrangement, 'Floating') == 1
                cutoff = 50;
                U(X > cutoff) = nan;
                V(X > cutoff) = nan;
                W(X > cutoff) = nan;
                wave(X(1,:) > cutoff) = nan;
            end
        else
            cutoff = -100;
        end

        % Import wave
        nf   = size(U);
        wave = imresize(data.wave_profiles(frame, :), [1, nf(2)]);
        waves(frame, :) = wave;

        % Try to clean up blank spots in wave
        x = unique(X).';
        [~, interp_idx] = min(abs(x - cutoff));

        % Try to fix waves for planes 1, 2, or 3
        if ismember(details.plane, [1,2,3])
            if sum(isnan(wave(interp_idx:end))) < 100 
                interp_x = x(interp_idx:end);
                interp_wave = wave(interp_idx:end);
                interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
    
                % Fill in holes
                waves(frame, interp_idx:end) = interp_wave;
                % waves(frame, X(1,:) < cutoff) = nan;
                waves(frame, 1:interp_idx - 1) = nan;
            end
        
        % Fix waves for plane 4 since data is cropped on the right
        else
            if sum(isnan(wave(1:interp_idx))) < 100 
                interp_x = x(1:interp_idx);
                interp_wave = wave(1:interp_idx);
                interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
    
                % Fill in holes
                waves(frame, 1:interp_idx) = interp_wave;
                % waves(frame, X(1,:) > cutoff) = nan;
                waves(frame, interp_idx + 1:end) = nan;
            end

        end

        % Re-written to work with matfile()
        UFs(:, :, frame) = U;
        VFs(:, :, frame) = V;
        WFs(:, :, frame) = W;

    end

    % Save ouputs
    output.D = length(UFs);
    output.X = X;
    output.Y = Y;
    output.U =  UFs;
    output.V =  VFs;
    output.W =  WFs;
    output.waves = waves;

    % Save Matlab File.
    fprintf('<croppingPIVXZ> Saving Data to File... \n');
    clc; fprintf('<croppingPIVXZ> Data Save Complete \n')
end


%% ChatGPT

% function output = croppingPIVXY(data, details, out_path)
% 
%     fprintf('<croppingPIVXZ> Cropping Instantaneous Fields...\n');
% 
%     output = matfile(out_path, 'Writable', true);
% 
%     D = data.D;
% 
%     skip_count = 1;
%     % waves = NaN(D, size(data.X, 2));  % Preallocate
% 
%     for frame = 1:D
%         progressbarText(frame / D);
% 
%         X = data.X;
%         Y = data.Y;
%         U = data.U(:, :, frame).';
%         V = data.V(:, :, frame).';
%         W = data.W(:, :, frame).';
% 
%         U(X > 100 | X < -100) = nan;
%         V(X > 100 | X < -100) = nan;
%         W(X > 100 | X < -100) = nan;
% 
%         x = X(1, :);
% 
%         % LHS crop
%         left_bound = -100;
%         [~, left_bound_idx] = min(abs(x - left_bound));
%         X(:, 1:left_bound_idx) = [];
%         Y(:, 1:left_bound_idx) = [];
%         U(:, 1:left_bound_idx) = [];
%         V(:, 1:left_bound_idx) = [];
%         W(:, 1:left_bound_idx) = [];
% 
%         % RHS crop
%         x = X(1, :);
%         right_bound = 100;
%         [~, right_bound_idx] = min(abs(x - right_bound));
%         X(:, right_bound_idx:end) = [];
%         Y(:, right_bound_idx:end) = [];
%         U(:, right_bound_idx:end) = [];
%         V(:, right_bound_idx:end) = [];
%         W(:, right_bound_idx:end) = [];
% 
%         U = fliplr(U);
%         V = fliplr(V);
%         W = fliplr(W);
% 
%         nf = size(U);
%         wave = imresize(data.wave_profiles(frame, :), [1, nf(2)]);
%         x = unique(X).';
% 
%         if details.plane == 1 && contains(details.arrangement, 'Floating')
%             cutoff = -20;
%             U(X < cutoff) = nan;
%             V(X < cutoff) = nan;
%             W(X < cutoff) = nan;
%             wave(x < cutoff) = nan;
%         else
%             cutoff = -100;
%         end
% 
%         % Clean up blank spots in wave
%         [~, interp_idx] = min(abs(x - cutoff));
%         if sum(isnan(wave(interp_idx:end))) < 0.5 * length(wave(interp_idx:end))
%             interp_x = x(interp_idx:end);
%             interp_wave = wave(interp_idx:end);
%             interp_wave(isnan(interp_wave)) = interp1(interp_x(~isnan(interp_wave)), interp_wave(~isnan(interp_wave)), interp_x(isnan(interp_wave)), 'linear', 'extrap');
%             wave(interp_idx:end) = interp_wave;
%         end
% 
%         waves(frame, :) = wave;
% 
%         U(Y < wave) = nan;
%         V(Y < wave) = nan;
%         W(Y < wave) = nan;
% 
%         UFs(:, :, frame) = U;
%         VFs(:, :, frame) = V;
%         WFs(:, :, frame) = W;
% 
%         if all(isnan(wave))
%             skipped_frames(skip_count) = frame;
%             skip_count = skip_count + 1;
%         else
%             skipped_frames = nan;
%         end
%     end
% 
%     %% === WAVE INTERPOLATION FIX ===
%     nan_mask = isnan(waves);
% 
%     % Temporal interpolation first
%     for col = 1:size(waves, 2)
%         col_data = waves(:, col);
%         good_idx = find(~isnan(col_data));
%         if numel(good_idx) >= 2
%             waves(:, col) = interp1(good_idx, col_data(good_idx), (1:D)', 'linear', 'extrap');
%         end
%     end
% 
%     % Spatial interpolation for each bad frame
%     for t = 1:D
%         if any(nan_mask(t, :))
%             row_data = waves(t, :);
%             good_idx = find(~isnan(row_data));
%             if numel(good_idx) >= 2
%                 waves(t, :) = interp1(good_idx, row_data(good_idx), 1:length(row_data), 'pchip');
%             elseif numel(good_idx) == 1
%                 waves(t, :) = row_data(good_idx);
%             else
%                 % No valid data — use previous or next frame if possible
%                 if t > 1
%                     waves(t, :) = waves(t - 1, :);
%                 elseif t < D
%                     waves(t, :) = waves(t + 1, :);
%                 end
%             end
%         end
%     end
% 
%     % Smooth the final wave data
%     waves = smoothdata(waves, 1, 'movmean', 5);  % temporal
%     waves = smoothdata(waves, 2, 'movmean', 15); % spatial
% 
%     %% Write to file
%     wave_mask = true(D, 1);  % Keep all frames now that we filled wave
% 
%     output.D = sum(wave_mask);
%     output.X = X;
%     output.Y = Y;
%     output.skip = skipped_frames;
% 
%     output.U = UFs(:, :, wave_mask);
%     output.V = VFs(:, :, wave_mask);
%     output.W = WFs(:, :, wave_mask);
%     output.waves = waves(wave_mask, :);
% 
% 
%     % Optional: save skipped U frames (original before cropping)
%     if ~isnan(skipped_frames)
%         output.skipped.U = UFs(:, :, skipped_frames);
%         output.skipped.V = VFs(:, :, skipped_frames);
%         output.skipped.W = WFs(:, :, skipped_frames);
%         output.skipped.waves = waves(skipped_frames, :);
%     end
% 
%     fprintf('<croppingPIVXZ> Data Save Complete \n');
% end

