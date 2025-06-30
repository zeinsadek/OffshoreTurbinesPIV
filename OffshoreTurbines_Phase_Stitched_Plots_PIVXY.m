%% Stitched Phase Average Plots for WESC conference


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PATHS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc; clear; close all;
addpath('C:\Users\ofercak\Desktop\Zein\PIV\readimx-v2.1.9-win64');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\OffshoreTurbinesPIV\OffshoreTurbines_Functions');
addpath('C:\Users\ofercak\Desktop\Zein\PIV\colormaps');
fprintf('All Paths Imported...\n\n')

matfile_path = 'H:\Offshore';
arrangement = 'FWF_I';
wave_types  = {'AK12_LM50', 'AK12_LM33'};

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for wave = 1:length(wave_types)
    % Load data
    wave_type = wave_types{wave};
    caze = strcat(arrangement, '_', wave_type, '_PHASE_STITCHED.mat');
    tmp = load(fullfile(matfile_path, 'stitched', 'phase', caze));
    tmp = tmp.output.cropped;

    % Save to struct
    data.(wave_type) = tmp;
end

clear wave wave_type caze tmp

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT CONTOURS TOGETHER 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Freestream
u_inf = 4.2;

% Turbine diameter
D = 150;

% Hub height in mm
hub_height = 117;

% Reference wave equation
cos_fit = @(b, x) b(1) * cos(2 * pi * (x - b(2)) / b(3));

% Plot
clc; close all;
figure('color', 'white')
tiledlayout(4,2)

% Phase shifts
phase_shifts = [0, 1/4, 1/2, 3/4];

% Count tiles
tile_counter = 1;

% What component to plot
component = 'uv';

% Loop through cases
for phase = 1:4
    phase_shift = phase_shifts(phase);

    for wave = 1:length(wave_types)
        wave_type = wave_types{wave};
    
        % Load data
        X = data.(wave_type)(phase).X;
        Y = data.(wave_type)(phase).Y;
        u = double(data.(wave_type)(phase).(component) / (u_inf^2));
        max_wave = data.(wave_type)(phase).max_wave;

        % Reference wave
        wave_properties = namereader(wave_type);
        wavelength = wave_properties.wavelength;
        amplitude = (wavelength * wave_properties.steepness) / (2 * pi);
        amplitude = 0.5 * amplitude;
        wave_x = linspace(0, 5, 100);
        reference_wave = cos_fit([amplitude, phase_shift * wavelength, wavelength], wave_x);
    
        % Plot data
        h(tile_counter) = nexttile;
        hold on

        % Plot u 
        contourf(X / D, Y / D, u, 50, 'linestyle', 'none')
    
        % Plot max wave profile
        plot(X(1,:) / D, max_wave / D, 'color', 'red', 'linewidth', 2)

        % Plot reference wave
        plot(wave_x, reference_wave, 'color', 'black', 'linewidth', 2)
    
        % Plot hub and rotor tips
        yline(hub_height / D)
        yline(hub_height / D + 1/2, 'linestyle', '--')
        yline(hub_height / D - 1/2, 'linestyle', '--')
    
        % Plot settings
        hold off
        axis equal
        xlim([0, 5])

        % Set colorbar
        C = colorbar();
        C.Label.String = "$uv / u_{\infty}^2$";
        C.Label.Interpreter = "latex";
        C.Label.FontSize = 16;
    
        % Title
        title(sprintf('Phase %1.0f', phase), 'interpreter', 'none')

        % X label
        if ismember(tile_counter, [7,8])
            xlabel('$x / D$', 'interpreter', 'latex', 'FontSize', 14)
        end

        % Y label
        ylabel('$y / D$', 'interpreter', 'latex', 'fontsize', 14)

        % Increment tile counter
        tile_counter = tile_counter + 1;
    end
end

linkaxes(h, 'xy')
set(h, 'Colormap', coolwarm, 'CLim', [-10E-3, 5E-3])


clear wave X Y u max_wave h masked_u wake_center_indicies wave_type


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GAUSSIAN CENTER TRACKING 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Single phase
phase = 4;
wave_type = wave_types{2};

X = data.(wave_type)(phase).X / D;
Y = data.(wave_type)(phase).Y / D;
U = data.(wave_type)(phase).u;

max_wave = data.(wave_type)(phase).max_wave;

% U_blurred = juliaan_smooth(U, 10);

x = X(1,:);
y = Y(:,1);

% Gaussian equation 
gaussEqn = @(b, y) b(1) * exp(-((y - b(2)).^2) / (2 * b(3)^2));

% Crop to only look within rotor area
[~, bottom_index] = min(abs(y - ((hub_height/D) - 0.5)));
[~, top_index] = min(abs(y - ((hub_height/D) + 0.5)));

% Save fits
gaussian_centers = nan(1, size(U,2));
gaussian_widths = nan(1, size(U,2));

% Fit a gaussian profile to each vertical slice
clc;
for s = 1:size(U, 2)

    % Progress bar
    progressbarText(s / size(U, 2))

    % Crop data
    masked_u = U(top_index:bottom_index, s);

    % Compute velocity deficit
    deficit = 1 - (masked_u / u_inf);

    try
        opts = optimoptions('lsqcurvefit', ...
        'FunctionTolerance', 1e-10, ...
        'MaxIterations', 1E9, ...
        'Display', 'off');
        beta = lsqcurvefit(gaussEqn, [0.82, 0.8, 0.5], Y(top_index:bottom_index,1), deficit, [], [], opts);
        gaussian_centers(s) = beta(2);
        gaussian_widths(s) = beta(3);

    catch
        % If fitting fails, leave as NaN
        % fprintf('Failure!\n')
    end
end


figure('color', 'white')
hold on
contourf(X, Y, U / u_inf, 100, 'linestyle', 'none')
plot(X(1,:), max_wave / D, 'color', 'red', 'linewidth', 2)
plot(X(1,:), gaussian_centers, 'color', 'green', 'linewidth', 2)
hold off
axis equal
xlim([0, 5])
C = colorbar();
C.Label.String = '$u / u_{\infty}$';
C.Label.Interpreter = 'latex';
C.Label.FontSize = 20;
clim([0.2, 0.7])

yline(hub_height / D)
yline(hub_height / D + 1/2, 'linestyle', '--')
yline(hub_height / D - 1/2, 'linestyle', '--')
title(sprintf('Phase %1.0f', phase), 'interpreter', 'none')
% title(sprintf('%s: Phase %1.0f', wave_type, phase), 'interpreter', 'none')

xlabel('$x / D$', 'interpreter', 'latex', 'FontSize', 16)
ylabel('$y / D$', 'interpreter', 'latex', 'FontSize', 16)










