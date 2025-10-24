function ep_ec_post_sl_analysis_adapt(xEnv, sSlArchFile, sMappingFile, sCodeModelFile)
% After SL analysis adapt the Mapping/CodeModel coming from the EC analysis part.
%
% function ep_ec_post_sl_analysis_adapt(xEnv, sSlArchFile, sMappingFile, sCodeModelFile)
%
% Reason why we need this function: SL-Analysis can be more constrained than the EC-Analysis taking place before. This
% means that scopes or interfaces found by EC-Analysis are not valid and were rejected. In order to keep things
% consistent, the Mapping and CodeModel XMLs that were produced solely by EC-Analysis need to be adapted also.
% 
% Problems handled here:
%   1) EPDEV-46691: SF-signals used as Locals are not indexed with SF-StartIndex (usually = 0) as they should be
%      --> Mapping XML potentially needs to be adapted
%
%   2) Unsupported SL data types like (u)int64 can lead to scopes/parameters/locals being rejected from the 
%      Simulink architecture.
%      --> Mapping and CodeModel XML need to be adapted
%
%   3) Unsupported accesses to SL-Functions can lead to scopes being rejected from the SL architecture.
%      --> Mapping and CodeModel XML need to be adapted
%


%%
if (~i_isAvailable(sSlArchFile) || ~i_isAvailable(sMappingFile))
    return;
end

[hSlRoot, xCloseSlArch]       = i_openXml(sSlArchFile);    %#ok
[hMappingRoot, xCloseMapping] = i_openXml(sMappingFile);   %#ok
[hCodeRoot, xCloseCodeModel]  = i_openXml(sCodeModelFile); %#ok

% -- 1) first the SF workaround ...
i_doStateflowIndexAdaptionForMapping(hMappingRoot, hSlRoot);

% -- 2 + 3)  ... now the rejections
stRejections = i_getProtocolledRejections(xEnv.getMessengerFilePath);
if (stRejections.bUnsupportedDataType || stRejections.bUnsupportedSlFunc)
    i_filterUnsupportedScopes(hMappingRoot, hCodeRoot, hSlRoot);
end
if stRejections.bUnsupportedDataType
    i_filterUnsupportedParameters(hMappingRoot, hCodeRoot, hSlRoot);
    i_filterUnsupportedLocals(hMappingRoot, hCodeRoot, hSlRoot)    
end

mxx_xmltree('save', hMappingRoot, sMappingFile);
mxx_xmltree('save', hCodeRoot, sCodeModelFile);
end


%%
function stRejections = i_getProtocolledRejections(sMessageFile)
jSetMessageIds = i_getProtocolledMessageIds(sMessageFile);

stRejections = struct( ...
    'bUnsupportedDataType', i_containsUnsupportedDataTypeMessage(jSetMessageIds), ...
    'bUnsupportedSlFunc',   i_containsUnsupportedSlFuncMessage(jSetMessageIds));
end


%%
function bIsModified = i_doStateflowIndexAdaptionForMapping(hMappingRoot, hSlRoot)
astSfLocals = i_getSfLocals(hSlRoot);
bIsModified = i_adaptSfLocalsInMappingFile(hMappingRoot, astSfLocals);
end


%%
function astSfLocals = i_getSfLocals(hSlRoot)
ahSfLocals = mxx_xmltree('get_nodes', hSlRoot, '/sl:SimulinkArchitecture/model/subsystem/display[@stateflowVariable]');
astSfLocals = arrayfun(@i_createLocalInfo, ahSfLocals);
end


%%
function stLocal = i_createLocalInfo(hSfLocal)
stInfo = mxx_xmltree('get_attributes', hSfLocal, '.', ...
    'path', ...
    'stateflowVariable', ...
    'portNumber');
stLocal = struct( ...
    'sPath',       stInfo.path, ...
    'sSfVariable', stInfo.stateflowVariable, ...
    'sPortNum',    char(stInfo.portNumber), ... % might be [] for *inner* SF locals --> transform then to empty string
    'nStartIndex', i_getStartIndex(hSfLocal));
end


%%
function nStartIndex = i_getStartIndex(hSfLocal)
astRes = mxx_xmltree('get_attributes', hSfLocal, './/*[@startIndex]', 'startIndex');
if ~isempty(astRes)
    nStartIndex = str2num(astRes(1).startIndex); %#ok<ST2NM>
else
    nStartIndex = [];
end
end


%%
function bIsModified = i_adaptSfLocalsInMappingFile(hMappingRoot, astSfLocals)
bIsModified = false;
if isempty(astSfLocals)
    return;
end
sMappingPrefix = '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]';

for i = 1:numel(astSfLocals)
    stLocal = astSfLocals(i);
    
    if isempty(stLocal.sPortNum)
        warning('EP:EC:INNER_SF_LOCALS_NOT_SUPPORTED', 'Inner SF locals cannot be handled.');
        continue;
    end
    
    sLocalPath = sprintf('%s(%s)', stLocal.sPath, stLocal.sPortNum);
    sXPath = sprintf('%s/Path[@path="%s"]', sMappingPrefix, sLocalPath);
    
    ahInterfacePaths = mxx_xmltree('get_nodes', hMappingRoot, sXPath);
    arrayfun(@(h) i_adaptLocalMappingNode(h, stLocal), ahInterfacePaths);
    
    bIsModified = true;
end
end


%%
function i_adaptLocalMappingNode(hInterfacePathNode, stLocal)
sReplacePath = sprintf('%s/%s', stLocal.sPath, stLocal.sSfVariable);
mxx_xmltree('set_attribute', hInterfacePathNode, 'path', sReplacePath);

if isempty(stLocal.nStartIndex)
    return;
end

sId = mxx_xmltree('get_attribute', hInterfacePathNode, 'refId');
ahSignalPathNodes = mxx_xmltree('get_nodes', hInterfacePathNode, sprintf('../SignalMapping/Path[@refId="%s"]', sId));
for i = 1:numel(ahSignalPathNodes)
    i_adaptIndex(ahSignalPathNodes(i), stLocal.nStartIndex);
end
end


%%
function i_adaptIndex(hSignalPath, nStartIndex)
if (nStartIndex == 1)
    return;
end
sOrigPath = mxx_xmltree('get_attribute', hSignalPath, 'path');

% trying to separate signal path into: <signal_struct_access><signal_index_access>
% e.g. path = "a.b.c(2)(1)" --> "a.b.c" & "(2)(1)"
casAccess = regexp(sOrigPath, '^([^()]*)((\(\d+\))+)$', 'tokens', 'once');
if isempty(casAccess) || isempty(casAccess{2})
    warning('EP:EC:INTERNAL_ERROR', 'Unexpected access Local path "%s" found.', sOrigPath);
    return;
end

sNewIndexes = '';
casOrigIndexes = regexp(casAccess{2}, '(\d+)', 'tokens');
for i = 1:numel(casOrigIndexes)
    nOrigIndex = str2num(char(casOrigIndexes{i})); %#ok<ST2NM>
    nNewIndex = nOrigIndex - 1 + nStartIndex;
    
    sNewIndexes = sprintf('%s(%d)', sNewIndexes, nNewIndex);
end

sNewPath = sprintf('%s%s', casAccess{1}, sNewIndexes);
if ~strcmp(sNewPath, sOrigPath)
    mxx_xmltree('set_attribute', hSignalPath, 'path', sNewPath);
end
end


%%
function bIsAvailable = i_isAvailable(sFile)
bIsAvailable = ~isempty(sFile) && exist(sFile, 'file');
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
function i_filterUnsupportedScopes(hMappingRoot, hCodeRoot, hSlRoot)
ahScopeMappings = mxx_xmltree('get_nodes', hMappingRoot, '/Mappings/ArchitectureMapping/ScopeMapping');
for i = 1:length(ahScopeMappings)
    hScopeMapping = ahScopeMappings(i);
    
    hSlScope =  mxx_xmltree('get_nodes', hScopeMapping, './Path[@refId="id0"]');
    sSlScopePath =  mxx_xmltree('get_attribute', hSlScope, 'path');
    hSlSubNode = mxx_xmltree('get_nodes', hSlRoot, sprintf('/sl:SimulinkArchitecture/model/subsystem[@path="%s"]', sSlScopePath));
    if isempty(hSlSubNode) || i_isDummyScope(hSlSubNode)
        ahCCodeScope =  mxx_xmltree('get_nodes', hScopeMapping, './Path[@refId="id1"]');
        sCCodeScopePath =  mxx_xmltree('get_attribute', ahCCodeScope, 'path');
        aiIdx = regexp(sCCodeScopePath, ':');
        sCCodeScopeName = sCCodeScopePath(aiIdx(end)+1:end);
        
        mxx_xmltree('delete_nodes', hCodeRoot, ['/CodeModel/Functions/Function[@name="', sCCodeScopeName, '"]']);
        mxx_xmltree('delete_node', hScopeMapping);
    end
end
end


%%
function i_filterUnsupportedParameters(hMappingRoot, hCodeRoot, hSlRoot)
ahParameterMappings = mxx_xmltree('get_nodes', hMappingRoot, ...
    '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Parameter"]');
for i = 1:length(ahParameterMappings)
    hParamMapping = ahParameterMappings(i);
    
    % Assumption: for the EC-workflow the mapping file contains only the name of the Parameter as path
    ahSlParameter = mxx_xmltree('get_nodes', hParamMapping, './Path[@refId="id0"]');
    sSlParameterName = mxx_xmltree('get_attribute', ahSlParameter, 'path');
    
    casNameParts = strsplit(sSlParameterName, ':');
    if (numel(casNameParts) > 1)
        % for workspace parameters, we need to take the source into account
        ahSlParameterNodes = mxx_xmltree('get_nodes', hSlRoot, sprintf( ...
            '/sl:SimulinkArchitecture/model/subsystem/parameter[@name="%s"]/source[@file="%s"]', ...
            casNameParts{2}, casNameParts{1}));    
    else
        ahSlParameterNodes = mxx_xmltree('get_nodes', hSlRoot, sprintf( ...
            '/sl:SimulinkArchitecture/model/subsystem/parameter[@name="%s"]', sSlParameterName));
    end
    if isempty(ahSlParameterNodes)
        ahCCodeScope = mxx_xmltree('get_nodes', hParamMapping, './Path[@refId="id1"]');
        sCCodeScopePath = mxx_xmltree('get_attribute', ahCCodeScope, 'path');
        
        mxx_xmltree('delete_nodes', hCodeRoot, ...
            ['/CodeModel/Functions/Function/Interface/InterfaceObj[@kind="cal" and @var="', sCCodeScopePath, '"]']);
        mxx_xmltree('delete_node', hParamMapping);
    end
end
end


%%
function i_filterUnsupportedLocals(hMappingRoot, hCodeRoot, hSlRoot)
ahLocalMappings = mxx_xmltree('get_nodes', hMappingRoot, ...
    '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]');
for i = 1:length(ahLocalMappings)
    hLocalMapping = ahLocalMappings(i);
    
    ahSlLocal =  mxx_xmltree('get_nodes', hLocalMapping, './Path[@refId="id0"]');
    sSlLocalPath =   mxx_xmltree('get_attribute', ahSlLocal, 'path');
    hSlDisplayNodes = mxx_xmltree('get_nodes', hSlRoot, ...
        ['/sl:SimulinkArchitecture/model/subsystem/display[@path="', sSlLocalPath, '"]']);
    if isempty(hSlDisplayNodes)
        % Check the case that the port number ist part of the mapping information
        aiIdx = regexp(sSlLocalPath, '(');
        if ~isempty(aiIdx)
            sSlLocalPath = sSlLocalPath(1:aiIdx(end)-1);
            hSlDisplayNodes = mxx_xmltree('get_nodes', hSlRoot, ...
                ['/sl:SimulinkArchitecture/model/subsystem/display[@path="', sSlLocalPath, '"]']);
        end
        if isempty(hSlDisplayNodes)
            ahCCodeScope =  mxx_xmltree('get_nodes', hLocalMapping, './Path[@refId="id1"]');
            sCCodeScopePath =  mxx_xmltree('get_attribute', ahCCodeScope, 'path');
            mxx_xmltree('delete_nodes', hCodeRoot, ...
                ['/CodeModel/Functions/Function/Interface/InterfaceObj[@kind="disp" and @var="', sCCodeScopePath, '"]']);
            mxx_xmltree('delete_node', hLocalMapping);
        end
    end
end
end


%%
function bIsDummy = i_isDummyScope(hSlScope)
bIsDummy = ~isempty(hSlScope) && strcmpi('DUMMY', mxx_xmltree('get_attribute', hSlScope, 'scopeKind'));
end


%%
function bContains = i_containsUnsupportedDataTypeMessage(jSetMessageIds)
bContains = false;

casRelevantMsgIds = {...
    'ATGCV:MOD_ANA:NOT_SUPPORTED_SIMULINK_PARAMETER', ...
    'ATGCV:MOD_ANA:LIMITATION_UNSUPPORTED_TYPE_INTERFACE', ...
    'ATGCV:MOD_ANA:NOT_SUPPORTED_LOCAL_DISPLAY', ...
    'ATGCV:MOD_ANA:LOCAL_DS_UNSUPPORTED_TYPE'};
for i = 1:numel(casRelevantMsgIds)
    if jSetMessageIds.contains(casRelevantMsgIds{i})
        bContains = true;
        return;
    end
end
end


%%
function bContains = i_containsUnsupportedSlFuncMessage(jSetMessageIds)
bContains = jSetMessageIds.contains('ATGCV:MOD_ANA:UNSUPPORTED_SL_FUNCTION_ACCESS');
end


%%
function jSetMessageIds = i_getProtocolledMessageIds(sMessageFile)
jSetMessageIds = java.util.HashSet;
if ~i_isAvailable(sMessageFile)
    return;
end

[hMsgs, xCloseMsgs] = i_openXml(sMessageFile); %#ok
astRes = mxx_xmltree('get_attributes', hMsgs, '/Messages/Message', 'id');
for i = 1:numel(astRes)
    jSetMessageIds.add(astRes(i).id);
end
end
