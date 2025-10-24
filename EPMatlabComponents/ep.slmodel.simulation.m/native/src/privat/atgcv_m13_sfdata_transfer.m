function atgcv_m13_sfdata_transfer(stEnv, xSource, xTarget, bOverwrite)
% Transform Stateflow Data and Events from one model to another
% 
% function atgcv_m13_sfdata_transfer(stEnv, hSource, hTarget, bOverwrite)
%
%   INPUT               DESCRIPTION
%       stEnv             (struct)         environment structure:
%                                          field hMessenger with messenger object is needed for messages
%                                          Note1: if the struct is empty, no messages are entered
%                                          Note2: if the field is empty, messages are entered into the global messenger
%       xSource           (string/handle)  source handle or path
%       xTarget           (string/handle)  destination handle or path
%       bOverwrite        (logical)        Optional flag that specifies if existing stateflow data is to be 
%                                          replaced (true) or kept (false)
%                                          Default: false
%


%%
if (nargin < 4)
    bOverwrite = false;
end

% Copy stateflow data into the new destintation subsystem if necessary
bHasStateflowContent = ~isempty(ep_find_system(xSource, ...
    'FollowLinks',    'on', ...
    'LookUnderMasks', 'all', ...
    'MaskType',       'Stateflow'));

if bHasStateflowContent
    oSfRoot = sfroot;
    
    sSrcModel = get_param(bdroot(xSource), 'Name');
    oSrcMachine = oSfRoot.find('-isa', 'Stateflow.Machine', '-and', 'Name', sSrcModel);
    
    sDstModel = get_param(bdroot(xTarget), 'Name');
    oDstMachine = oSfRoot.find('-isa', 'Stateflow.Machine', '-and', 'Name', sDstModel);

    if ~isempty(oSrcMachine) && ~isempty(oDstMachine)
        srcData    = oSrcMachine.findShallow('Data');
        dstData    = oDstMachine.findShallow('Data');
        srcEvents  = oSrcMachine.findShallow('Event');
        dstEvents  = oDstMachine.findShallow('Event');
        
        % Prepare variables for transfer
        if ~isempty(dstData)
            casDstDataNames = get(dstData, 'Name');
            if ~iscell(casDstDataNames)
                casDstDataNames = {casDstDataNames};
            end
        else
            casDstDataNames = {};
        end
        
        if ~isempty(dstEvents)
            casDstEventNames = get(dstEvents, 'Name');
            if ~iscell(casDstEventNames)
                casDstEventNames = {casDstEventNames};
            end
        else
            casDstEventNames = {};
        end
                
        % Transfer stateflow data
        for i = 1:length(srcData)
            abReplace = strcmp(srcData(i).Name, casDstDataNames);
            bSfExists = any(abReplace);
            if bOverwrite
                % Remove data that is to be replaced
                for j = find(abReplace)
                    dstData(j).delete;
                end
            end
            if ~bSfExists || bOverwrite
                % use clipboard to copy data and events from source model to destination model
                clipboard = sfclipboard();
                clipboard.copy(srcData(i));
                clipboard.pasteTo(oDstMachine);
            end
            
            if bSfExists
                i_addMessage(stEnv, 'Data', srcData(i).Name, sSrcModel, sDstModel, bOverwrite);
            end
        end
        
        % Transfer stateflow events
        % TODO: Events are not allowed on the Rootlevel of Libraries, so this code might never be used
        for i = 1:length(srcEvents)
            abReplace = strcmp(srcEvents(i).Name, casDstEventNames);
            bSfExists = any(abReplace);
            if bOverwrite
                % Remove event that is to be replaced
                for j = find(abReplace)
                    dstEvents(j).delete;
                end
            end
            if ~bSfExists || bOverwrite
                clipboard = sfclipboard();
                clipboard.copy(srcEvents(i));
                clipboard.pasteTo(oDstMachine);
            end
            
            if bSfExists
                i_addMessage(stEnv, 'Events', srcEvents(i).Name, sSrcModel, sDstModel, bOverwrite);
            end
        end
    end
end
end


%%
function i_addMessage(stEnv, sKind, sName, sSrcModel, sDstModel, bOverwritten)
if isempty(stEnv)
    return;
end

if bOverwritten
    atgcv_messenger_add(stEnv.hMessenger, ...
        'ATGCV:MIL_GEN:SF_REPLACED', ...
        'kind',   sKind, ...
        'name',   sName, ...
        'source', sSrcModel, ...
        'target', sDstModel);
else
    atgcv_messenger_add(stEnv.hMessenger, ...
        'ATGCV:MIL_GEN:SF_NAME_CLASH', ...
        'kind',   'Data', ...
        'name',   sName, ...
        'source', sSrcModel);
end
end

