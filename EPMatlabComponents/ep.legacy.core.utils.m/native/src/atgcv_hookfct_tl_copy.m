function atgcv_hookfct_tl_copy(stEnv, sSourceDir, sTargetDir)
% Copies the TL hookfct from the source director to the target directoy
%
% function atgcv_hookfct_tl_copy(stEnv, sSourceDir, sTargetDir)
%
%   INPUT               DESCRIPTION
%     sSourceDir          (string)      Source Directory Full Path
%     sTargetDir          (string)      Target Directory Full Path
% 
%  <et_copyright>

%% Internal
%   REFERENCE(S):
%     Design Document:
%
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2010
%
%%

%% Check parameters



%% Check if both directories exist
if ~exist(sSourceDir, 'dir')
    osc_messenger_add(stEnv, 'ATGCV:STD:HOOK_SOURCE_DIR', 'dir', sSourceDir);
    return;
end

if ~exist(sTargetDir,'dir')
    osc_messenger_add(stEnv, 'ATGCV:STD:HOOK_TARGET_DIR', 'dir', sTargetDir);
    return;
end

if strcmp(sSourceDir, sTargetDir)
	return; % Nothing to do here (source and target are equal)
end


sFormerPaths = addpath(sSourceDir);
        
try
    casHookPatterns = {'*_hook*.*'};
    for k = 1:length(casHookPatterns)
        sHookPattern = casHookPatterns{k};

        hookFcnName = tl_find_hook(sHookPattern, {sSourceDir});
        for i = 1:length( hookFcnName )
            sHookFcn = hookFcnName{i};
            sFullHookFcn = fullfile( sSourceDir, sHookFcn );
            copyfile(sFullHookFcn, sTargetDir, 'f');
        end
    end
catch
end
rmpath(sSourceDir);
addpath(sFormerPaths);
        
sConfigDir = fullfile(sSourceDir, 'config');
if exist(sConfigDir, 'dir')
    sTargetConDir = fullfile(sTargetDir, 'config');
    atgcv_m_copydir(sConfigDir, sTargetConDir);
end
end

%**************************************************************************
% END OF FILE
%**************************************************************************