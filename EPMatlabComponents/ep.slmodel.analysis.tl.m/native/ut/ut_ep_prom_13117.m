function ut_ep_prom_13117
% Check fix for Bug PROM-13117.
%
%  REMARKS
%       Bug: Code info contains interface pointing to the provided function argument (function-external view) instead
%       of the corresponding function parameter (function-internal view).
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'prom_13117');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'simple_interface');

sTlModel      = 'simple_interface';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);

ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_code_model(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C-Code', oEx)); 
end

try 
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%% CodeModel
function i_check_code_model(sCodeModel)
if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

casExpectedInterfaces = { ...
    'in:DD_Sa1_In1', ...
    'in:new_Variable->Comp_1', ...
    'in:new_Variable_2.Expli_comp2', ...
    'in:Sa1_in2', ...
    'in:new_Variable->Comp_2', ...
    'in:Input_Variable_str2.new_Component.sub_Com2', ...
    'in:Input_Variable_str2.new_Component_3', ...
    'out:Output_variable.Expli_comp3', ...
    'out:Output_variable.Expli_comp1', ...
    'out:new_Variable_2.Expli_comp2', ...
    'out:', ...
    'out:Output_Variable_str2->new_Component.sub_Com2', ...
    'out:DD_Sa1_Out2', ...
    'disp:Sa1_Relational_Operator1', ...
    'disp:Sa1_Relational_Operator5', ...
    'disp:Sa1_Relational_Operator3', ...
    'disp:Sa1_Relational_Operator4'};

oFoundIfMap = i_getAllInterfaceObjects(hDoc);
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
function oFoundIfMap = i_getAllInterfaceObjects(hDoc)
oFoundIfMap = containers.Map;
astRes = mxx_xmltree('get_attributes', hDoc, ...
    '/CodeModel/Functions/Function/Interface/InterfaceObj', 'kind', 'var', 'access');
for i = 1:length(astRes)
    sKey = [astRes(i).kind, ':', astRes(i).var, astRes(i).access];
    oFoundIfMap(sKey) = true;
end
end


%% Mapping
function i_check_mapping(sMappingResultFile)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

casExpectedInOutMappings = { ...
    'Input:In1 <--> DD_Sa1_In1', ...
    'Input:in.2 <--> new_Variable->Comp_1', ...
    'Input:in1 <--> new_Variable_2.Expli_comp2', ...
    'Input:in2 <--> Sa1_in2', ...
    'Input:in.1 <--> new_Variable->Comp_2', ...
    'Input:in3 <--> Input_Variable_str2.new_Component.sub_Com2', ...
    'Input:in4 <--> Input_Variable_str2.new_Component_3', ...
    'Output:out. <--> Output_variable.Expli_comp3', ...
    'Output:Out4 <--> Output_variable.Expli_comp1', ...
    'Output:Out3 <--> new_Variable_2.Expli_comp2', ...
    'Output:out.2 <--> Subsystem1:return', ...
    'Output:Out1 <--> Output_Variable_str2->new_Component.sub_Com2', ...
    'Output:Out2 <--> DD_Sa1_Out2'};

oFoundInOutMappingsMap = i_getAllInOutMappings(hDoc);
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
function oFoundInOut = i_getAllInOutMappings(hDoc)
oFoundInOut = containers.Map;

sXPath = ...
    ['/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping', ...
    '[@kind="Input" or @kind="Output"]'];
ahIfMaps = mxx_xmltree('get_nodes', hDoc, sXPath);
for i = 1:length(ahIfMaps)
    hIfMap = ahIfMaps(i);
    
    sKind = mxx_xmltree('get_attribute', hIfMap, 'kind');
    stMIL = mxx_xmltree('get_attributes', hIfMap, './Path[@refId="id0"]', 'path');
    stSIL = mxx_xmltree('get_attributes', hIfMap, './Path[@refId="id1"]', 'path');
    
    sKey = [sKind, ':', stMIL.path, ' <--> ', stSIL.path];
    oFoundInOut(sKey) = true;
end
end


