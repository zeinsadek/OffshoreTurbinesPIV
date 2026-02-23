%% Stitched Ensemble Average Plots for WESC conference


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
wave_types  = {'AK0', 'AK12_LM50', 'AK12_LM33'};

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for wave = 1:length(wave_types)
    % Load data
    wave_type = wave_types{wave};
    caze = strcat(arrangement, '_', wave_type, '_ENSEMBLE_STITCHED.mat');
    tmp = load(fullfile(matfile_path, 'stitched', 'ensemble', caze));
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

% Plot
clc; close all;
figure('color', 'white')
tiledlayout(3,1)

% Loop through cases
for wave = 1:length(wave_types)
    wave_type = wave_types{wave};

    % Load data
    X = data.(wave_type).X;
    Y = data.(wave_type).Y;
    u = double(data.(wave_type).uv / (u_inf^2));
    max_wave = data.(wave_type).max_wave;

    % Plot data
    h(wave) = nexttile;
    hold on

    % Plot u 
    contourf(X / D, Y / D, u, 50, 'linestyle', 'none')

    % Plot max wave profile
    plot(X(1,:) / D, max_wave / D, 'color', 'red', 'linewidth', 2)

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

    title(wave_type, 'interpreter', 'none')

    % X label
    if ismember(wave, 3)
        xlabel('$x / D$', 'interpreter', 'latex', 'FontSize', 14)
    end

    % Y label
    ylabel('$y / D$', 'interpreter', 'latex', 'fontsize', 14)

end

linkaxes(h, 'xy')
set(h, 'Colormap', coolwarm, 'CLim', [-10E-3, 5E-3])

clear wave X Y u max_wave h masked_u wake_center_indicies wave_type

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT PROFILES SIDE-BY-SIDE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Freestream
u_inf = 4.2;

% Turbine diameter
D = 150;

% Hub height in mm
hub_height = 117;

% Columns to skip
skip = 50;
colors = parula(size(data.AK0.u, 2));

% Plot
clc; close all;
figure('color', 'white')
tiledlayout(1,3)

% Loop through cases
for wave = 1:length(wave_types)
    wave_type = wave_types{wave};

    % Load data
    X = data.(wave_type).X;
    Y = data.(wave_type).Y;
    u = double(data.(wave_type).u / u_inf);

    % Plot data
    h(wave) = nexttile;
    hold on

    % Loop through profiles
    for i = 1:skip:size(u, 2)
        plot(u(:,i), Y(:,1) / D, 'color', colors(i,:))
    end

    % Plot hub and rotor tips
    yline(hub_height / D)
    yline(hub_height / D + 1/2, 'linestyle', '--')
    yline(hub_height / D - 1/2, 'linestyle', '--')

    % Plot settings
    hold off
    axis equal
    xlim([0, 1])
    ylim([0, 1.5])
    % clim([0,0.75])
    % colorbar()
    title(wave_type, 'interpreter', 'none')
end

linkaxes(h, 'xy')

clear wave X Y u max_wave h masked_u wake_center_indicies wave_type i colors skip


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT PROFILES TOGETHER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Freestream
u_inf = 4.2;

% Turbine diameter
D = 150;

% Hub height in mm
hub_height = 117;

% Columns to skip
start = 1;
step  = 0.5;
stop  = 4;

% Colors
colors.AK0 = 'black';
colors.AK12_LM50 = 'red';
colors.AK12_LM33 = 'blue';
fs =16;

% Counter for tiles
tile_counter = 1;
num_tiles = (stop - start + 1) / step;
clc; close all; figure('color', 'white')
tiledlayout(1, 7)

% Loop through x-locations
for location = start:step:stop

    h(tile_counter) = nexttile;
    hold on 
    % Loop through experiments
    for wave = 1:length(wave_types)

        % Select experiment
        wave_type = wave_types{wave};

        % Load data
        X = data.(wave_type).X;
        Y = data.(wave_type).Y;
        u = double(data.(wave_type).u / u_inf);

        % Select which column to plot
        [~, index] = min(abs((X(1,:) / D) - location));

        % Only make legend work for first plot
        if tile_counter == 1
            vis = 'on';
        else 
            vis = 'off';
        end

        % Plot data
        plot(u(:,index), Y(:,1) / D, 'color', colors.(wave_type), 'displayname', wave_type, 'linewidth', 2, 'HandleVisibility', vis)

        % Plot hub and rotor tips
        yline(hub_height / D, 'HandleVisibility', 'off')
        yline(hub_height / D + 1/2, 'linestyle', '--', 'HandleVisibility', 'off')
        yline(hub_height / D - 1/2, 'linestyle', '--', 'HandleVisibility', 'off')
    end
    hold off

    % Title which x-location each plot is taken at
    title(sprintf('$x / D = %1.1f$', location), 'interpreter', 'latex', 'FontSize', 12)
    
    % Make a legend for only the first plot
    if tile_counter == 1
        leg = legend('Orientation', 'Horizontal', 'Interpreter', 'none');
        leg.Layout.Tile = 'north';
        leg.Box = 'off';
        ylabel('$y / D$', 'Interpreter', 'latex', 'fontsize', fs)
    end

    % Add x-label for the middle plot
    if tile_counter == 4
        xlabel("$u / u_{\infty}$", 'Interpreter', 'latex', 'FontSize', fs)
    end

    % Hide y-axis for plots except the first one
    if tile_counter ~= 1
        h(tile_counter).YAxis.Visible = 'off';
    end
    
    % Increment tile counter
    tile_counter = tile_counter + 1;
end

linkaxes(h, 'xy')

clear colors fs h index leg location num_tiles start step stop tile_counter u vis wave wave_type X Y



