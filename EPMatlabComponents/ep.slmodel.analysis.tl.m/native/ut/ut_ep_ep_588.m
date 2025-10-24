function ut_ep_ep_588
% Check fix for Bug EP_588
%
%  REMARKS
%       Bug: Mapping and CCode Arch contain references to nonexistent variables.
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_968');

bIsHighTL = false;
if (ep_core_version_compare('TL4.2') < 0)
    sTlDir = 'TL34';
else
    sTlDir = 'TL42';
    if (ep_core_version_compare('TL4.4') >= 0)
        bIsHighTL = true;
    end
end
sDataDir = fullfile(ut_local_testdata_dir_get(), 'em_968', sTlDir);

sTlModel      = 'te_Calcn';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, 'Simulink_models.dd');
sTlInitScript = fullfile(sTestRoot, 'TypesStruct.m');


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
try 
    i_checkCodeModel(stOpt.sCResultFile, bIsHighTL);
catch oEx
    MU_FAIL(i_printException('C-Code', oEx)); 
end

try
    i_checkMapping(stOpt.sMappingResultFile, bIsHighTL);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx));
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_checkCodeModel(sCodeModel, bIsHighTL)
if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

casExpectedInterfaces = { ...
    'in:IF_Sa1_lTireRd', ...
    'in:IF_Sa1_lTireRd_a', ...
    'in:IF_Sa1_trqAA', ...
    'in:IF_Sa1_trqAA_a', ...
    'in:IF_Sa1_vA', ...
    'in:IF_Sa1_vA_a', ...
    'in:IF_Sa1_stAD', ...
    'out:SCaln1_Out_a.Float', ...
    'out:SCaln1_Out_a.Qly'};
if bIsHighTL
    % TL4.4 is creating a different access variable for the output
    casExpectedInterfaces{end - 1} = 'out:Sa1_Out->Float';
    casExpectedInterfaces{end} = 'out:Sa1_Out->Qly';
    
    % TL5.0 is creatingdifferent access variables for some inputs
    if (ep_core_version_compare('TL5.0') >= 0)
        casExpectedInterfaces{1} = 'in:IF_Sa1_lTR';
        casExpectedInterfaces{2} = 'in:IF_Sa1_lTR_a';
    end
end

oFoundIfMap = i_getAllInterfaceObjectsForFunction(hDoc, 'sim_Calcn');
for i = 1:length(casExpectedInterfaces)
    sExpIf = casExpectedInterfaces{i};
    
    if oFoundIfMap.isKey(sExpIf)        
        oFoundIfMap.remove(sExpIf);
    else
        MU_FAIL(sprintf('Expected interface "%s" was not found.', sExpIf));
    end
end
casUnexpected = oFoundIfMap.keys;
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('Found unexpected interface "%s".', casUnexpected{i}));
end
end


%%
function i_checkMapping(sMappingResultFile, bIsHighTL)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

casExpectedInOutMappings = { ...
    'Input:lTR.lTireRd.FloatAry8 <--> IF_Sa1_lTireRd', ...
    'Input:lTR.lTireRd.QlyAry8 <--> IF_Sa1_lTireRd_a', ...
    'Input:trqAA.trqAA.FloatAryAxles <--> IF_Sa1_trqAA', ...
    'Input:trqAA.trqAA.QlyAryAxles <--> IF_Sa1_trqAA_a', ...
    'Input:vA.vA.FloatAry8 <--> IF_Sa1_vA', ...
    'Input:vA.vA.QlyAry8 <--> IF_Sa1_vA_a', ...
    'Input:stAD <--> IF_Sa1_stAD', ...
    'Output:Out.Out.Float <--> SCaln1_Out_a.Float', ...
    'Output:Out.Out.Qly <--> SCaln1_Out_a.Qly'};
if bIsHighTL
    % TL4.4 is creating a different access variable for the output
    casExpectedInOutMappings{end - 1} = 'Output:Out.Out.Float <--> Sa1_Out->Float';
    casExpectedInOutMappings{end} = 'Output:Out.Out.Qly <--> Sa1_Out->Qly';
    
    % TL5.0 is creatingdifferent access variables for some inputs
    if (ep_core_version_compare('TL5.0') >= 0)
        casExpectedInOutMappings{1} = 'Input:lTR.lTireRd.FloatAry8 <--> IF_Sa1_lTR';
        casExpectedInOutMappings{2} = 'Input:lTR.lTireRd.QlyAry8 <--> IF_Sa1_lTR_a';
    end
end

sScopePath = 'sim_Calcn/Subsystem/sim_Calcn';
oFoundInOutMappingsMap = i_getAllInOutMappingsForScope(hDoc, sScopePath);
for i = 1:length(casExpectedInOutMappings)
    sExpMapping = casExpectedInOutMappings{i};
    
    if oFoundInOutMappingsMap.isKey(sExpMapping)        
        oFoundInOutMappingsMap.remove(sExpMapping);
    else
        MU_FAIL(sprintf('Expected mapping "%s" was not found.', sExpMapping));
    end
end
casUnexpected = oFoundInOutMappingsMap.keys;
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('Found unexpected mapping "%s".', casUnexpected{i}));
end
end


%%
function oFoundIfMap = i_getAllInterfaceObjectsForFunction(hDoc, sStepFunc)
oFoundIfMap = containers.Map;
astRes = mxx_xmltree('get_attributes', hDoc, ...
    sprintf('/CodeModel/Functions/Function[@name="%s"]/Interface/InterfaceObj', sStepFunc), ...
    'kind', 'var', 'access');
for i = 1:length(astRes)
    sKey = [astRes(i).kind, ':', astRes(i).var, astRes(i).access];
    oFoundIfMap(sKey) = true;
end
end


%%
function oFoundInOut = i_getAllInOutMappingsForScope(hDoc, sScopePath)
oFoundInOut = containers.Map;

sXPath = sprintf( ...
    ['/Mappings/ArchitectureMapping/ScopeMapping[Path[@path="%s"]]/', ...
    'InterfaceObjectMapping[@kind="Input" or @kind="Output"]'], sScopePath);
ahIfMaps = mxx_xmltree('get_nodes', hDoc, sXPath);
for i = 1:length(ahIfMaps)
    hIfMap = ahIfMaps(i);
    
    sKind = mxx_xmltree('get_attribute', hIfMap, 'kind');
    casMilPaths = i_getFullInterfaceObjPaths(hIfMap, 'id0');
    casSilPaths = i_getFullInterfaceObjPaths(hIfMap, 'id1');

    for k = 1:length(casMilPaths)
        sKey = [sKind, ':', casMilPaths{k}, ' <--> ', casSilPaths{k}];
        oFoundInOut(sKey) = true;
    end
end
end


%%
function casFullPaths = i_getFullInterfaceObjPaths(hIfMap, sID)
stRoot = mxx_xmltree('get_attributes', hIfMap, sprintf('./Path[@refId="%s"]', sID), 'path');
astLeafs = mxx_xmltree('get_attributes', hIfMap, sprintf('./SignalMapping/Path[@refId="%s"]', sID), 'path');

if isempty(astLeafs)
    casFullPaths = {stRoot.path};
else
    casFullPaths = arrayfun(@(stLeaf) [stRoot.path, stLeaf.path], astLeafs, 'UniformOutput', false);
end
end

