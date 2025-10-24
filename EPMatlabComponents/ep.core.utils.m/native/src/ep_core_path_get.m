function sAbsoluteResourcePath = ep_core_path_get(sResourceKind)
% Get the absolute resource location for the specified resource kind.
%
% sAbsoluteResourcePath = ep_core_path_get(sResourceKind)
%
%   INPUT
%    - sResourceKind    (string)   'TL_HOOKS' --- additional hook functions for TL use cases
%                                  'EP_HOOKS' --- additional hook functions for EP use cases
%                                  'EC_CONFIGS' --- additional config functions for EC use cases
%
%   OUTPUT
%    - sAbsoluteResourcePath    (string)   absolute file path or [] if not found
%


%%
switch upper(sResourceKind)    
    case 'TL_HOOKS'
        sAbsoluteResourcePath = i_extendPath(i_getHookDirectory('scripts/m'), 'tl_hooks');
        
    case 'EP_HOOKS'
        sAbsoluteResourcePath = i_getHookDirectory('scripts/m');
        
    case 'EC_CONFIGS'
        sAbsoluteResourcePath =  i_getConfigsDirectoryEC();
        
    otherwise
        error('EP:CORE:USAGE_ERROR', 'Unknown resource kind "%s".', sResourceKind);
end
end


%%
function sAbsoluteConfigDirectory = i_getConfigsDirectoryEC()
sAbsoluteConfigDirectory = '';

sPrefConfigsDirectory = ep_core_get_pref_value('ARCHITECTURE_EC_DEFAULT_CONFIGURATION_FOLDER');
if (isempty(sPrefConfigsDirectory) || strcmp(sPrefConfigsDirectory, 'BTC Default Configuration'))
    return;
end
sAbsoluteConfigDirectory = ep_core_canonical_path(sPrefConfigsDirectory, i_getPrefFileDir());
end


%%
function sDir = i_getPrefFileDir()
sDir = fileparts(ep_core_get_preference_location_env());
end


%%
function sAbsoluteHookDirectory = i_getHookDirectory(sMatlabScriptPath)
sSpecificHooksDirectory = ep_core_get_pref_value('GENERAL_MATLAB_HOOKS_DIRECTORY');

if isempty(sSpecificHooksDirectory)
    sAbsoluteHookDirectory = i_extendPath(i_getCorePath(sMatlabScriptPath), 'hooks');
else
    sAbsoluteHookDirectory = ep_core_canonical_path(sSpecificHooksDirectory, i_getPrefFileDir());
end
end


%%
function sAbsoluteResourcePath = i_getCorePath(sRelativeResourcePath)
sAbsoluteResourcePath = [];
try
    sAbsoluteResourcePath = ep_core_internal_resource_get(sRelativeResourcePath);
catch oEx
    warning('EP:CORE:RESOURCE_NOT_FOUND', 'Resource with relative path "%s" was not found.\n%s', ...
        sRelativeResourcePath, oEx.message);
end
end


%%
function sExtendedPath = i_extendPath(sRootPath, varargin)
if isempty(sRootPath)
    sExtendedPath = sRootPath;
else
    sExtendedPath = fullfile(sRootPath, varargin{:});
end
end
