function ut_ep_code_01
% Check handling of multiple static vars with the same name in different modules.
%
%  REMARKS
%       UT is related to PROM-12288.
%
%       Checking also fix for PROM-13400: File references should only be added for _static_ variables and functions.
%       Otherwise the info about the module name might be wrong, e.g. for EXTERNAL variables.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'code_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'SameNameVars');

sTlModel      = 'same_name_vars';
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

% Note: only the static function "step_c" is expected to have a reference
sStaticFunc = 'step_c';
sXPathFunc = '/CodeModel/Functions/Function';
astFuncs = mxx_xmltree('get_attributes', hDoc, sXPathFunc, 'name', 'fileref');
if ~isempty(astFuncs)
    for i = 1:length(astFuncs)
        stFunc = astFuncs(i);
        if strcmpi(stFunc.name, sStaticFunc)
            MU_ASSERT_FALSE(isempty(stFunc.fileref), ...
                sprintf('Unexpected: Static function "%s" has no file reference.', stFunc.name));
        else
            MU_ASSERT_TRUE(isempty(stFunc.fileref), ...
                sprintf('Unexpected: Non-static function "%s" has a file reference.', stFunc.name));
        end
    end
else
    MU_FAIL('Unexpected: no Functions found in CodeModel.');
end

% PROM-13400 --> check that non-static vars have _no_ fileref
casNonstaticVars = { ...
    'cal_x', ...
    'disp_x', ...
    'cal_y', ...
    'disp_y'};

% Note: all CALs and DISPs in model are static --> expect all of them to have a file reference
sXPathIf = '/CodeModel/Functions/Function/Interface/InterfaceObj';
astCals = mxx_xmltree('get_attributes', hDoc, [sXPathIf, '[@kind="cal"]'], 'var', 'fileref');
if ~isempty(astCals)
    for i = 1:length(astCals)
        stCal = astCals(i);
        if any(strcmp(stCal.var, casNonstaticVars))
            MU_ASSERT_TRUE(isempty(stCal.fileref), ...
                sprintf('Non-static CAL variable "%s" shall have no file reference.', stCal.var));
        else
            MU_ASSERT_FALSE(isempty(stCal.fileref), ...
                sprintf('Static CAL variable "%s" shall have a file reference.', stCal.var));
        end
    end
else
    MU_FAIL('Unexpected: no CALs found in CodeModel.');
end

astDisps = mxx_xmltree('get_attributes', hDoc, [sXPathIf, '[@kind="disp"]'], 'var', 'fileref');
if ~isempty(astDisps)
    for i = 1:length(astDisps)
        stDisp = astDisps(i);
        if any(strcmp(stDisp.var, casNonstaticVars))
            MU_ASSERT_TRUE(isempty(stDisp.fileref), ...
                sprintf('Non-static DISP variable "%s" shall have no file reference.', stDisp.var));
        else
            MU_ASSERT_FALSE(isempty(stDisp.fileref), ...
                sprintf('Static Disp variable "%s" shall have a file reference.', stDisp.var));
        end
    end
else
    MU_FAIL('Unexpected: no DISPs found in CodeModel.');
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

casModelPaths = { ...
    'top_A/Subsystem/top_A/sub_B1/Gain1/b1_group/calvar', ...
    'top_A/Subsystem/top_A/sub_B1/Gain1(1)', ...
    'top_A/Subsystem/top_A/sub_B1/sub_C/Unit Delay(1)', ...
    'top_A/Subsystem/top_A/sub_B2/Gain1/b2_group/calvar', ...
    'top_A/Subsystem/top_A/sub_B2/Gain1(1)', ...
    'top_A/Subsystem/top_A/sub_B2/sub_C/Unit Delay(1)'};

casCodePaths = { ...
    'calvar', ...
    'dispvar', ...
    'Sb1_c1_Unit_Delay', ...
    'calvar', ...
    'dispvar', ...
    'Sb1_c1_Unit_Delay'};

casModules = { ...
    'b1_code.c', ...
    'b1_code.c', ...
    'b1_code.c', ...
    'b2_code.c', ...
    'b2_code.c', ...
    'b2_code.c'};

astExpected = struct( ...
    'sModelPath', casModelPaths, ...
    'sCodePath',  casCodePaths, ...
    'sModule',    casModules);
i_check_interface_mappings(hDoc, astExpected);
end


%%
function i_check_interface_mappings(hDoc, astExpected)
sXPathFormat = '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[Path[@refId="id0" and @path="%s"]]';
for i = 1:length(astExpected)
    stExp = astExpected(i);
    
    sXPath = sprintf(sXPathFormat, stExp.sModelPath);
    ahIfs = mxx_xmltree('get_nodes', hDoc, sXPath);
    if ~isempty(ahIfs)
        for k = 1:length(ahIfs)
            hIf = ahIfs(k);
            stPath = mxx_xmltree('get_attributes', hIf, './Path[@refId="id1"]', 'path');
            if ~isempty(stPath)
                MU_ASSERT_TRUE(strcmp(stPath.path, stExp.sCodePath), ...
                    sprintf('Expected code path "%s" instead of "%s".', stExp.sCodePath, stPath.path));
            else
                MU_FAIL(sprintf('Expected code path not found for model interface "%s".', stExp.sModelPath));
            end
            
            stModule = mxx_xmltree('get_attributes', hIf, './Path[@refId="id1"]/Property[@name="module"]', 'value');
            if ~isempty(stModule)
                MU_ASSERT_TRUE(strcmp(stModule.value, stExp.sModule), ...
                    sprintf('Expected module "%s" instead of "%s".', stExp.sModule, stModule.value));
            else
                MU_FAIL(sprintf('Expected property "module" not found for model interface "%s".', stExp.sModelPath));
            end
            
        end
    else
        MU_FAIL(sprintf('Interface object with model path "%s" not found.', stExp.sModelPath));
    end
end
end
