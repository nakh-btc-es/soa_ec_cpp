function sVersion = atgcv_version_get(varargin)
% Returns the version string of the EP Project.
%
% function version = atgcv_version_get
%
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%     version              (string)   version of installed EP
%


%%
% just ask once and cache the result
persistent p_sVersion; 

if isempty(p_sVersion)
    p_sVersion = i_getVersion('ep');
end
if isempty(p_sVersion)
    p_sVersion = '<unknown>';
end

if ((nargin > 0) && strcmp(varargin{1}, 'only_number'))
    % Only use Major and first Minor number
    sVersion = char(regexp(p_sVersion, '^\d\.\d', 'match'));
    
elseif ((nargin) > 0 && strcmp(varargin{1}, 'all_numbers'))
    sVersion = p_sVersion;
    
else
    sVersion = sprintf('EmbeddedPlatform Version %s', p_sVersion);
end
end


%%
function sVersion = i_getVersion(sPath)
astVers = ver(sPath);
sVersion = '';
for i = 1:length(astVers)
    if strcmp(astVers(i).Name, 'BTC EmbeddedPlatform')
        sVersion = astVers(i).Version;
        break;
    end
end
end


