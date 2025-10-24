function atgcv_m13_tl_logging_analyze(hExtractionTopSub, bBreakModelRefs, bFullLogging, hLoggingAnalysis)
% Analyze TL logging for TL SIL workflows (TL SIL, TL PIL, ClosedLoop Derive).
%
% function  atgcv_m13_tl_logging_analyze(hExtractionTopSub, bBreakModelRefs, bFullLogging, hLoggingAnalysis)
%
%   INPUTS               DESCRIPTION
%   OUTPUT               DESCRIPTION
%     -                     -
%


%%
i_addToplevelSub(hLoggingAnalysis, hExtractionTopSub, bBreakModelRefs);
if bFullLogging
    ahExtractionNestedSubs = i_getNestedSubsystemsForLogging(hExtractionTopSub);
    arrayfun(@(h) i_addNestedSub(hLoggingAnalysis, h, bBreakModelRefs), ahExtractionNestedSubs);
end
end


%%
function hLoggingSub = i_addToplevelSub(hLoggingAnalysis, hExtractionSub, bBreakModelRefs)
hLoggingSub = mxx_xmltree('add_node', hLoggingAnalysis, 'Subsystem');
i_transferSubsystemAttributes(hExtractionSub, hLoggingSub);

% note: for the toplevel sub we just want to log the Locals (aka Display in ExtractionModel XML)
ahBlocks = mxx_xmltree('get_nodes', hExtractionSub, './Display');
arrayfun(@(h) i_addLoggingNode(hLoggingSub, h, 'Local', bBreakModelRefs), ahBlocks);
end


%%
function hLoggingSub = i_addNestedSub(hLoggingAnalysis, hExtractionSub, bBreakModelRefs)
hLoggingSub = mxx_xmltree('add_node', hLoggingAnalysis, 'Subsystem');
i_transferSubsystemAttributes(hExtractionSub, hLoggingSub);

% note: for the nested subs we just want to log the Inputs and Parameters
ahBlocks = mxx_xmltree('get_nodes', hExtractionSub, './InPort');
arrayfun(@(h) i_addLoggingNode(hLoggingSub, h, 'Input', bBreakModelRefs), ahBlocks);

ahBlocks = mxx_xmltree('get_nodes', hExtractionSub, './Calibration');
arrayfun(@(h) i_addLoggingNode(hLoggingSub, h, 'Parameter', bBreakModelRefs), ahBlocks);
end


%%
function ahSubsForLogging = i_getNestedSubsystemsForLogging(hExtractionTopSub)
% note: currently it's enough to look out for descendant Subsystem nodes with an *existing* subsystemLogging attribute
%       not checking for any specific value here!
ahSubsForLogging = mxx_xmltree('get_nodes', hExtractionTopSub, './/Scope[@subsystemLogging]');
end


%%
function i_transferSubsystemAttributes(hExtractonSub, hLoggingSub)
sId = mxx_xmltree('get_attribute', hExtractonSub, 'uid');
sSampleTime = mxx_xmltree('get_attribute', hExtractonSub, 'sampleTime');

mxx_xmltree('set_attribute', hLoggingSub, 'id', sId);
mxx_xmltree('set_attribute', hLoggingSub, 'sampleTime', sSampleTime);
end


%%
function hLoggingNode = i_addLoggingNode(hLoggingSub, hBlock, sKind, bBreakModelRefs)
hLoggingNode = mxx_xmltree('add_node', hLoggingSub, 'Logging');

mxx_xmltree('set_attribute', hLoggingNode, 'kind', sKind);

sID = char(java.util.UUID.randomUUID());
mxx_xmltree('set_attribute', hLoggingNode, 'id', sID);

i_copyAttributeIfNotEmpty(hBlock, hLoggingNode, 'startIdx');

[sBlock, sModelRef] = atgcv_m13_object_block_get(hBlock, bBreakModelRefs);
bIsModelRef = ~isempty(sModelRef);
sModule = i_getModuleName(sBlock, sModelRef);
if ~isempty(sModelRef)
    mxx_xmltree('set_attribute', hLoggingNode, 'module', sModule);
end

sPortNo = mxx_xmltree('get_attribute', hBlock, 'portNumber');
bIsSFVariable = isempty(sPortNo);

sStateflowVar = '';
if bIsSFVariable
    sStateflowVar = i_findStateflowVar(hBlock);
end
if ~isempty(sStateflowVar)
    mxx_xmltree('set_attribute', hLoggingNode, 'stateflowVariable', sStateflowVar);
    mxx_xmltree('set_attribute', hLoggingNode, 'block', [sBlock, '.', sStateflowVar]);
else
    mxx_xmltree('set_attribute', hLoggingNode, 'block', sBlock);
end

if bIsSFVariable
    mxx_xmltree('set_attribute', hLoggingNode, 'path', sBlock);
    
    hParentSub = mxx_xmltree('get_nodes', hBlock, '..');
    sDdVarPath = atgcv_m13_ddvarref_get(hParentSub, sModule, sBlock, '', bIsModelRef);
    mxx_xmltree('set_attribute', hLoggingNode, 'ddVarPath', sDdVarPath);
    
else
    mxx_xmltree('set_attribute', hLoggingNode, 'path', sBlock);
    mxx_xmltree('set_attribute', hLoggingNode, 'port', sPortNo);
end

if strcmp(sKind, 'Parameter')
    i_addParamAttributes(hLoggingNode, hBlock);
end

ahIfName = mxx_xmltree('get_nodes', hBlock, './/ifName');
for j = 1:length(ahIfName)
    hIfName = ahIfName(j);
    
    hAccess = mxx_xmltree('add_node', hLoggingNode, 'Access');
        
    i_copyAttributeIfNotEmpty(hIfName, hAccess, 'ifid');
    i_copyAttributeIfNotEmpty(hIfName, hAccess, 'identifier');
    
    sDisplayName = atgcv_m13_display_name(hIfName);
    mxx_xmltree('set_attribute', hAccess, 'displayName', sDisplayName);
    
    i_copyAttributeIfNotEmpty(hIfName, hAccess, 'index1');
    i_copyAttributeIfNotEmpty(hIfName, hAccess, 'index2');
    
    hVarNode = mxx_xmltree('get_nodes', hIfName, 'parent::Variable');
    
    i_copyAttributeIfNotEmpty(hVarNode, hAccess, 'signalType');
    
    sSignalName = mxx_xmltree('get_attribute', hVarNode, 'signalName');
    if ~isempty(sSignalName)
        
        % check if signal name contains artifical bus (e.g. % <signal1>)
        sBusName = atgcv_m13_busname_get(sSignalName);
        if( ~isempty(sBusName) )
            if( sBusName(1)=='<' && sBusName(end)=='>' )
                sSignalName = atgcv_m13_regexprep(sSignalName, sBusName, '');
            end
        end
        mxx_xmltree('set_attribute', hAccess, 'signalName', sSignalName);
        
    else
        if ds_isa(sBlock, 'tlblock')
            if ~isempty(sPortNo)
                casOutports = ep_find_system(sBlock, ...
                    'LookUnderMasks','on', ...
                    'FollowLinks','on', ...
                    'Parent', sBlock, ...
                    'BlockType', 'Outport', ...
                    'Port', sPortNo);
                if ~isempty(casOutports)
                    sName = get_param(casOutports{1}, 'Name');
                    mxx_xmltree('set_attribute', hAccess, 'signalName', sName);
                end
            end
        end
    end
end
end


%%
function sStateflowVar = i_findStateflowVar(hBlock)
sStateflowVar = mxx_xmltree('get_attribute', hBlock, 'stateflowVariable');
if isempty(sStateflowVar)
    astRes = mxx_xmltree('get_attributes', hBlock, './CalibrationUsage', 'stateflowVariable');
    if ~isempty(astRes)
        sStateflowVar = astRes(1).stateflowVariable;
    end
end
end


%%
function sModule = i_getModuleName(sBlock, sModelRef)
if ~isempty(sModelRef)
    sModule = sModelRef;
else
    ccasCandidates = regexp(sBlock, '.*?/([^/]+)/Subsystem/\1/.*', 'tokens');
    if ~isempty(ccasCandidates)
        sModule = char(ccasCandidates{1});
    else
        sModule = '';
    end
end
end


%%
function i_addParamAttributes(hLoggingNode, hBlock)
i_copyAttributeIfNotEmpty(hBlock, hLoggingNode, 'ddPath');

ahCalUsages = mxx_xmltree('get_nodes', hBlock, './CalibrationUsage');
if isempty(ahCalUsages)
    return;
end
hCalUsage = ahCalUsages(1);

i_copyAttributeIfNotEmpty(hCalUsage, hLoggingNode, 'blockAttribute', 'blockUsage');
end


%%
function sAttribValue = i_copyAttributeIfNotEmpty(hSrcNode, hTargetNode, sAttribName, sNewAttribName)
if (nargin < 4)
    sNewAttribName = sAttribName;
end

sAttribValue = mxx_xmltree('get_attribute', hSrcNode, sAttribName);
if ~isempty(sAttribValue)
    mxx_xmltree('set_attribute', hTargetNode, sNewAttribName, sAttribValue);
end
end
