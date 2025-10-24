function [nComp, bTrailEqual] = sltu_version_compare(varargin)
% Compare current Matlab/TargetLink version (including p-Postfix for patches) to reference version. 
%
% function [nComp, bTrailEqual] = sltu_version_compare(sRefVersion)
%
%   INPUT                   DESCRIPTION
%
%   sRefVersion            (string)  either MLxxx.xxx.xxx for Matlab 
%                                    or     TLxxx.xxx.xxx for TargetLink
%
%   OUTPUT                  DESCRIPTION
%   nComp                  (integer) ( -1 | 0 | 1 )
%                               1: current version is greater than sRefVersion
%                               0: current version is equal to sRefVersion 
%                              -1: current version is smaller than sRefVersion
%                         <empty>: no valid current version found; tool is not installed
%                           
%   bTrailEqual             (bool) optional output parameter; if asked for, the trailer after the version
%                                  number is also compared to the one of the current version
%                                  (e.g. TL2.2.1alpha3 --> "alpha3")
%                            TRUE: trailers are equal
%                           FALSE: trailers differ
%                         <empty>: no valid current version found; tool is not installed
%
%                                  NOTE: "p%d" is _not_ interpreted as trailer but as "micro"-number: TL3.0.1p1 is
%                                  equivalent to TL3.0.1.1
%                               

%% check inputs
if (nargin < 2)
    [sRefVersion, sVersion] = i_getCurrentVersion(varargin{1});
    if isempty(sVersion)
        % Tool is not installed, so we have no valid version number
        nComp       = [];
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

[sRefVersion, sRefTrailer] = i_separateVersionNumberTrailer(sRefVersion);
[sVersion,    sVerTrailer] = i_separateVersionNumberTrailer(sVersion);
bTrailEqual = strcmp(sRefTrailer, sVerTrailer);

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
        sVer = atgcv_current_version_get('ml');
    case 'tl'
        sVer = atgcv_current_version_get('tl');
    otherwise
        error('ATGCV:MXX:WRONG_USAGE', 'Unknown mode %s.', sMode);
end
end


%% i_separateVersionNumberTrailer
function [sVersionNumber, sTrailer] = i_separateVersionNumberTrailer(sVersion)
sVersionNumber = '0';
sTrailer       = '';

casParts = regexp(sVersion, '^([\.\d]*)?(.*)$', 'tokens', 'once');
if (length(casParts) == 2)
    if ~isempty(casParts{1})
        sVersionNumber = casParts{1};
    end
    if ~isempty(casParts{2})
        sTrailer = casParts{2};
        
        % try to detect the "p%d" special case for trailers
        sPatchNumber = i_detectPatchTrailer(sTrailer);
        if ~isempty(sPatchNumber)
            sVersionNumber = [sVersionNumber, '.', sPatchNumber];
            sTrailer = '';
        end
    end
end
end


%% i_detectPatchTrailer
function sPatchNumber = i_detectPatchTrailer(sTrailer)
sPatchNumber = '';

% try to detect the "p%d" special case for trailers
casPatch = regexp(sTrailer, '^p([\.\d]+)$', 'tokens', 'once');
if (~isempty(casPatch) && ~isempty(casPatch{1}))
    sPatchNumber = casPatch{1};
end
end

