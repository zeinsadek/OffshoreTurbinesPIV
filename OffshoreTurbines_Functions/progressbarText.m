function [varargout] = progressbarText(percentageCompleted, varargin)
% progressbarText	Generates a textual bar which visualizes the progress of a task.
%   Consecutive progressbars overwrite the previous instance instead of outputting on a new line.
%   Works for both GUI and CLI instances of MATLAB
%
%   progressbarText(percentageCompleted) prints the progressbar to standard output.
%       A new progressbar always needs to be initialized by calling the function 
%       with percentageCompleted equal to zero 0.
%   progressbarText(percentageCompleted, nSegments) splits the progressbar into n segments. Default value: 10.
%       This only has an effect when percentageCompleted equals 0.
%   progressbarText(___, symbolName, symbolValue) sets the symbols used to generate the progressbar.
%       This only has an effect when percentageCompleted equals 0.
%       Symbol name             Symbol type                     Default value
%       -----------             ------------                    -------------
%       "CompletedSymbol"       printable character             "—"
%       "TodoSymbol"            printable character             "·"
%       "DelimiterSymbols"      cell array of two               ("[", "]")
%                               printable characters
%       "ProgressSymbols"       cell array of one or more       ("—", "\\", "|", "/")
%                               printable characters
%   [progressbarString, clearString] = progressbarText(___) returns the progressbar as variables 
%       instead of printing it. progressbarString contains the actual progressbar, 
%       clearString contains the character sequence to clear the previous one.
%
%
%   Example 1: Basic usage
%       nLoops = 100;
%       progressbarText(0);
%       for loopCnt = 1:nLoops
%           progressbarText(loopCnt/nLoops);
%           pause(0.2);
%       end
%
%   Example 2: Print other text while keeping the progressbar at the bottom
%       nLoops = 200;
%       progressbarText(0, 20);
%       for loopCnt = 1:nLoops
%           [progressbarString, resetString] = progressbarText(loopCnt/nLoops);
%           printString = strjoin([resetString, "%03d\n", progressbarString], "");
%           fprintf(printString, loopCnt);
%           pause(0.1);
%       end
%
%   Example 3: Use custom symbols
%       nLoops = 200;
%       progressbarText(0, 20, "DelimiterSymbols", ["(", ")"], "ProgressSymbols", ["o", "0", "O", "0"], ...
%           "CompletedSymbol", ">", "TodoSymbol", "<");
%       for loopCnt = 1:nLoops
%           progressbarText(loopCnt/nLoops);
%           pause(0.1);
%       end
%
%
% Author: Girmi Schouten (girmi.schouten@uantwerpen.be), 2019. 
% Written in MATLAB 2019b, tested on Ubuntu 16.04 & Windows 10.


    %% Define persistent variables
    
    persistent nSegments;
    persistent progressSymbols;
    persistent completedSymbol;
    persistent todoSymbol;
    persistent delimiterSymbols;
    
    persistent triggerCnt;
    
    
    %% Parse input
    
    progressbarInit = (isempty(triggerCnt) && ~(percentageCompleted > 1));
    
    if progressbarInit
        if isunix()
            DEFAULT_PROGRESS_SYMBOLS = ["—", "\\", "|", "/"];
            DEFAULT_COMPLETED_SYMBOL = "—";
            DEFAULT_TODO_SYMBOL = "·";
        else
            DEFAULT_PROGRESS_SYMBOLS = ["-", "\\", "|", "/"];
            DEFAULT_COMPLETED_SYMBOL = "~";
            DEFAULT_TODO_SYMBOL = "-";
        end
        DEFAULT_DELIMITER_SYMBOLS = ["[", "]"];
        
        argParser = inputParser();

        addRequired(argParser, "percentageCompleted", @isreal);
        addOptional(argParser, "nSegments", 10, ...
            @(nSegments) nSegments > 0 && rem(nSegments, 1) == 0);
        addParameter(argParser, "ProgressSymbols", DEFAULT_PROGRESS_SYMBOLS, ...
            @(symbols) isstring(symbols) && numel(symbols) >= 1);
        addParameter(argParser, "CompletedSymbol", DEFAULT_COMPLETED_SYMBOL, ...
            @(symbol) isstring(symbol) && numel(sprintf(symbol)) == 1);
        addParameter(argParser, "TodoSymbol", DEFAULT_TODO_SYMBOL, ...
            @(symbol) isstring(symbol) && numel(sprintf(symbol)) == 1);
        addParameter(argParser, "DelimiterSymbols", DEFAULT_DELIMITER_SYMBOLS, ...
            @(symbols) isstring(symbols) && numel(symbols) == 2);

        parse(argParser, percentageCompleted, varargin{:});
        percentageCompleted = argParser.Results.percentageCompleted;
        nSegments = argParser.Results.nSegments;
        progressSymbols = argParser.Results.ProgressSymbols;
        completedSymbol = argParser.Results.CompletedSymbol;
        todoSymbol = argParser.Results.TodoSymbol;
        delimiterSymbols = argParser.Results.DelimiterSymbols;
        
        triggerCnt = 1;
    else
        triggerCnt = triggerCnt+1;
    end
    
    if percentageCompleted == 1
       triggerCnt = [];
    end
    
    percentageCompleted = max(min(percentageCompleted, 1), 0);
    
    %% Generate progressbar string
    
    progressCnt = floor(percentageCompleted*nSegments);
    
    completedString = strjoin(repelem(completedSymbol, progressCnt), "");
    todoCnt = max(nSegments-progressCnt-1, 0);
    todoString = strjoin(repelem(todoSymbol, todoCnt), "");
    progressSymbol = progressSymbols(mod(triggerCnt, length(progressSymbols))+1);
    
    progressbarString = strjoin([delimiterSymbols(1), completedString, progressSymbol, todoString, delimiterSymbols(2), "\n"], "");
    
    if progressbarInit
        clearString = "";
    else
        if usejava('desktop')  % Check if GUI or CLI
            clearString = strjoin(repelem("\b", strlength(sprintf(progressbarString))), "");
        else
            clearString = "\033[1F\033[2K\r";
        end
    end
    
    fullString = strjoin([clearString, progressbarString], "");
    if nargout < 1
        fprintf(fullString);
    else
        varargout{1} = progressbarString;
        varargout{2} = clearString;
    end
end