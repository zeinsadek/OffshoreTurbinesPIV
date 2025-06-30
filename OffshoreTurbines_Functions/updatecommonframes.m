function output = updatecommonframes(frames, miss, outpath, images)
    
    PIV_frames     = frames.PIV;
    RAW_frames     = frames.RAW;
    common_frames  = frames.common;
    skipped_frame_numbers = miss.skip;
    
    if images == 'RAW'
      if ~isnan(skipped_frame_numbers)
          skipped_frames = string(strcat(common_frames(skipped_frame_numbers), '.im7'));
          % Remove skipped frames from wave detection
          RAW_frames = RAW_frames(~ismember(RAW_frames, skipped_frames));
          output.RAW_skip = skipped_frames;
      else
          fprintf('\n<updatecommonframes> Did not skip any RAW files!\n')
      end
    end
    
    
    if images == 'PIV'
      if ~isnan(skipped_frame_numbers)
          skipped_frames = string(strcat(common_frames(skipped_frame_numbers), '.vc7'));
          % Remove skipped frames from wave detection
        PIV_frames = PIV_frames(~ismember(PIV_frames, skipped_frames));
        output.PIV_skip = skipped_frames;
      else
          fprintf('\n<updatecommonframes> Did not skip any PIV files!\n')
      end
    end

    % Get Frame Names
    PIV_frames = char(PIV_frames);
    RAW_frames = char(RAW_frames);
    
    % Remove file extensions and BXXX
    PIV_frames = PIV_frames(:,2:end-4);
    RAW_frames = RAW_frames(:,2:end-4);
    
    % Turn into numbers
    PIV_frames = str2double(string(PIV_frames));
    RAW_frames = str2double(string(RAW_frames));
    
    % Get common frames
    common = intersect(PIV_frames, RAW_frames);
    
     % Display Information
     if ~isnan(skipped_frame_numbers)
        fprintf('\n<updatecommonframes> Skipped %s frames: \n\n', images)
        disp(skipped_frames)
        fprintf('\n')
     end 
     fprintf('<updatecommonframes> PIV Frames: %3.0f\n', length(PIV_frames));
     fprintf('<updatecommonframes> RAW Frames: %3.0f\n', length(RAW_frames));
     fprintf('<updatecommonframes> Common Frames: %3.0f\n', length(common));
    
     % Save Output
     output.PIV  = string(strcat('B', num2str(PIV_frames,'%05.f'), '.vc7'));
     output.RAW  = string(strcat('B', num2str(RAW_frames,'%05.f'), '.im7'));
    output.common = string(strcat('B', num2str(common,'%05.f')));
    
    % Save Matlab File.
    save(outpath, 'output');
    fprintf('<updatecommonframes> Data Save Complete \n')
end
