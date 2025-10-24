function [sCompiler, sVs] = atgcv_host_compiler_get(sFile)
% Return the Compiler currently used for mex.
%
% SYNTAX [sCompiler, sVs] = atgcv_host_compiler_get()
%
%   INPUT
%   -/-
%
%   OUTPUT
%       sCompiler      short identifier of compiler
%                       'MSVC' ... Microsoft Visual C/C++ compiler
%                       'LCC'  ... LCC compiler
%                       'WCC'  ... Watcom
%       sVs            compiler version
%
% REMARKS
%   The compiler type is retrieved from the mexopts.bat file.
%   Function returns the same values as TL's get_host_compiler().

%%
if (nargin < 1)
    sCompilerId = i_getCompilerId();
else
    sCompilerId = i_getFromFileCompilerId(sFile);
end
[sCompiler, sVs] = i_translateId(sCompilerId);
end


%%
function [sCompiler, sVs] = i_translateId(sCompilerId)
sCompiler = 'unknown';
sVs       = 'unknown';
if isempty(sCompilerId)
    return;
end
% expect something like: MSVC80FREE, LCC, MSSDK71, ...
casMatch = regexp(sCompilerId, '^([a-zA-Z]+)([\d]+.*)?', 'once', 'tokens');
if ~isempty(casMatch)
    if ~isempty(casMatch{1})
        sCompiler = casMatch{1};
        if strcmpi(sCompiler, 'WAT')
            sCompiler = 'WCC';
        end
        if ~isempty(casMatch{2})
            sVs = lower(casMatch{2});
            
            % remove the last zero and transform '71' to '7.1'
            sVs = regexprep(sVs, '0$', '', 'once');
            if strcmp(sVs, '71')
                sVs = '7.1';
            end
        end
    end
end
end



%%
function sCompilerId = i_getFromFileCompilerId(sFile)
if ~exist(sFile, 'file')
    error('ATGCV:STD:MEXOPTS_MISSING', ...
        'Could not find MEXOPTS file: %s.', sFile);
end
[p, f, sExt] = fileparts(sFile); %#ok
if strcmpi(sExt, '.xml')
    sCompilerId = i_readFromXmlCompilerId(sFile);
else
    % assume that file is a Batch script "mexopts.bat"
    sCompilerId = i_readFromBatCompilerId(sFile);
end
sCompilerId = upper(sCompilerId);
end


%%
function sCompilerId = i_getCompilerId()
if verLessThan('MATLAB', '8.3')
    sMexOptsFile = i_getCurrentMexOptsFile();
    if isempty(sMexOptsFile)
        error('ATGCV:STD:MEXOPTS_MISSING', ...
            'Could not find MEXOPTS file.');
    end
    sCompilerId = i_readFromBatCompilerId(sMexOptsFile);
else
    stMex = mex.getCompilerConfigurations('C', 'Selected');
    sCompilerId = i_getCompilerIdFromStruct(stMex);
end
sCompilerId = upper(sCompilerId);
end


%%
function sCompilerId = i_getCompilerIdFromStruct(stMex)
sCompilerId = stMex.ShortName;

% special treatment for mingw64 --> gcc4.x
if strncmpi(sCompilerId, 'mingw', 5)
    sCompilerId = ['gcc', stMex.Version];
end
end


%%
function sMexOptsFile = i_getCurrentMexOptsFile()
sMexOptsFile = fullfile(prefdir(), 'mexopts.bat');
if ~exist(sMexOptsFile, 'file')
    sMexOptsFile = '';
end
end

%%
function sCompilerId = i_readFromBatCompilerId(sMexOptsFile)
hFid = fopen(sMexOptsFile, 'r');
if (hFid < 0)
    error('ATGCV:STD:MEXOPTS_READ_FAILED', ...
        'Opening MEXOPTS file "%s" failed.', sMexOptsFile);
end
try
    sCompilerId = '';
    
    sLine = fgetl(hFid);
    while (isempty(sCompilerId) && ischar(sLine))
        sCompilerId = i_identifyCompiler(sLine);
        sLine = fgetl(hFid);
    end
    fclose(hFid);
catch oEx
    fclose(hFid);
    rethrow(oEx);
end
end


%%
function sCompilerId = i_readFromXmlCompilerId(sMexOptsFile)
try
    stRes = mxx_xmltool(sMexOptsFile, '/config', 'ShortName');
    if ~isempty(stRes)
        sCompilerId = stRes(1).ShortName;
    else
        sCompilerId = '';
    end
catch oEx
    error('ATGCV:STD:MEXOPTS_READ_FAILED', ...
        'Reading MEXOPTS file "%s" failed.\n%s', sMexOptsFile, oEx.message);
end
end


%%
function sCompilerId = i_identifyCompiler(sText)
casCompilerId = regexp(sText, 'rem [\w\d]*OPTS\.BAT', 'match');

if ~isempty(casCompilerId)
    sCompilerId = casCompilerId{1};
    sCompilerId = strrep(sCompilerId, 'rem ', '');
    sCompilerId = strrep(sCompilerId, 'OPTS.BAT', '');
else
    sCompilerId = '';
end
end


