function ut_struct_locals
% Test the handling of struct DISP variables mapped to bus signals.
%

%%
if ep_core_version_compare('TL4.1') < 0
    MU_MESSAGE('TEST SKIPPED: Testdata with "struct DISP" for SF-Charts only for TL4.1 and higher.');
    return;
end


%% cleanup
sltu_cleanup();


%% arrange
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_local_testdata_dir_get(), 'StructDisp');

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('StructDisp', 'TL', sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sTlModel',  sModel, ...
    'xEnv',      xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
sExpectedTlArch = fullfile(sTestDataDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
i_checkLocalsInTlArch(sExpectedTlArch, stOpt.sTlResultFile);
%SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
i_checkLocalsInCodeModel(sExpectedCodeModel, stOpt.sCResultFile);
end



%%
function i_checkLocalsInCodeModel(sExpectedCodeModel, sFoundCodeModel)
if ~exist(sFoundCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
casExpLocals = i_readLocalsOfToplevelInCodeModel(sExpectedCodeModel);
casFoundLocals = i_readLocalsOfToplevelInCodeModel(sFoundCodeModel);
SLTU_ASSERT_STRINGSETS_EQUAL(casExpLocals, casFoundLocals);
end


%%
function casLocals = i_readLocalsOfToplevelInCodeModel(sCodeModel)
casLocals = {};

[hDoc, xOnCleanupClose] = i_openXml(sCodeModel); %#ok<NASGU> onCleanup object
if isempty(hDoc)
    return;
end

% ASSUMPTION: first function is the *toplevel* function
astFuncs = mxx_xmltree('get_attributes', hDoc, ...
    '/CodeModel/Functions/Function[1]/Interface/InterfaceObj[@kind="disp"]', ...
    'var', 'access');
casLocals = arrayfun(@(stF) [stF.var, stF.access], reshape(astFuncs, 1, []), 'UniformOutput', false);
end


%%
function i_checkLocalsInTlArch(sExpectedTlArch, sFoundTlArch)
if ~exist(sFoundTlArch, 'file')
    MU_FAIL('TL Arch XML is missing.');
    return;
end
casExpLocals = i_readLocalsOfToplevel(sExpectedTlArch);
casFoundLocals = i_readLocalsOfToplevel(sFoundTlArch);
SLTU_ASSERT_STRINGSETS_EQUAL(casExpLocals, casFoundLocals);
end


%%
function casLocals = i_readLocalsOfToplevel(sTlArch)
casLocals = {};

[hDoc, xOnCleanupClose] = i_openXml(sTlArch); %#ok<NASGU> onCleanup object
if isempty(hDoc)
    return;
end

% ASSUMPTION: first subsystem is the *toplevel* subsystem
ahDisplays = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem[1]/display');
ccasLocals = arrayfun(@i_readLeafLocals, reshape(ahDisplays, 1, []), 'UniformOutput', false);
casLocals = [ccasLocals{:}];
end


%%
function casLocals = i_readLeafLocals(hDisplayNode)
sRootPath = i_getRootPath(hDisplayNode);

astSigs = mxx_xmltree('get_attributes', hDisplayNode, './miltype/bus/signal', 'signalName');
if ~isempty(astSigs)
    casLocals = arrayfun(@(stSig) [sRootPath, ':', stSig.signalName], reshape(astSigs, 1, []), 'UniformOutput', false);
else
    casLocals = {sRootPath};
end
end


%%
function sRootPath = i_getRootPath(hDisplayNode)
stDisp = mxx_xmltree('get_attributes', hDisplayNode, '.', 'path', 'stateflowVariable', 'portNumber');
if ~isempty(stDisp.stateflowVariable)
    sRootPath = [stDisp.path, ':', stDisp.stateflowVariable];
else
    sRootPath = [stDisp.path, ':', stDisp.portNumber];
end
end


%%
function [hDoc, xOnCleanupClose] = i_openXml(sXmlFile)
hDoc = [];
xOnCleanupClose = [];

if ~exist(sXmlFile, 'file')
    warning('UT:WARNING:XML_FILE_NOT_FOUND', 'XML file "%s" is missing.', sXmlFile);
    return;
end

hDoc = mxx_xmltree('load', sXmlFile);
xOnCleanupClose = onCleanup(@() mxx_xmltree('clear', hDoc));
end
