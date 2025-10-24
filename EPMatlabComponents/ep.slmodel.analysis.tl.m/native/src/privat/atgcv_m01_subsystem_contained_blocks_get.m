function astBlocks = atgcv_m01_subsystem_contained_blocks_get(stEnv, xSubsys)
% Get all child blocks of the provided Subsystem.
%
% function astBlocks = ...
%               atgcv_m01_subsystem_contained_blocks_get(stEnv, xSubsystem)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)        error messenger environment
%     xSubsys           (handle/string) handle or model path of Simulink Subsystem
%
%   OUTPUT              DESCRIPTION
%     astBlocks         (array)     structs witht the following fields:
%       .sName          (string)      name of the block
%       .sPath          (string)      model path of the block
%       .sType          (string)      type of the block
%
%   REMARKS
%
%   <et_copyright>


%% main
hSubsys = i_normalizeSubsys(stEnv, xSubsys);

ahBlocks = ep_find_system(hSubsys, 'SearchDepth', 1, 'BlockType', 'SubSystem');

% Note: also hSubsys itself is found --> exclude it from result list
ahBlocks = ahBlocks(ahBlocks ~= hSubsys); 

nBlocks = length(ahBlocks);
astBlocks = repmat(struct( ...
    'sName', '', ...
    'sPath', '', ...
    'sType', ''), 1, nBlocks);
for i = 1:nBlocks
    astBlocks(i).sName = get_param(ahBlocks(i), 'Name');
    astBlocks(i).sPath = getfullname(ahBlocks(i));
    astBlocks(i).sType = get_param(ahBlocks(i), 'BlockType');
end
end


function hSubsys = i_normalizeSubsys(stEnv, xSubsys)
try
    hSubsys = get_param(xSubsys, 'handle');
catch oEx
    error('ATGCV:MOD_ANA:INTERNAL_ERROR', ...
        'Provided Subsystem is invalid: %s', oEx.message);
end
end



