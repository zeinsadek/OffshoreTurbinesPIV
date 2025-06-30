function output = wavecropPIVXY(crop, waves, details, outpath)
    

    fprintf('<wavecropPIVXY> Cropping below waves...\n');

    % Halim edit to be able to open
    output = matfile(outpath, 'Writable', true);
    Y = crop.Y;
    D = crop.D;

    % Look for waves that were entered as all nans 
    if details.plane == 1
        if contains(details.arrangement, 'Floating') == 1
            cutoff = -20;
        end
    elseif details.plane == 4
        if contains(details.arrangement, 'Floating') == 1
            cutoff = 60;
        end
    else
        cutoff = -100;
    end

    % Try to clean up blank spots in wave
    x = crop.X(1,:);
    [~, cutoff_index] = min(abs(x - cutoff));

    % Define cutoff: how many NaNs would make a frame invalid
    nan_cutoff = size(waves, 2) - cutoff_index + 1;

    %%% ChatGPT
    % Get logical vector of invalid frames (i.e., misfired or unusable)
    if ismember(details.plane, [1,2,3])           
        is_invalid = sum(isnan(waves(:, cutoff_index:end)), 2) >= nan_cutoff;
    else
        is_invalid = sum(isnan(waves(:, 1:cutoff_index)), 2) >= nan_cutoff;
    end
    
    % Indices of valid and invalid frames
    valid_frames = find(~is_invalid);
    invalid_frames = find(is_invalid);


    for f = 1:length(valid_frames)

        % Progress bar
        progressbarText(f / D)

        % Load data
        u = crop.U(:, :, valid_frames(f));
        v = crop.V(:, :, valid_frames(f));
        w = crop.W(:, :, valid_frames(f));
        wave = waves(valid_frames(f), :);

        % Crop below wave
        u(Y < wave) = nan;
        v(Y < wave) = nan;
        w(Y < wave) = nan;

        % Save to output array
        UFs(:, :, f) = u;
        VFs(:, :, f) = v;
        WFs(:, :, f) = w;
        output_waves(f, :) = wave;
    end

    output.skip = invalid_frames;
    output.D = length(valid_frames);
    output.X = crop.X;
    output.Y = crop.Y;
    output.U =  UFs;
    output.V =  VFs;
    output.W =  WFs;
    % output.waves = waves;
    output.waves = output_waves;

    clc;
    fprintf('<wavecropPIVXY> Done saving!...\n');
end



