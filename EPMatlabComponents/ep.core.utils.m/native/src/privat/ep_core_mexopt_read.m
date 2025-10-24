function [casResult] = ep_core_mexopt_read(stMex, sOption, sDelimiter)
% Extracts information from the batch file describing the mex interface 'mexopt.bat'. 
% The currenty active mex compiler is used for the evaluation. 
%
% Example:
% Assume the following entry in the mexopt.bat: 'COMPFLAGS=/c /GR /W3 /EHs /D_CRT_SECURE_NO_DEPRECATE'
%
% The call ep_core_mexopt_read('COMPFLAGS', '/') results in 
% casResult = {'c' 'GR' 'W3' 'EHs' 'D_CRT_SECURE_NO_DEPRECATE'}
%
% function [casResult] = ep_core_mexopt_read(sOption, sDelimiter)
%
%   INPUT
%   - stMex                 The Mex compiler configurations. 
%   - sOption     (String)  The Mex option to be evaluated.
%   - sDelimiter  (String)  If the delimiter is not null, the evaluated string will be split by the specified delimiter.
%                           Otherwise, the evaluated option is not split.
%
%   OUTPUT
%   - casResult   (cell array) The result of the evaluated batch file option.
%
% $$$COPYRIGHT$$$-2014

% Read mexopt file
if (ep_core_version_compare('ML8.3') == -1)
    sMexOptsFile = fullfile(prefdir(), 'mexopts.bat');
    if ~exist(sMexOptsFile, 'file')
        return;
    end
    sSetEnv = fileread(sMexOptsFile);
else
    sSetEnv = stMex.Details.SetEnv;
end
 
% Create eval bat
sTmpDir = EPEnvironment.getTempDirectory;
oOnCleanupRemoveTmp = onCleanup(@() EPEnvironment.deleteDirectory(sTmpDir));
if isunix
    sEvalBat = fullfile(sTmpDir, 'eval_temp.sh');
    fid = fopen(sEvalBat, 'a');
    i_append_string(fid, '%s', ['MATLAB=', matlabroot]);
    system(strjoin({'chmod +x', sEvalBat}));
else
    sEvalBat = fullfile(sTmpDir, 'eval_temp.bat');
    fid = fopen(sEvalBat, 'a');
    i_append_string(fid, '%s', ['set MATLAB=', matlabroot]);
end
i_append_string(fid, '%s', sSetEnv);
sMyOption = ['MY_', sOption];
if isunix
    i_append_string(fid, 'echo %s%s', sMyOption, ['$', sOption]);
else 
    i_append_string(fid, 'echo %s%s', sMyOption, ['%', sOption, '%']);
end
fclose(fid);

% Evaluate bat file
casResult = i_eval_bat(sEvalBat, sMyOption, sDelimiter);
end

%%
%***********************************************************************************************************************
% Appends a String to a file.
%
%   PARAMETER(S)    DESCRIPTION
%   - fid           (File ID)   The file identifier
%   - sPattern      (String)    Pattern to be added
%   - varargin      (String)    Additional information for the pattern
%
%   OUTPUT
%   -
%***********************************************************************************************************************
function i_append_string(fid, sPattern, varargin)
if (fid > 0)
    fprintf(fid, sPattern, varargin{:});
    if isunix
        fprintf(fid, '\n');
    else
        fprintf(fid, '\n\r');
    end
end
end

%%
%***********************************************************************************************************************
% Evalutes the temp batch file and retrieves information.
%
%   PARAMETER(S)    DESCRIPTION
%   - sBatFile       (String)    Temp batch file which has to be evaluted
%   - sGetString     (String)    The String which has to be read.
%   - sDelimiter     (String)    Delimiter for the splitting. Null means no splitting.
%
%   OUTPUT
%   - casResult      (cell array) Result of the evalution
%***********************************************************************************************************************
function casResult = i_eval_bat(sBatFile, sGetString, sDelimiter)
casResult = {};
[nStatus, sMsg] = system(sBatFile); %#ok<ASGLU>
if nStatus == 0
    % remove everything _including_ the delimiter
    sEscapedGetString = regexptranslate('escape', sGetString);
    sIncludes = regexprep(sMsg, ['^.*', sEscapedGetString], '');
    sIncludes = strtrim(sIncludes);
    
    if ~isempty(sIncludes) && ~isempty(sDelimiter)
        % Delimiter shall be ignored if surrounded by quotes (unless the
        % delimiter itself is (or contains) a quote)
        if isempty(strfind(sDelimiter, '"'))
            canIgnore = regexp(sIncludes, '("[^"]+")', 'tokenExtents');
        else
            canIgnore = [];
        end
        
        % Escape the delimiter, so it can be used as regular expression
        sDelimiter = regexptranslate('escape', sDelimiter);
        
        % Get all delimiter occurances
        anDelimiterIndex = regexp(sIncludes, sDelimiter);
        
        % Filter the delimiter occurances that are found in ranges that
        % should be ignored
        abKeep = true(1, length(anDelimiterIndex));
        for i = 1:length(canIgnore)
            abKeep = abKeep & (anDelimiterIndex < canIgnore{i}(1) |  anDelimiterIndex > canIgnore{i}(2));
        end
        anResultIndex = [0, anDelimiterIndex(abKeep)];
        
        % Fill the result vector
        nResults = sum(abKeep) + 1;
        casResult = cell(1, nResults);
        for i = 1:nResults-1
            casResult{i} = strtrim(sIncludes(anResultIndex(i)+1:anResultIndex(i+1)-1));
        end
        casResult{end} = strtrim(sIncludes(anResultIndex(end)+1:end));
    else
        casResult = {sIncludes};
    end
    % Clear empty results
    casResult(cellfun('isempty', casResult)) = [];
end
end