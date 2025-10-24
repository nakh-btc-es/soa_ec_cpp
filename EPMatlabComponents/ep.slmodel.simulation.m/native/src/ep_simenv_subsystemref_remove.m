function [nBreakCnt, hSub] = ep_simenv_subsystemref_remove(stEnv, hSub)
% Resolves all subsystem references in the Subsystem
%
% function nBreakCnt = ep_simenv_subsystemref_remove(stEnv, hSub)
%
% INPUTS             DESCRIPTION
%   stEnv            (struct)    Environment structure
%   hSub             (handle)    Simulink/TargetLink subsystem
%
%
% OUTPUTS:
%

%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Andreea Hinrichs
% $$$COPYRIGHT$$$-2020
%
%%
nBreakCnt = 0;

casSubRefs = ep_find_system(getfullname(hSub),...
    'LookUnderMasks',      'on', ...
    'FollowLinks',         'off', ...
    'RegExp',              'on', ...
    'BlockType',           'SubSystem', ...
    'ReferencedSubsystem', '.');

if isempty(casSubRefs)
    return;
end

% the provided subsystem might itself be a referenced subsystem
% --> if this is the case, later when the references are resolved the handle will become invalid
% --> retrieve path and some other infos now (note: subsystem path remains valid although the handle does not)
sSubsysPath = getfullname(hSub);
bIsSubRef = strcmp(get_param(hSub, 'type'), 'block') && ~isempty(get_param(hSub, 'ReferencedSubsystem'));

% sort paths by length
[~, anPathLength] = sort(cellfun(@length, casSubRefs), 'ascend');
casSubRefs = casSubRefs(anPathLength);
for i = 1:numel(casSubRefs)
    i_subsystemReferenceReplace(stEnv, casSubRefs{i});
    nBreakCnt = nBreakCnt + 1;
end

if bIsSubRef
    % if the subsystem was replaced, the provided subsystem handle has become invalid and needs to be refreshed via the
    % memorized subsystem path
    hSub = get_param(sSubsysPath, 'Handle');
end
end


%%
function i_subsystemReferenceReplace(stEnv, sSubPath)
bSuccess = i_refSubToSubsystem(sSubPath);
if ~bSuccess
    stErr = osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:SUBSYSTEMREF_DISABLED_FAILED', ...
        'block', sSubPath);
    osc_throw(stErr);
end
end

%%
function bSuccess = i_refSubToSubsystem(sSubPath)
bSuccess = true; %#ok
sParentPath = get_param(sSubPath, 'Parent');
sSubName = get_param(sSubPath, 'Name');
try
    hNewSys = add_block('built-in/Subsystem', ...
        [sParentPath, '/', 'BTC_Subsystem'], ...
        'MakeNameUnique','on', 'Position', get_param(sSubPath, 'Position'));
    Simulink.BlockDiagram.copyContentsToSubsystem(get_param(sSubPath, 'ReferencedSubsystem'), hNewSys);
    i_connectNewSubsystem(get_param(sSubPath, 'LineHandles'), hNewSys);
    delete_block(sSubPath);
    set_param(hNewSys, 'Name', sSubName);
catch oEx %#ok
    bSuccess = false;
end
end

%%
function i_connectNewSubsystem(stLineHandles, hNewAddedSub)
stSubsystemPortHandles = get(hNewAddedSub, 'PortHandles');
casPortTypes = fieldnames(stSubsystemPortHandles);
for i=1:numel(casPortTypes)
    if ~isempty(stSubsystemPortHandles.(casPortTypes{i}))
        switch lower(casPortTypes{i})
            case 'inport'
                ahSubPorts = stSubsystemPortHandles.(casPortTypes{i});
                ahLinesToSubPorts = stLineHandles.(casPortTypes{i});
                i_addLinesToSubPorts(hNewAddedSub, ahSubPorts, ahLinesToSubPorts);
            case 'outport'
                ahSubPorts = stSubsystemPortHandles.(casPortTypes{i});
                ahLinesFromSubPorts = stLineHandles.(casPortTypes{i});
                i_addLinesFromSubPorts(hNewAddedSub, ahSubPorts, ahLinesFromSubPorts);
            case 'enable'
                ahSubPorts = stSubsystemPortHandles.(casPortTypes{i});
                ahLinesToSubPorts = stLineHandles.(casPortTypes{i});
                i_addLinesToSubPorts(hNewAddedSub, ahSubPorts, ahLinesToSubPorts);
            case 'trigger'
                ahSubPorts = stSubsystemPortHandles.(casPortTypes{i});
                ahLinesToSubPorts = stLineHandles.(casPortTypes{i});
                i_addLinesToSubPorts(hNewAddedSub, ahSubPorts, ahLinesToSubPorts);
        end
    end
end
end

%%
function i_addLinesToSubPorts(hNewAddedSub, ahSubPorts, ahLinesToSubPorts)
for i=1:numel(ahLinesToSubPorts)
    if ahLinesToSubPorts(i)~=-1
        hSrcPort = get_param(ahLinesToSubPorts(i),'SrcPortHandle');
        hOldDest = get_param(ahLinesToSubPorts(i),'DstPortHandle');
        nPortNumber = get_param(hOldDest, 'PortNumber');
        
        delete_line(ahLinesToSubPorts(i));
        if strcmp(get_param(ahSubPorts, 'PortType'), 'inport')
            add_line(get_param(hNewAddedSub, 'Parent'), hSrcPort, ahSubPorts(nPortNumber), 'autorouting', 'on');
        else
            %a subsystem can not have more than one enable, trigger, reset or action port
            add_line(get_param(hNewAddedSub, 'Parent'), hSrcPort, ahSubPorts(1), 'autorouting', 'on');
        end
    end
end
end

%%
function i_addLinesFromSubPorts(hNewAddedSub, ahSubPorts, ahLinesFromSubPorts)
for i=1:numel(ahLinesFromSubPorts)
    if ahLinesFromSubPorts(i)~=-1
        hOldSrcPort = get_param(ahLinesFromSubPorts(i),'SrcPortHandle');
        nPortNumber = get_param(hOldSrcPort, 'PortNumber');
        hDest = get_param(ahLinesFromSubPorts(i),'DstPortHandle');
        
        delete_line(ahLinesFromSubPorts(i));
        for j=1:numel(hDest)
            add_line(get_param(hNewAddedSub, 'Parent'), ahSubPorts(nPortNumber), hDest(j), 'autorouting', 'on');
        end
    end
end
end

%%
function sNewSubName = i_getCreatedSubName(sParentPath, sSubName)
sNewSubName='';
casCreatedSub = ep_find_system([sParentPath, '/', sSubName], ...
    'SearchDepth', '1',...
    'FindAll',     'off', ...
    'BlockType',   'SubSystem');
casCreatedSub = i_excludeFromArray(casCreatedSub, [sParentPath, '/', sSubName]);
if ~isempty(casCreatedSub)
    sNewSubName = strrep(casCreatedSub{1},[sParentPath, '/', sSubName, '/'], '');
end
end

%%
function aElems = i_excludeFromArray(aElems, xElem)
if ischar(xElem)
    for i=1:numel(aElems)
        if strcmp(xElem, aElems{i})
            aElems(i) = [];
            break;
        end
    end
end
if isnumeric(xElem)
    for i=1:numel(aElems)
        if (xElem == aElems(i))
            aElems(i) = [];
            break;
        end
    end
end
end



