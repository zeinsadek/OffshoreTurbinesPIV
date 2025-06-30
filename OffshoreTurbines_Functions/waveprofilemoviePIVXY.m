function waveprofilemoviePIVXY(waves, x, frames, savePath, frameRate)
% generateWaveProfileMovie - Generates and saves a movie of wave profiles.
%
% Syntax: generateWaveProfileMovie(dataStruct, savePath, frameRate)
%
% Inputs:
%   dataStruct - Struct with fields:
%       .x         -> 1 x N vector of x-coordinates
%       .waves     -> M x N matrix of wave profiles (M frames)
%   savePath   - Full file path to save the movie (e.g. 'C:/videos/waves.avi')
%   frameRate  - (Optional) Frame rate for saved video (default: 10)
%
% Output:
%   Saves a video file of the evolving wave profile.

    if nargin < 3
        frameRate = 15;
    end


    % Create a video writer object
    v = VideoWriter(savePath, 'MPEG-4');
    v.FrameRate = frameRate;
    open(v);

    % Set up the figure
    hFig = figure('Visible', 'off', 'Color', 'w');
    axis tight manual
    hold on

    % Define plot limits
    y_min = -120;
    y_max = -80;
    x_min = -100;
    x_max = 100;

    fprintf('<waveprofilemoviePIVXY> Starting movie...\n')
    for f = 1:length(frames.common)

        % Progress bar
        progressbarText(f / length(frames.common))

        % Clear figure each time to avoid overplotting
        clf(hFig);  
        plot(x, waves(f, :), 'b', 'LineWidth', 2);
        title(sprintf('Frame %s: Index %s', frames.common(f), num2str(f)));
        xlabel('x [mm]'); 
        ylabel('Wave Height');
        % axis([x_min, x_max, y_min, y_max]);
        axis equal
        xlim([x_min, x_max])
        ylim([y_min, y_max])
        grid on;

        % Capture frame
        frame = getframe(hFig);
        writeVideo(v, frame);
    end
    fprintf('<waveprofilemoviePIVXY> Finished movie!\n')

    close(v);
    close(hFig);
    
    clc;
    fprintf('<waveprofilemoviePIVXY> Movie saved!\n');
end
