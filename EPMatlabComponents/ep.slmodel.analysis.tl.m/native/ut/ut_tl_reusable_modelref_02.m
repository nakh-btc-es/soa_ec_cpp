function ut_tl_reusable_modelref_02
% Checking that the TL feature-combination "reusable" and "incremental" (ModelRef) are correctly handled by analysis.
%
% EPDEV-42053 As a TL user, I want extended support for subsystems represented as reusable functions in C-code
%


%% testdata only for TL4.1 and higher
if ep_core_version_compare('TL4.1') < 0
    MU_MESSAGE('TEST SKIPPED: Testdata with "reusable" and "incremental" subsystems only for TL4.1 and higher.');
    return;
end

%% prepare test
ut_cleanup();

sPwd          = pwd();
sTestRoot     = fullfile(sPwd, 'reuse_modelref_02');
sDataDir      = fullfile(ut_local_testdata_dir_get(), 'tl41_mod_function_reuse');
sTlModel      = 'function_reuse';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript = fullfile(sTestRoot, 'start.m');


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sErrFile = ut_ep_model_analyse(stOpt);

%% assert
% check TL arch
oExpectedIfs = containers.Map;
oExpectedIfs('pidcontroller/Subsystem/pidcontroller') = { ...
    'in:SwitchInstance', ...
    'in:REF', ...
    'in:U_X1', ...
    'in:U_X2', ...
    'in:U_X3', ...
    'out:U_M'};
oExpectedIfs('pidcontroller/Subsystem/pidcontroller/PID_Controller_Inst3') = { ...
    'in:REF', ...
    'in:U_X', ...
    'out:U_M'};

i_checkTlArch(stOpt.sTlResultFile, oExpectedIfs);

% check limitation messages
i_checkErrFile(sErrFile, 'ATGCV:MOD_ANA:LIMITATION_REUSE_MAPPING_INCOMPLETE', 2);
end


%%
function i_checkErrFile(sErrFile, sMessageID, nExpectedMsg)
astMessages = ut_read_error_file(sErrFile);
nFoundMsg = 0;
for i = 1:numel(astMessages)
    if strcmp(astMessages(i).id, sMessageID)
        nFoundMsg = nFoundMsg + 1;
    end
end

MU_ASSERT_TRUE(nExpectedMsg == nFoundMsg, ...
    sprintf('Expected %d messages "%s" instead of %d.', nExpectedMsg, sMessageID, nFoundMsg));
end


%%
function i_checkTlArch(sTlArchFile, oExpectedIfs)
oFoundIfs = i_readInterfaces(sTlArchFile);

i_compareResults('Interfaces', oExpectedIfs, oFoundIfs);
end


%%
function oIfs = i_readInterfaces(sTlArchFile)
oIfs = containers.Map;

if ~exist(sTlArchFile, 'file')
    MU_FAIL('TL architecture XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sTlArchFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahSubs = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem');
for i = 1:numel(ahSubs)
    hSub = ahSubs(i);
    
    sPath = mxx_xmltree('get_attribute', hSub, 'path');
    oIfs(sPath) = i_readIfsOfSub(hSub);
end
end


%%
function casIfs = i_readIfsOfSub(hSub)
astRes = mxx_xmltree('get_attributes', hSub, './inport', 'name');
casInports = reshape(arrayfun(@(stRes) ['in:', stRes.name], astRes, 'UniformOutput', false), 1, []);

astRes = mxx_xmltree('get_attributes', hSub, './calibration', 'name');
casCals = reshape(arrayfun(@(stRes) ['cal:', stRes.name], astRes, 'UniformOutput', false), 1, []);

astRes = mxx_xmltree('get_attributes', hSub, './outport', 'name');
casOutports = reshape(arrayfun(@(stRes) ['out:', stRes.name], astRes, 'UniformOutput', false), 1, []);

astRes = mxx_xmltree('get_attributes', hSub, './display', 'path');
casDisps = reshape(arrayfun(@(stRes) ['disp:', stRes.path], astRes, 'UniformOutput', false), 1, []);

casIfs = [casInports, casCals, casOutports, casDisps];
end


%%
function i_compareResults(sContext, oExpMap, oFoundMap)
casExpKeys = oExpMap.keys;
casFoundKeys = oFoundMap.keys;
i_assertSetsEqual(sContext, casExpKeys, casFoundKeys);

for i = 1:length(casExpKeys)
    sKey = casExpKeys{i};
    
    if oFoundMap.isKey(sKey)
        xExpObj = oExpMap(sKey);
        xFoundObj = oFoundMap(sKey);
        
        MU_ASSERT_TRUE(isequal(xExpObj, xFoundObj), i_failMessage([sContext, ' --- ' sKey], xExpObj, xFoundObj));
    end
end
end


%%
function sMsg = i_failMessage(sContext, xExpObj, xFoundObj) %#ok<INUSD> used implicitly in eval()
sExpObj = evalc('disp(xExpObj)');
sFoundObj = evalc('disp(xFoundObj)');
sMsg = sprintf('%s -----\n... Expected ...\n"%s"\n... Found ...\n"%s".', sContext, sExpObj, sFoundObj);
end


%%
function i_assertSetsEqual(sContext, casExpSet, casFoundSet)
casMissing = setdiff(casExpSet, casFoundSet);
casUnexpected = setdiff(casFoundSet, casExpSet);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('%s:\nExpected object "%s" not found.', sContext, casMissing{i}));
end
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('%s:\nUnexpected object "%s" found.', sContext, casUnexpected{i}));
end
end


