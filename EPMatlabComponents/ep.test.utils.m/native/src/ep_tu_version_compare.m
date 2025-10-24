function [nComp, bTrailEqual] = ep_tu_version_compare(varargin)
% Compare current Matlab/TargetLink version to reference version. 
%
% function [nComp, bTrailEqual] = atgcv_version_compare(sRefVersion)
%
%   INPUT                   DESCRIPTION
%
%   sRefVersion            (string)  either MLxxx.xxx.xxx for Matlab 
%                                    or     TLxxx.xxx.xxx for TargetLink
%
%
%                                        
%   OUTPUT                  DESCRIPTION
%   nComp                  (integer) ( -1 | 0 | 1 )
%                               1: current version is greater than sRefVersion
%                               0: current version is equal to sRefVersion 
%                              -1: current version is smaller than sRefVersion
%                         <empty>: no valid current version found; 
%                                  tool is not installed
%                           
%   bTrailEqual             (bool) optional output parameter
%                                  if asked for, the trailer after the version
%                                  number is also compared to the one of the
%                                  current version
%                                  (e.g. TL2.2.1patch3 --> "patch3")
%                            TRUE: trailers are equal
%                           FALSE: trailers differ
%                         <empty>: no valid current version found; 
%                                  tool is not installed
%                               

%% internal
%                           
%   AUTHOR(S):
%       Alexander.Hornstein@osc-es.de
% $$$COPYRIGHT$$$
%
% $Revision$ 
% Last modified: $Date$ 
% $Author$ 


%% check inputs

if (nargin < 2)
    [sRefVersion, sVersion] = i_getCurrentVersion(varargin{1});
    if isempty(sVersion)
        % Tool is not installed, so we have no valid version number
        nComp = [];
        bTrailEqual = [];
        return;
    end
else
    sRefVersion = varargin{1};
    sVersion    = varargin{2};
end

%% main compare
% separate version number from patch trailers, 
% e.g.,  2.2.1alpha3 ---> 2.2.1 + alpha3
casRefPure = regexp(sRefVersion, '([\.\d]+)', 'tokens', 'once');
casVerPure = regexp(sVersion, '([\.\d]+)', 'tokens', 'once');

if isempty(casRefPure)
    sRefCut = '0';
else
    sRefCut = casRefPure{1};
end
if isempty(casVerPure)
    sVerCut = '0';
else
    sVerCut = casVerPure{1};
end
if (nargout > 1)
    if (length(sRefCut) < length(sRefVersion))
        sRefTrailer = sRefVersion(length(sRefCut)+1:end);
    else
        sRefTrailer = '';
    end
    if (length(sVerCut) < length(sVersion))
        sVerTrailer = sVersion(length(sVerCut)+1:end);
    else
        sVerTrailer = '';
    end
    bTrailEqual = strcmp(sRefTrailer, sVerTrailer);
end

% remove the trailers
sRefVersion = sRefCut;
sVersion    = sVerCut;


% ! assumption: version string contains only digits and '.' as delimiters
casRefLevels = regexp(sRefVersion, '(\d+)', 'tokens');
casVerLevels = regexp(sVersion, '(\d+)', 'tokens');

nRefLevel = length(casRefLevels);
nVerLevel = length(casVerLevels);
nLevel    = max(nRefLevel, nVerLevel);    
nComp     = 0;
for i = 1:nLevel
    if (i > nRefLevel)
        dRefVal = 0;
    else
        dRefVal = sscanf(casRefLevels{i}{1}, '%i');
    end
    if (i > nVerLevel)
        dVerVal = 0;
    else
        dVerVal = sscanf(casVerLevels{i}{1}, '%i');
     end
    if (dVerVal > dRefVal)
        nComp = 1;
        break;
    elseif (dVerVal < dRefVal)
        nComp = -1;
        break;
    end
end
end



%% compare and use current version as reference version 
function [sRefVer, sVer] = i_getCurrentVersion(sRefVersion)
if (length(sRefVersion) < 2)
    error('ATGCV:MXX:WRONG_USAGE', 'Given reference version is not consistent.');
end
sMode = lower(sRefVersion(1:2));

if (length(sRefVersion) > 2)
    sRefVer = sRefVersion(3:end);
else
    sRefVer = '';
end
switch sMode
    case 'ml'
        sVer = i_getMatlabCurrentVersion();
    case 'tl'
        sVer = i_getTargetLinkCurrentVersion();
    otherwise
        error('ATGCV:MXX:WRONG_USAGE', 'Unknown mode %s.', sMode);
end
end


%% internal functions

%% i_getMatlabCurrentVersion
function sCurrVer = i_getMatlabCurrentVersion()
persistent sVer;

if isempty(sVer)
    % first try a shortcut
    stVersion = ver('matlab');
    if (length(stVersion) == 1)
        sVer = stVersion.Version;
    else
        sRegexp = '^MATLAB$';
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
sCurrVer = sVer;
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
