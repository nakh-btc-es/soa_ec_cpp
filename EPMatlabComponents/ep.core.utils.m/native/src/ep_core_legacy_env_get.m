function stEnvLegacy = ep_core_legacy_env_get(xEnv, bWithoutDirectories)
% Creates an environment for the legacy components.
%
%  function stEnvLegacy = ep_core_legacy_env_get(xEnv, bWithoutDirectories)
%
%  INPUT                        DESCRIPTION
%  - xEnv                           (struct)  EPEnvironment
%  - bWithoutDirectories            (boolean) If false, a temp directory and a result directory are created.
%                                             Otherwise, .sOutputDirectory, .sTmpPath, and .sResultPath
%                                             are emtpy. Default is false.
%
%  OUTPUT                       DESCRIPTION
%  - stEnvLegacy                    (struct)        environment for module
%       .sMessenger                     (handle)        messenger for handling warnings/messages
%       .sOutputDirectory               (string)        root dir
%       .sTmpPath                       (string)        tmp dir
%       .sResultPath                    (string)        result dir
%

%%
if (nargin < 2)
    bCreateDirectories = true;
else
    bCreateDirectories = ~bWithoutDirectories;
end

% init output struct
stEnvLegacy = struct( ...
    'hMessenger',       xEnv, ...
    'sOutputDirectory', '',...
    'sTmpPath',         '',...
    'sResultPath',      '');

% create directories if requested
if bCreateDirectories
    stEnvLegacy.sOutputDirectory = xEnv.createLocalTmpDir();

    stEnvLegacy.sResultPath = fullfile(stEnvLegacy.sOutputDirectory, 'res');
    EPEnvironment.createDirectory(stEnvLegacy.sResultPath);
    
    stEnvLegacy.sTmpPath = fullfile(stEnvLegacy.sOutputDirectory, 'tmp');
    EPEnvironment.createDirectory(stEnvLegacy.sTmpPath);
end
end
