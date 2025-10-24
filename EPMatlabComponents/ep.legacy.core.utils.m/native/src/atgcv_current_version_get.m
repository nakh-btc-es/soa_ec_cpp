function [sVersion, sPatchTrailer] = atgcv_current_version_get(sToolKey)
% Return currently used version of specified tool. 
%
% function [sVersion, sPatchTrailer] = atgcv_current_version_get(sToolKey)
%
%   INPUT                   DESCRIPTION
%
%   sToolKey              (string)   'ML' -- Matlab
%                                    'SL' -- Simulink
%                                    'TL' -- TargetLink
%
%
%                                        
%   OUTPUT                  DESCRIPTION
%
%   sVersion              (string)   curently used version as string
%                                    "<major>.<minor>.<patch><patch_trailer>"
%                                    note: might be empty '' if not found
%
%   sPatchTrailer         (string)   optional output: if requested, the 
%                                    version string is separted into 
%                                    <patch-main-number> and <patch-trailer> 
%                                    example: '3.3p6' --> '3.3' and 'p6'
%                               

%% internal
%                           
%   AUTHOR(S):
%       Alexander.Hornstein@osc-es.de
% $$$COPYRIGHT$$$
%
% $Revision: 76739 $ 
% Last modified: $Date: 2010-11-02 09:06:47 +0100 (Di, 02 Nov 2010) $ 
% $Author: ahornste $ 



%% input check
if ((nargin ~= 1) || ~ischar(sToolKey))
    error('ATGCV:MXX:WRONG_USAGE', 'One char argument expected.');
end

switch lower(sToolKey)
    case 'tl'
        sVersion = i_getTargetLinkCurrentVersion();
    case 'ml'
        sVersion = i_getMatlabCurrentVersion();
    case 'sl'
        sVersion = i_getSimulinkCurrentVersion();
        
    otherwise
        error('ATGCV:MXX:WRONG_USAGE', 'Unknown tool key %s.', sToolKey);
end
if (nargout > 1)
    [sVersion, sPatchTrailer] = i_separatePatchTrailer(sVersion);    
end
end





%% i_getMatlabCurrentVersion
function sCurrVer = i_getMatlabCurrentVersion()
persistent sVer;

if isempty(sVer)
    sVer = i_getCurrentVersion('matlab', '^MATLAB$');
end
sCurrVer = sVer;
end


%% i_getSimulinkCurrentVersion
function sCurrVer = i_getSimulinkCurrentVersion()
persistent sVer;

if isempty(sVer)
    sVer = i_getCurrentVersion('simulink', '^Simulink$');
end
sCurrVer = sVer;
end


%% i_getCurrentVersion
function sVer = i_getCurrentVersion(sToolName, sFallbackPattern)
% first try a shortcut via ToolName
stVersion = ver(sToolName);
if (length(stVersion) == 1)
    sVer = stVersion.Version;
else
    sVer = ''; % ensure that empty string is returned and not []
    
    sRegexp = sFallbackPattern;
    astVersions = ver();
    for i = 1:length(astVersions)
        sName = astVersions(i).Name;
        if ~isempty(regexpi(sName, sRegexp, 'once'))
            sVer = astVersions(i).Version;
            break;
        end
    end
end
end


%% i_getTargetLinkCurrentVersion
function sCurrVer = i_getTargetLinkCurrentVersion()
persistent sVer;

if isempty(sVer)
    % first try a shortcut
    stVersion = ver('tl');
    if (length(stVersion) == 1)
        sVer = stVersion.Version;
    else
        sVer = ''; % ensure that empty string is returned and not []
        
        % now look for first pattern
        sRegexp = '^dSPACE TargetLink';
        astVersions = ver();
        nFound = 0;
        for i = 1:length(astVersions)
            sName = astVersions(i).Name;
            if ~isempty(regexpi(sName, sRegexp, 'once'))
                sVer = astVersions(i).Version;
                nFound = nFound + 1;
            end
        end
        % we are finished if we have _exactly_ one hit
        if (nFound ~= 1)
            % now look for second pattern (more precise)
            sRegexp = '^dSPACE TargetLink Production Code Generator$';
            astVersions = ver();
            nFound = 0;
            for i = 1:length(astVersions)
                sName = astVersions(i).Name;
                if ~isempty(regexpi(sName, sRegexp, 'once'))
                    sVer = astVersions(i).Version;
                    nFound = nFound + 1;
                end
            end
        end
    end
end
sCurrVer = sVer;
end


%% i_separatePatchTrailer
function [sVersionNumber, sTrailer] = i_separatePatchTrailer(sVersion)
sVersionNumber = '';
sTrailer       = '';

casParts = regexp(sVersion, '([\.\d]+\d)(.*)$', 'tokens', 'once');
if (length(casParts) == 2)
    if ~isempty(casParts{1})
        sVersionNumber = casParts{1};
    end
    if ~isempty(casParts{2})
        sTrailer = casParts{2};        
    end
end
end

