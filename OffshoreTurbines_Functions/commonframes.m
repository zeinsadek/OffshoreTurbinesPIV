% Get Common Frames Betweeen PIV and Perspective-Corrected Images
% Safety net for misprocessed images

% Zein Sadek, APS 2024

function output = commonframes(PIV_path, RAW_path, out_path)

    % Get directories
    PIV_dir = dir([PIV_path, '/*.vc7']);
    RAW_dir = dir([RAW_path, '/*.im7']);
    
    % Get Frame Names
    PIV_frames = char({PIV_dir.name}.');
    RAW_frames = char({RAW_dir.name}.');
    
    % Remove file extensions and BXXX
    PIV_frames = PIV_frames(:,2:end-4);
    RAW_frames = RAW_frames(:,2:end-4);
    
    % Turn into numbers
    PIV_frames = str2double(string(PIV_frames));
    RAW_frames = str2double(string(RAW_frames));
    
    % Get common frames
    common = intersect(PIV_frames, RAW_frames);
    
    % Display Information
    fprintf('<commonframes> PIV Frames: %3.0f\n', length(PIV_frames));
    fprintf('<commonframes> RAW Frames: %3.0f\n', length(RAW_frames));
    fprintf('<commonframes> Common Frames: %3.0f\n', length(common));
    
    % Save Output
    output.PIV = string(strcat('B', num2str(PIV_frames,'%04.f'), '.vc7'));
    output.RAW = string(strcat('B', num2str(RAW_frames,'%04.f'), '.im7'));
    output.common = string(strcat('B', num2str(common,'%04.f')));

    % Save Matlab File.
    save(out_path, 'output');
    fprintf('\n<commonframes> Data Save Complete \n')
end


% Get common files between PIV images and Perspective corrected images
% (only doing this to salvage misprocessed cases, with missing files)
% (Can leave in the final code, should not make a difference for fully
% processed cases)


% clc; clear;
% % Get directories
% PIV_dir = dir('/Volumes/ZeinResults/PIV/FWF_I_PL1_AK12_LM50_A/*.vc7');
% RAW_dir = dir('/Volumes/ZeinResults/Perspective/FWF_I_PL1_AK12_LM50_A_Perspective/*.im7');
% 
% % Get Frame Names
% PIV_frames = char({PIV_dir.name}.');
% RAW_frames = char({RAW_dir.name}.');
% 
% % Remove file extensions and BXXX
% PIV_frames = PIV_frames(:,2:end-4);
% RAW_frames = RAW_frames(:,2:end-4);
% 
% % Turn into numbers
% PIV_frames = str2double(string(PIV_frames));
% RAW_frames = str2double(string(RAW_frames));
% 
% % Get common frames
% common = intersect(PIV_frames, RAW_frames);
% 
% % Display Information
% fprintf('PIV Frames: %3.0f\n', length(PIV_frames));
% fprintf('RAW Frames: %3.0f\n\n', length(RAW_frames));
% fprintf('Common Frames: %3.0f\n', length(common));
