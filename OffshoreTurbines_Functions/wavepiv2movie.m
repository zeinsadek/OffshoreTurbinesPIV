function wavepiv2movie(raw_path, piv_path, constants)

    addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/readimx-v2.1.8-osx/');
    addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Functions/');
    %addpath('/Users/zeinsadek/Desktop/Experiments/PIV/Processing/Functions/Inpaint_nans/Inpaint_nans/')

    % Video Settings
    num_frames         = constants.num_frames;
    fps                = constants.fps;
    recording_name     = constants.recording_name;
    cmap_perc          = constants.cmap_perc;
    figure_file        = constants.figure_file;
    
    % Edge Detection Constantss
    background_removal = constants.background_removal;
    std_tol            = constants.std_tol;
    canny_lower        = constants.canny_lower;
    canny_upper        = constants.canny_upper;
    grad_tol           = constants.grad_tol;
    nan_dist           = constants.nan_dist;
    
    % Wave Constants
    wave_amplitude     = constants.wave_amplitude;
    wave_length        = constants.wave_length;
    vertical_offset    = constants.vertical_offset;
    wave_type          = constants.wave_type;
    cos_fit            = @(b, v) wave_amplitude * cos(2 * pi * (v - b(1)) / wave_length) + vertical_offset;

    % Define Images
    raw_image_name   = dir([raw_path, '/*.im7']);
    piv_image_name   = dir([piv_path, '/*.vc7']);

    % Define Image Dimensions
    data     = readimx([piv_path, '\', piv_image_name(1).name]);
    names    = data.Frames{1,1}.ComponentNames;        
    U0_index = find(strcmp(names, 'U0'));
    UF       = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
    nf       = size(UF);
    x        = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).* data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
    y        = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).* data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
    [X, Y]   = meshgrid(x, y);

    
    % Video Writer
    u_frames = [];
    writerObj_u = VideoWriter(strcat(figure_file, '/', recording_name, '_u_', num2str(num_frames), '_frames_', num2str(fps), '_FPS'), 'MPEG-4');
    writerObj_u.FrameRate = fps;
    
    v_frames = [];
    writerObj_v = VideoWriter(strcat(figure_file, '/', recording_name, '_v_', num2str(num_frames), '_frames_', num2str(fps), '_FPS'), 'MPEG-4');
    writerObj_v.FrameRate = fps;

    % Loop Through Each Frame in Folder.
    fprintf('\n<wavepiv2movie> PROGRESS: \n');
    for frame_number = 1:num_frames

        % Print Progress.
        progressbarText(frame_number/num_frames);

        % Load data.
        raw         = readimx([raw_path, '\', raw_image_name(frame_number).name]);
        data        = readimx([piv_path, '\', piv_image_name(frame_number).name]);
        names       = data.Frames{1,1}.ComponentNames;        
        U0_index    = find(strcmp(names, 'U0'));
        V0_index    = find(strcmp(names, 'V0'));

        % Load Raw Image and PIV Vectors
        raw_image = raw.Frames{1,1}.Components{1,1}.Planes{1,1};
        UF        = data.Frames{1,1}.Components{U0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{U0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{U0_index,1}.Scale.Offset;
        VF        = data.Frames{1,1}.Components{V0_index,1}.Scale.Slope.*data.Frames{1,1}.Components{V0_index,1}.Planes{1,1} + data.Frames{1,1}.Components{V0_index,1}.Scale.Offset;

        % PIV Image Coordinates
        nf     = size(UF);
        x      = data.Frames{1,1}.Scales.X.Slope.*linspace(1, nf(1), nf(1)).* data.Frames{1,1}.Grids.X + data.Frames{1,1}.Scales.X.Offset;
        y      = data.Frames{1,1}.Scales.Y.Slope.*linspace(1, nf(2), nf(2)).* data.Frames{1,1}.Grids.Y + data.Frames{1,1}.Scales.Y.Offset;
        [X, Y] = meshgrid(x, y);

        % Align Images: Flip 'n Dip
        raw_image = fliplr(rot90(raw_image, -1));
        UF        = -1 * fliplr(rot90(UF, -1));
        VF        = fliplr(rot90(VF, -1));

        % Resize Raw Image to Fit into PIV Frame
        raw_image = imresize(raw_image, size(UF));

        % Edge Detection
        raw_image(raw_image < background_removal) = 0;
        wave_edge = edge(raw_image, 'Canny', [canny_lower, canny_upper]);
        wave_profile = zeros(1, nf(1));

        for i = 1:nf(1)
            vertical_slice   = wave_edge(:, i);
            [ones_r, ~]      = find(vertical_slice == 1);
            size_ones        = size(ones_r);
            len              = size_ones(1);
            if len == 0
                wave_profile(1, i) = nan;
            else
                wave_profile(1, i) = y(min(ones_r));
            end
        end

        % Interpolate over any weird kinks and nans
        spikes = find(abs(gradient(wave_profile)) >= grad_tol);
        wave_profile(spikes) = nan;

        % Remove values between nans if they are within specified distance
        for i = 1:length(spikes)
            first_nan = spikes(i);
            for j = 1:nan_dist
                second_nan = first_nan + j;
                if second_nan > length(x)
                    second_nan = length(x);
                end
                if isnan(wave_profile(second_nan))
                    wave_profile(first_nan:second_nan) = nan;
                end
            end
        end

        % Interpolate over nans
        wave_profile(isnan(wave_profile)) = interp1(x(~isnan(wave_profile)), wave_profile(~isnan(wave_profile)), x(isnan(wave_profile)));

        % If there are waves, replace bad profiles with cosine wave
        fit_nan_crop = ~isnan(wave_profile);
        fcn          = @(b) sum((cos_fit(b, x(fit_nan_crop)) - wave_profile(fit_nan_crop)).^2);                             
        fitted_phase = fminsearch(fcn, 0);

        if sum(~isnan(wave_profile)) < length(x)
            wave_profile = cos_fit(fitted_phase, x);   
        end

        % Statistical Filtering in Space
        frame_UF_mean = mean(UF, 'all', 'omitnan');
        frame_UF_stdv = std(UF, 0, 'all', 'omitnan');

        frame_VF_mean = mean(VF, 'all', 'omitnan');
        frame_VF_stdv = std(VF, 0, 'all', 'omitnan');

        UF(UF < (frame_UF_mean - std_tol * frame_UF_stdv)) = nan;
        UF(UF > (frame_UF_mean + std_tol * frame_UF_stdv)) = nan;

        VF(VF < (frame_VF_mean - std_tol * frame_VF_stdv)) = nan;
        VF(VF > (frame_VF_mean + std_tol * frame_VF_stdv)) = nan;

        % Fill in removed values (only for video purposes for now)
%         UF = inpaint_nans(im2gray(double(UF)));
%         VF = inpaint_nans(im2gray(double(VF)));

        % Crop water
        UF(Y < wave_profile) = nan;
        VF(Y < wave_profile) = nan;


        %%% Plot/Video
        if frame_number == 1
            u_max = (1 - cmap_perc) * max(UF, [], 'all');
            u_min = (1 + cmap_perc) * min(UF, [], 'all');
            
%             v_max = (1 - cmap_perc) * min(VF, [], 'all');
%             v_min = (1 + cmap_perc) * min(VF, [], 'all');
            
            v_max = 1;
            v_min = -1;
        end
        
        % U
        fig = figure(1);
        contourf(X, Y, UF, 500, 'lineStyle', 'none');
        axis equal
        colormap parula
        ax = gca;
        set(ax,'color','w');
        ax.CLim = [u_min, u_max];
        title(strcat(recording_name, ': Frame Number', {' '}, num2str(frame_number)), 'Interpreter', 'none')
        hold on
        plot(x, wave_profile, 'Color', 'red', 'LineWidth', 2)
        hold off
        xlim([-110,110])
        ylim([-120,110])
        xlabel('x [mm]')
        ylabel('y [mm]')
        colorbar()
        drawnow;
        set(fig,'renderer','zbuffer')
        F_u = getframe(fig);
        u_frames = [u_frames F_u];
        
        % V
        fig = figure(2);
        contourf(X, Y, VF, 500, 'lineStyle', 'none');
        axis equal
        colormap parula
        ax = gca;
        set(ax,'color','w');
        ax.CLim = [v_min, v_max];
        title(strcat(recording_name, ': Frame Number', {' '}, num2str(frame_number)), 'Interpreter', 'none')
        hold on
        plot(x, wave_profile, 'Color', 'red', 'LineWidth', 2)
        hold off
        xlim([-110,110])
        ylim([-120,110])
        xlabel('x [mm]')
        ylabel('y [mm]')
        colorbar()
        drawnow;
        set(fig,'renderer','zbuffer')
        F_v = getframe(fig);
        v_frames = [v_frames F_v];
        end

    close all;
    % open the video writer
    open(writerObj_u);
    open(writerObj_v);
    
    for i=1:length(u_frames)
        u_frame = u_frames(i);  
        v_frame = v_frames(i);  
        
        writeVideo(writerObj_u, u_frame);
        writeVideo(writerObj_v, v_frame);
    end
    
    close(writerObj_u);
    close(writerObj_v);

end

