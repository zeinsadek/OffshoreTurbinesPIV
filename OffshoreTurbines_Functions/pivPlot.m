% This function converts DaVis vector data (.vc7) files into a Matlab
% Struct file for easy manipulation in Matlab.
% Ondrej Fercak, Zein Sadek, 3/21/2022

% file_path:    Folder where DaVis (.vc7) files are stored.
% out_path:     Folder where new struct file will be saved.
% out_name:     Name of new struct file.

function t = pivPlot(dat, exp_name, varargin)

   % Cropping
%    x_min = -100;
%    x_max = 100;
%    
%    y_min = -98;
%    y_max = 110;
    
   % Set Default Number of Contours [If no Input].
   defaultContours  = 1000;

   % Parse Input Arguments.
   p = inputParser;
   validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
   
   addRequired(p,'data');
   addRequired(p,'name');
   addOptional(p,'contours', defaultContours, validScalarPosNum);
   
   addParameter(p,'U', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'V', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'W', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   
   addParameter(p,'uu', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'vv', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'ww', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   
   addParameter(p,'uv', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'vu', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'uw', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   
   addParameter(p,'wu', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'vw', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   addParameter(p,'wv', @(x)validateattributes(x,{'char'}, {'nonempty'}))
   
   parse(p,dat, exp_name, varargin{:});
   
   % Assign Variable Values.
   dat      = p.Results.data;
   exp_name = p.Results.name;
   contours = p.Results.contours;
   U        = p.Results.U;
   V        = p.Results.V;
   W        = p.Results.W;
   uu       = p.Results.uu;
   vv       = p.Results.vv;
   ww       = p.Results.ww;
   uv       = p.Results.uv;
   vu       = p.Results.vu;
   uw       = p.Results.uw;
   wu       = p.Results.wu;
   vw       = p.Results.vw;
   wv       = p.Results.wv;
   
   % Extract Image Dimensions.
   x = dat.X;
   y = dat.Y;
   
   % Create Plot Logic from Existing Inputs.
   if ischar(U) == 1
       tile_U = 1;
   else
       tile_U = 0;
   end
   
   if ischar(V) == 1
       tile_V = 1;
   else
       tile_V = 0;
   end
   
   if ischar(W) == 1
       tile_W = 1;
   else
       tile_W = 0;
   end

   if ischar(uu) == 1
       tile_uu = 1;
   else
       tile_uu = 0;
   end
   
   if ischar(vv) == 1
       tile_vv = 1;
   else
       tile_vv = 0;
   end
   
   if ischar(ww) == 1
       tile_ww = 1;
   else
       tile_ww = 0;
   end
   
   if ischar(uv) == 1 || ischar(vu) == 1
       tile_uv = 1;
   else
       tile_uv = 0;
   end
   
   if ischar(vw) == 1 || ischar(wv) == 1
       tile_vw = 1;
   else
       tile_vw = 0;
   end
   
   if ischar(uw) == 1 || ischar(wu) == 1
       tile_uw = 1;
   else
       tile_uw = 0;
   end         
            
   % Calculate Total Number of Tiles Needed. [Out of Nine Total]
   tiles = sum([tile_U, tile_V, tile_W, tile_uu, tile_vv, tile_ww, tile_uv, tile_uw, tile_vw]);
   
   if tiles <= 3
    rows = 1;
    cols = tiles;
    
   elseif tiles > 3 && tiles <= 6
    rows = 2;
    cols = 3;
    
   else
    rows = 3;
    cols = 3;
    
   end

   t = tiledlayout(rows, cols, 'TileSpacing','Compact');
   
   if  tile_U == 1      
   nexttile
        hold on
        contourf(x, y, dat.u, contours,'LineStyle','none');
        title(strcat("U"))
        xlabel('y [mm]')
        ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal    
%         xlim([x_min, x_max])
%         ylim([y_min, y_max])
   end
   
   if  tile_V == 1      
   nexttile
        contourf(x, y, dat.v, contours,'LineStyle','none');
        title(strcat("V"))
        xlabel('y [mm]')
        ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal    
%         xlim([x_min, x_max])
%         ylim([y_min, y_max])

   end
   
   if  tile_W == 1      
   nexttile
        contourf(x, y, dat.w, contours,'LineStyle','none');
        title(strcat("W"))
        xlabel('y [mm]')
        ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal
%         xlim([x_min, x_max])
%         ylim([y_min, y_max])
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
  
   if  tile_uu == 1      
   nexttile
        contourf(x, y, dat.uu, contours,'LineStyle','none');
        title(strcat("uu"))
        xlabel('y [mm]')
        ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal 
%         xlim([x_min, x_max])
%         ylim([y_min, y_max])
        
   end
   
   if  tile_vv == 1      
   nexttile
        contourf(x, y, dat.vv, contours,'LineStyle','none');
        title(strcat("vv"))
        xlabel('y [mm]')
        %ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal
%         xlim([x_min, x_max])
%         ylim([y_min, y_max])
   end
   
   if  tile_ww == 1      
   nexttile
        contourf(x, y, dat.ww, contours,'LineStyle','none');
        title(strcat("ww"))
        xlabel('y [mm]')
        %ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal
        xlim([x_min, x_max])
        ylim([y_min, y_max])
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
   if  tile_uv == 1      
   nexttile
        contourf(x, y, dat.uv, contours,'LineStyle','none');
        title(strcat("uv"))
        xlabel('y [mm]')
        ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal
%         xlim([x_min, x_max])
%         ylim([y_min, y_max])
   end
   
   if  tile_uw == 1      
   nexttile
        contourf(x, y, dat.uw, contours,'LineStyle','none');
        title(strcat("uw"))
        xlabel('y [mm]')
        %ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal
        xlim([x_min, x_max])
        ylim([y_min, y_max])
   end
   
   if  tile_vw == 1      
   nexttile
        contourf(x, y, dat.vw, contours,'LineStyle','none');
        title(strcat("vw"))
        xlabel('y [mm]')
        %ylabel('z [mm]')
        colorbar;
        colormap parula
        axis equal
        xlim([x_min, x_max])
        ylim([y_min, y_max])
   end

%    t.Title.String = strcat(exp_name, '_Summary');
   t.Title.Interpreter = 'None';
   t.TileSpacing = 'compact';
   t.Padding = 'compact';

   % Save Matlab File.
  fprintf('\n Plotting <pivPlot> Data to Figure...\n');
  clc; fprintf('<pivPlot> Calculations Complete: Figure Will Show Shortly... \n')
    
end

