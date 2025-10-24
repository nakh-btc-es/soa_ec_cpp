function atgcv_m13_prepare_subsys( hSub )
% Remove the trigger and enable inports of the subystem. It also removes the tl dummy trigger and enable inports
%
% Parameters:
%   hSub        (handle)  of the new inserted subsystem
%
% Output:
%
%%

atgcv_m13_break_linkstatus(hSub);


% remove trigger block
hTrigger = ep_find_system( hSub, ...
    'LookUnderMasks','on',      ...
    'SearchDepth',    1,        ...
    'CaseSensitive', 'off',     ...
    'BlockType',     'TriggerPort');
if ~isempty(hTrigger)
    hTrigger = i_getDummyPort(hTrigger);  
    delete_block(hTrigger);  
end

% remove enable block
hEnable = ep_find_system( hSub, ...
    'LookUnderMasks','on',      ...
    'SearchDepth',    1,        ...
    'CaseSensitive', 'off',     ...
    'BlockType',     'EnablePort');
if ~isempty(hEnable)
    hEnable = i_getDummyPort(hEnable);
    delete_block(hEnable);
end

% remove action block
hAction = ep_find_system( hSub, ...
    'LookUnderMasks','on',      ...
    'SearchDepth',    1,        ...
    'CaseSensitive', 'off',     ...
    'BlockType',     'ActionPort');
if ~isempty(hAction)
    delete_block(hAction);
end
end


%%
function hPort = i_getDummyPort(hPort)
hParent = get_param(get_param(hPort, 'Parent'), 'Handle');
if strcmp(get_param(hParent, 'MaskType'), 'TL_SimFrame')
    % if the trigger/enable port is found in the targetlink frame, then we deal here with the dummy trigger/enable port
    % feature - this means we need to find the dummy port in the subsystem and to remove it, removing only the port
    % found in the frame is not enough
    sParentPath = get(hParent, 'Path');
    sParentName = get(hParent, 'Name');
    sSub = strcat(sParentPath, '/', sParentName, '/', 'Subsystem', '/', sParentName);
    hSub = get_param(sSub, 'Handle');
    hDummyPort = ep_find_system( hSub, ...
        'LookUnderMasks','on',      ...
        'SearchDepth',    1,        ...
        'CaseSensitive', 'off',     ...
        'OpenFcn',     'tl_openport(gcbh);');
    hPort = hDummyPort;
end
end

