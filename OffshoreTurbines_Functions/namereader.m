% Reads input input filename and extracts expeiment info

function output = namereader(filename)
    
    %%% Floating or Fixed, Farm or Single
    arrangement = filename(1:3);
    if strcmp(arrangement, 'FWF') == 1
        output.arrangement = 'Floating Farm';

        % Inline or Staggered
        alignment = filename(5);
        if strcmp(alignment, 'I')
            output.alignment = 'Inline';
        end
        if strcmp(alignment, 'S')
            output.alignment = 'Staggered';
        end

    end

    if strcmp(arrangement, 'FBF') == 1
        output.arrangement = 'Fixed Farm';

        % Inline or Staggered
        alignment = filename(5);
        if strcmp(alignment, 'I')
            output.alignment = 'Inline';
        end
        if strcmp(alignment, 'S')
            output.alignment = 'Staggered';
        end
    end

    if strcmp(arrangement, 'FWT') == 1
        output.arrangement = 'Floating Turbine';
    end

    if strcmp(arrangement, 'FBT') == 1
        output.arrangement = 'Fixed Turbine';
    end

    %%% PIV Plane
    plane_keyword = 'PL';
    plane_idx     = strfind(filename, plane_keyword) + length(plane_keyword);
    output.plane  = str2double(filename(plane_idx));

    %%% Wave Steepness
    steepness_keyword = 'AK';
    steepness_idx     = strfind(filename, steepness_keyword) + length(steepness_keyword);
    output.steepness  = str2double(filename(steepness_idx:steepness_idx + 1)) * 1E-2;

    %%% Wavelength
    wavelength_keyword = 'LM';
    wavelength_idx     = strfind(filename, wavelength_keyword) + length(wavelength_keyword);
    output.wavelength  = str2double(filename(wavelength_idx:wavelength_idx + 1)) * 1E-1;

    %%% Batch
    batch = filename(end);
    if strcmp(batch, 'A')
        output.batch = 'A';
    end
    if strcmp(batch, 'B')
        output.batch = 'B';
    end

end