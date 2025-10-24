function SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArchFile, sTestTlArchFile)
% Asserts that the TL architecture XML file is equal to the expected XML file.
%

%%
if SLTU_update_testdata_mode()
    MU_MESSAGE('Updating expectation values in TL Arch XML. No equality checking performed!');
    sltu_copyfile(sTestTlArchFile, sExpectedTlArchFile);
    return;
end


%%
% Note: currently just a trvial compare that all subsystems are mentioned
% TODO: --> extend functionality (preferably on Java level)

[hExpRoot,  oOnCleanupCloseExpDoc]  = i_openXml(sExpectedTlArchFile); %#ok<ASGLU> onCleanup object
[hTestRoot, oOnCleanupCloseTestDoc] = i_openXml(sTestTlArchFile);     %#ok<ASGLU> onCleanup object

casExpectedAndFoundSubPaths = sltu_compare_subsystems(hExpRoot, hTestRoot);
sltu_compare_interfaces_for_subs(hExpRoot, hTestRoot, casExpectedAndFoundSubPaths);
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
% note: sub-function *must* start with sltu_* for correct messaging in MUnit report
function casExpectedAndFoundSubPaths = sltu_compare_subsystems(hExpRoot, hTestRoot)
oExpSubsMap  = i_getSubsystems(hExpRoot);
oTestSubsMap = i_getSubsystems(hTestRoot);

casExpectedAndFound = sltu_compare_objects(oExpSubsMap, oTestSubsMap, 'subsystem');
casExpectedAndFoundSubPaths = cell(size(casExpectedAndFound));
for i = 1:numel(casExpectedAndFound)
    casExpectedAndFoundSubPaths{i} = oExpSubsMap(casExpectedAndFound{i}).path;
end
end


%%
% note: sub-function *must* start with sltu_* for correct messaging in MUnit report
function casExpectedAndFound = sltu_compare_objects(oExpMap, oTestMap, sObjKind)
casExpectedAndFound = {};
casExpected = oExpMap.keys;
for i = 1:numel(casExpected)
    sExpected = casExpected{i};
    
    if oTestMap.isKey(sExpected)
        stExp = oExpMap(sExpected);
        stFound = oTestMap(sExpected);
        
        bSameProps = isequal(stExp, stFound);
        if bSameProps
            casExpectedAndFound{end + 1} = sExpected; %#ok<AGROW>
            MU_PASS(); % just for statistics reported in MUNIT report
        else
            SLTU_FAIL('Found unexpected properties in %s "%s".', sObjKind, sExpected);
        end
    else
        SLTU_FAIL('Expected %s "%s" not found.', sObjKind, sExpected);
    end
end

casFound = oTestMap.keys;
casUnexpected = setdiff(casFound, casExpected);
for i = 1:numel(casUnexpected)
    SLTU_FAIL('Found unexpected %s "%s".', sObjKind, casUnexpected{i});
end
end


%%
function oSubsMap = i_getSubsystems(hRoot)
oSubsMap = containers.Map;
ahSubs = mxx_xmltree('get_nodes', hRoot, '/tl:TargetLinkArchitecture/model/subsystem');
astSubs = arrayfun(@(hSub) i_readSubsystem(hSub), ahSubs);
for i = 1:numel(astSubs)
    oSubsMap(astSubs(i).physicalPath) = astSubs(i);
end
end


%%
function stSub = i_readSubsystem(hSub)
stSub = mxx_xmltree('get_attributes', hSub, '.', ...
    'physicalPath', ...
    'path', ...
    'sampleTime');
end


%%
% note: sub-function *must* start with sltu_* for correct messaging in MUnit report
function sltu_compare_interfaces_for_subs(hExpRoot, hTestRoot, casSubPaths)
for i = 1:numel(casSubPaths)
    sSubPath = casSubPaths{i};
    
    hExpSub = i_getSubNode(hExpRoot, sSubPath);
    hTestSub = i_getSubNode(hTestRoot, sSubPath);
    if (~isempty(hExpSub) && ~isempty(hTestSub))
        stExpIf  = i_getInterfaces(hExpSub);
        stTestIf = i_getInterfaces(hTestSub);
        casIfKinds = fieldnames(stExpIf);
        for k = 1:numel(casIfKinds)
            sIfKind = casIfKinds{k};
            
            sltu_compare_objects(stExpIf.(sIfKind), stTestIf.(sIfKind), sIfKind);
        end
    else
        SLTU_FAIL('Could not find subsystem with path "%s".', sSubPath);
    end
end
end


%%
% sKind == 'inport' | 'outport' | 'parameter' | 'display'
function stInterfaces = i_getInterfaces(hSub)
stInterfaces = struct( ...
    'inport',    i_getInterfacesOfKind(hSub, 'inport',    @i_readPort,  'physicalPath'), ...
    'output',    i_getInterfacesOfKind(hSub, 'outport',   @i_readPort,  'physicalPath'), ...
    'parameter', i_getInterfacesOfKind(hSub, 'parameter', @i_readParam, 'name'), ...
    'local',     i_getInterfacesOfKind(hSub, 'display',   @i_readLocal, 'physicalPath'));    
end


%%
% sKind == 'inport' | 'outport' | 'parameter' | 'display'
function oInterfacesMap = i_getInterfacesOfKind(hSub, sKind, hReadFunc, sPropNameForKey)
oInterfacesMap = containers.Map;
ahInterface = mxx_xmltree('get_nodes', hSub, ['./', lower(sKind)]);
astInterfaces = arrayfun(hReadFunc, ahInterface);
for i = 1:numel(astInterfaces)
    oInterfacesMap(astInterfaces(i).(sPropNameForKey)) = astInterfaces(i);
end
end


%%
function stProps = i_readPort(hPort)
stProps = mxx_xmltree('get_attributes', hPort, '.', ...
    'physicalPath', ...
    'path', ...
    'name', ...
    'portNumber', ...
    'signalName');
end


%%
function stProps = i_readLocal(hLocal)
stProps = mxx_xmltree('get_attributes', hLocal, '.', ...
    'physicalPath', ...
    'path', ...
    'name', ...
    'portNumber', ...
    'signalName');
end


%%
function stProps = i_readParam(hParam)
stProps = mxx_xmltree('get_attributes', hParam, '.', ...
    'physicalPath', ...
    'path', ...
    'name', ...
    'initValue');
end


%%
function hSub = i_getSubNode(hRoot, sSubPath)
hSub = mxx_xmltree('get_nodes', hRoot, sprintf('/tl:TargetLinkArchitecture/model/subsystem[@path="%s"]', sSubPath));
end
