function astSubs = ep_ec_export_func_subsystems_get(xModel)
% Retrieves all subsystems from the model that are called via a func-call trigger signal coming from a root Inport.
%
% Note: model needs to be in compiled mode
%

hModel = i_normalize(xModel);
if i_hasFcnCallRootInport(hModel)
    astSubs = i_findExportFuncSubsRecursively(hModel);
    
    ahModelRefs = i_getModelRefs(hModel);
    for i = 1:numel(ahModelRefs)
        astSubs = [astSubs, i_findExportFuncSubsRecursively(ahModelRefs(i))]; %#ok<AGROW>
    end
else
    astSubs = [];
end
end


%%
function hModel = i_normalize(xModel)
hModel = get_param(xModel, 'handle');
end


%%
function ahModelRefs = i_getModelRefs(hModel)
ahModelRefs = [];
casMdlRefs = ep_find_mdlrefs(hModel);
if (numel(casMdlRefs) > 1)
    ahModelRefs = cellfun(@i_normalize, reshape(casMdlRefs(1:end-1), 1, []));
end
end


%%
function astSubs = i_findExportFuncSubsRecursively(hSearchRoot)
ahSubs = ep_find_system(hSearchRoot,...
    'SearchDepth',        1, ...
    'FollowLinks',        'on',...
    'LookUnderMasks',     'all',...
    'IncludeCommented',   'off',...
    'BlockType',          'SubSystem', ...
    'IsSubsystemVirtual', 'off');
astSubs = i_filterExportFuncSubs(ahSubs);

ahVirtualSubs = ep_find_system(hSearchRoot,...
    'SearchDepth',        1, ...
    'FollowLinks',        'on',...
    'LookUnderMasks',     'all',...
    'IncludeCommented',   'off',...
    'BlockType',          'SubSystem', ...
    'IsSubsystemVirtual', 'on');
if ~isempty(ahVirtualSubs)
    ahVirtualSubs = setdiff(ahVirtualSubs, hSearchRoot);
    for i = 1:numel(ahVirtualSubs)
        astSubs = [astSubs, i_findExportFuncSubsRecursively(ahVirtualSubs(i))]; %#ok<AGROW>
    end
end
end


%%
function bHasRootFcnCall = i_hasFcnCallRootInport(hModel)
bHasRootFcnCall = numel(ep_find_system(hModel, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on')) > 0;
end


%%
function astSubs = i_filterExportFuncSubs(ahSubCandidates)
astSubs = repmat(struct( ...
    'sSubsystem',     '', ...
    'sFcnCallInport', ''), 1, numel(ahSubCandidates));

abSelect = false(size(astSubs));
for i = 1:numel(ahSubCandidates)
    hSub = ahSubCandidates(i);
    
    stSubSysPh = get(hSub, 'PortHandles');
    if ~isempty(stSubSysPh.Trigger)
        stTrigPortProps = get(stSubSysPh.Trigger);
        bIsFunctionTrigger = strcmp(stTrigPortProps.CompiledPortDataType, 'fcn_call');
        if bIsFunctionTrigger
            hSrcBlk = i_findSrcInportBlock(stTrigPortProps.Line);
            if ~isempty(hSrcBlk)
                astSubs(i).sSubsystem = getfullname(hSub);
                astSubs(i).sFcnCallInport = get_param(hSrcBlk, 'name');
                abSelect(i) = true;
            end
        end
    end
end
astSubs = astSubs(abSelect);
end


%%
function hSrcBlk = i_findSrcInportBlock(hLine)
%Find the connected Inport block which is sending a Function-call signal.
if (hLine < 0)
    hSrcBlk = [];
    return;
end

hSrcBlk = get(hLine, 'SrcBlockHandle');
if ~isempty(hSrcBlk)
    switch get(hSrcBlk, 'BlockType')
        case 'Inport'
            if ~strcmp(get(hSrcBlk, 'OutputFunctionCall'), 'on')
                sParent = get(hSrcBlk, 'Parent');
                if ~strcmpi(get_param(sParent, 'Type'), 'block')
                    hSrcBlk = [];
                else
                    iPort = str2double(get(hSrcBlk, 'Port'));
                    stPortHandles = get(get_param(sParent, 'handle'), 'PortHandles');
                    hBlockInport = stPortHandles.Inport(iPort);
                    hLine = get(hBlockInport, 'Line');
                    hSrcBlk  = i_findSrcInportBlock(hLine);
                end
            end
            
        case 'FunctionCallSplit'
            stPortHandles = get(hSrcBlk, 'PortHandles');
            hLine = get(stPortHandles.Inport(1), 'Line');
            hSrcBlk = i_findSrcInportBlock(hLine);
            
        otherwise
            hSrcBlk = [];
    end
end
end
