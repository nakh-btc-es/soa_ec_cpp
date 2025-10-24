function ut_ep_code_03
% Check handling of multiple global vars with the same name in different modules.
%
%  REMARKS
%       UT is related to regression EP23AR-7726.
%
%       Note: Having global variables with same name in different modules is possible IFF the definition of these
%             variables does not include an assignment and both have the same type. In this case the definitions
%             are interpreted as if one of them is "extern". This means
%
%             POSSIBLE:  int x; // file1.c 
%                        int x; // in file2.c
%
%             IMPOSSIBLE:  int x=3; // file1.c 
%                          int x; // in file2.c
%
%             IMPOSSIBLE:  int x;  // file1.c 
%                          char x; // in file2.c
%
%       For the model analysis this means: the valid case the variable x needs to be treated as if "global" and 
%       defined in only one of the modules.


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'code_03');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'SameNameVars2');

sTlModel      = 'same_vars';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);

ut_ep_model_analyse(stOpt);


%% check test results
oExpectedInterfaces = containers.Map;
oExpectedInterfaces('top_A') = { ...
    'in:Sa1_x', ...
    'out:Sa1_y1', ...
    'out:Sa1_y2', ...
    'disp:d', ...
    'disp:d:2'};
oExpectedInterfaces('Sa2_sub_B') = { ...
    'in:Sa1_x', ...
    'out:Sa2_Gain2', ...
    'out:Sa2_Gain2:2'};
oExpectedInterfaces('Sdm11_sub_D1') = { ...
    'in:Sdm11_In1', ...
    'out:Sdm11_Out1', ...
    'disp:d'};
oExpectedInterfaces('Sa3_sub_D2') = { ...
    'in:Sa2_Gain2', ...
    'out:d', ...
    'disp:d'};

% check CodeModel
oFoundInterfaces = i_readInterfacesFromCodeModel(stOpt.sCResultFile);
i_checkFoundInterfaces(oExpectedInterfaces, oFoundInterfaces);

% check Mapping
oFoundInterfaces = i_readInterfacesFromMapping(stOpt.sMappingResultFile);
i_checkFoundInterfaces(oExpectedInterfaces, oFoundInterfaces);
end


%%
function i_checkFoundInterfaces(oExpectedInterfaces, oFoundInterfaces)
casExpectedFuncNames = oExpectedInterfaces.keys;
for i = 1:numel(casExpectedFuncNames)
    sFuncName = casExpectedFuncNames{i};
    
    if oFoundInterfaces.isKey(sFuncName)
        casExpectedSymbols = oExpectedInterfaces(sFuncName);
        casFoundSymbols = oFoundInterfaces(sFuncName);
        
        MU_ASSERT_TRUE(numel(casFoundSymbols) == numel(unique(casFoundSymbols)), ...
            sprintf('%s: Found interface symbols are not unique.', sFuncName));
        
        casMissing = setdiff(casExpectedSymbols, casFoundSymbols);
        for k = 1:numel(casMissing)
            MU_FAIL(sprintf('%s: Expected interface symbol %s not found.', sFuncName, casMissing{k}));
        end
        casUnexpected = setdiff(casFoundSymbols, casExpectedSymbols);
        for k = 1:numel(casUnexpected)
            MU_FAIL(sprintf('%s: Unexpected interface symbol %s found.', sFuncName, casUnexpected{k}));
        end
        
        oFoundInterfaces.remove(sFuncName);
    else
        MU_FAIL(['Expected function not found: ', sFuncName]);
    end
end

casUnexpectedFuncNames = oFoundInterfaces.keys;
for i = 1:length(casUnexpectedFuncNames)
    MU_FAIL(['Found unexpected function: ', casUnexpectedFuncNames{i}]);
end
end


%%
function oInterfaceMap = i_readInterfacesFromCodeModel(sCodeModel)
oInterfaceMap = containers.Map;

if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end

hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahFunctions = mxx_xmltree('get_nodes', hDoc, '/CodeModel/Functions/Function');
for i = 1:numel(ahFunctions)
    hFunction = ahFunctions(i);
    
    oInterfaceMap(i_getFunctionName(hFunction)) = i_getFunctionInterfaces(hFunction);
end
end


%%
function sName = i_getFunctionName(hFunction)
sName = mxx_xmltree('get_attribute', hFunction, 'name');
end


%%
function casInterfaces = i_getFunctionInterfaces(hFunction)
astRes = mxx_xmltree('get_attributes', hFunction, './Interface/InterfaceObj', 'kind', 'var', 'alias');
casInterfaces = arrayfun(@i_getInterfaceSymbol, astRes, 'UniformOutput', false);
end


%%
function sSymbol = i_getInterfaceSymbol(stInterfaceObj)
if ~isempty(stInterfaceObj.alias)
    sSymbol = [stInterfaceObj.kind, ':', stInterfaceObj.alias]; 
else
    sSymbol = [stInterfaceObj.kind, ':', stInterfaceObj.var]; 
end
end


%%
function oInterfaceMap = i_readInterfacesFromMapping(sMappingResultFile)
oInterfaceMap = containers.Map;

if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end

hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

sRefIdForCode = 'id1'; % NOTE: may be changed in future!
ahScopeMappings = mxx_xmltree('get_nodes', hDoc, '/Mappings/ArchitectureMapping/ScopeMapping');
for i = 1:numel(ahScopeMappings)
    hScopeMapping = ahScopeMappings(i);
    
    oInterfaceMap(i_getFunctionNameFromScopeMapping(hScopeMapping, sRefIdForCode)) = ...
        i_getFunctionInterfacesFromScopeMapping(hScopeMapping, sRefIdForCode);
end
end


%%
function sName = i_getFunctionNameFromScopeMapping(hScopeMapping, sRefId)
stRes = mxx_xmltree('get_attributes', hScopeMapping, sprintf('./Path[@refId="%s"]', sRefId), 'path');
sName = regexprep(stRes.path, '.+:', '');
end


%%
function casSymbols = i_getFunctionInterfacesFromScopeMapping(hScopeMapping, sRefId)
ahIntfMappings = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping');
casSymbols = arrayfun(@(h) i_getSymbolFromIntfMapping(h, sRefId), ahIntfMappings, 'UniformOutput', false);
end


%%
function sSymbol = i_getSymbolFromIntfMapping(hIntfMapping, sRefId)
stRes = mxx_xmltree('get_attributes', hIntfMapping, sprintf('./Path[@refId="%s"]', sRefId), 'path');
sName = stRes.path;

sAttKind = mxx_xmltree('get_attribute', hIntfMapping, 'kind');
switch lower(sAttKind)
    case 'output'
        sSymbol = ['out:', sName];
        
    case 'input'
        sSymbol = ['in:', sName];
        
    case 'param'
        sSymbol = ['cal:', sName];
        
    case 'local'
        sSymbol = ['disp:', sName];
        
    otherwise
        error('UT:ERROR', 'Unexpected kind %s.', sAttKind);
end
end

