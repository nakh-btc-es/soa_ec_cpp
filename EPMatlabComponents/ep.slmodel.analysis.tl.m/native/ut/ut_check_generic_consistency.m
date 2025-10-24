function ut_check_generic_consistency(varargin)
% Check fix for Bug EP_828
%
%  REMARKS
%       Bug: Sub-structure in referenced models is not correctly taken over into SL architecture.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%%
%   NOTE: this function is intended for checking generic consistency rules
%         BUT currently only (Mapping|TlArch) checking supported

%%
stArgs = i_evalArgs(varargin{:});

if isempty(stArgs.Mapping)
    return;
end
if isempty(stArgs.TlArch)
    return;
end
i_checkConsistencyMappingTlArch(stArgs.Mapping, stArgs.TlArch);
end


%%
function i_checkConsistencyMappingTlArch(sMappingFile, sTlArchFile)
[hMappingDoc, xCloseMappingDoc] = i_loadXML(sMappingFile); %#ok<NASGU> onCleanup object
[hTlArchDoc, xCloseTlArchDoc]   = i_loadXML(sTlArchFile); %#ok<NASGU> onCleanup object

sTlID = 'id0';

ahScopeMappings = mxx_xmltree('get_nodes', hMappingDoc, '/Mappings/ArchitectureMapping/ScopeMapping');
for i = 1:numel(ahScopeMappings)
    hScopeMapping = ahScopeMappings(i);
    sScopePath = i_getMappingPath(hScopeMapping, sTlID);
    
    hScope = i_findScope(hTlArchDoc, sScopePath);
    if ~isempty(hScope)
        ahInterfaceMappings = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping');
        for k = 1:numel(ahInterfaceMappings)
            hIfMapping = ahInterfaceMappings(k);
            
            [sKind, sIfPath] = i_getKindAndPathIfMapping(hIfMapping, sTlID);
            switch sKind
                case 'Input'
                    hIf = i_findInport(hScope, sIfPath);
                    
                case 'Parameter'
                    hIf = i_findParameter(hScope, sIfPath);
                    
                case 'Output'
                    hIf = i_findOutport(hScope, sIfPath);
                    
                case 'Local'
                    hIf = i_findLocal(hScope, sIfPath);
                    
                otherwise
                    MU_FAIL(sprintf('Unexpected intrface kind "%s".', sKind));
                    hIf = [];
            end
            MU_ASSERT_FALSE(isempty(hIf), ...
                sprintf('Interface "%s:%s" not found in scope "%s".', sKind, sIfPath, sScopePath));
        end
    else
        MU_FAIL(sprintf('Could not find Mapping:ScopePath "%s" in TL Architecture XML.', sPath));
    end
end
end


%%
function sPath = i_getMappingPath(hMapping, sArchID)
sPath = getfield(mxx_xmltree('get_attributes', hMapping, sprintf('./Path[@refId="%s"]', sArchID), 'path'), 'path');
end


%%
function hScope = i_findScope(hTlArchDoc, sScopePath)
hScope = mxx_xmltree('get_nodes', hTlArchDoc, ...
    sprintf('/tl:TargetLinkArchitecture/model/subsystem[@path="%s"]', sScopePath));
end


%%
function hIn = i_findInport(hScope, sIfPath)
% note: change the XPath approach for DSMs
hIn = mxx_xmltree('get_nodes', hScope, sprintf('./inport[@name="%s"]', sIfPath));
end


%%
function hParam = i_findParameter(hScope, sIfPath)
hParam = [];

ahParams = mxx_xmltree('get_nodes', hScope, './calibration');
for i = 1:numel(ahParams)
    sPathName = i_getPathNameConcat(ahParams(i));
    if strcmp(sPathName, sIfPath)
        hParam = ahParams(i);
        return;
    end
end
end


%%
function sPathName = i_getPathNameConcat(hParam)
stAttr = mxx_xmltree('get_attributes', hParam, '.', 'name', 'path');
sPathName = [stAttr.path, '/', stAttr.name];
end


%%
function hOut = i_findOutport(hScope, sIfPath)
% note: change the XPath approach for DSMs
hOut = mxx_xmltree('get_nodes', hScope, sprintf('./outport[@name="%s"]', sIfPath));
end


%%
function hLocal = i_findLocal(hScope, sIfPath)
% TODO: finish this
hLocal = [];
MU_FAIL('Check is not implemented yet!');
end


%%
function [sKind, sPath] = i_getKindAndPathIfMapping(hIfMapping, sArchID)
sKind = mxx_xmltree('get_attribute', hIfMapping, 'kind');
sPath = i_getMappingPath(hIfMapping, sArchID);
end


%%
function [hDoc, xOnCleanupCloseDoc] = i_loadXML(sFile)
if ~exist(sFile, 'file')
    MU_FAIL_FATAL('XML file not found.');
end
hDoc = mxx_xmltree('load', sFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));
end


%%
function stArgs = i_evalArgs(varargin)
stDefaults = struct( ...
    'Mapping',  '', ...
    'TlArch',   '', ...
    'SlArch',   '', ...
    'CodeArch', '');
stArgs = i_enhanceWithUserArgs(stDefaults, varargin{:});
end


%%
function stArgs = i_enhanceWithUserArgs(stArgs, varargin)
caxKeyValues = varargin;
if isempty(caxKeyValues)
    return;
end

nLen = numel(caxKeyValues);
if (mod(nLen, 2) ~= 0) 
    error('EP:UT:WRONG_USAGE', 'Inconsistent number of key-value pairs.');
end

for i = 1:2:nLen
    sKey = caxKeyValues{i};
    xVal = caxKeyValues{i + 1};
    
    if isfield(stArgs, sKey)
        stArgs.(sKey) = xVal;
    else
        error('EP:UT:WRONG_USAGE', 'Unsupported key "%s".', sKey);
    end
end
end
