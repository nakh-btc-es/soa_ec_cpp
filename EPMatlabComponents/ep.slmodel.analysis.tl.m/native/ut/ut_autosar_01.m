function ut_autosar_01
% Handling of AUTOSAR models in context of "incremental".
%
% Regression EP25AR-761: Calibration variables missing in the interface of scopes.
%


%%
if ((ep_core_version_compare('TL4.0') ~= 0) || (ep_core_version_compare('TL4.3') ~= 0))
    MU_MESSAGE('TEST SKIPPED: Testdata only exactly for TL4.0 or for TL4.3 (AUTOSAR hook opens DD).');
    return;
end

sVer = 'tl40';
if (ep_core_version_compare('TL4.3') >= 0)
    sVer = 'tl43';
end

%% prepare test
ut_cleanup();

sPwd          = pwd();
sTestRoot     = fullfile(sPwd, 'tmp_ar_01');
sDataDir      = fullfile(ut_local_testdata_dir_get(), 'AUTOSAR', sVer, 'IncrSWC_integ');
sTlModel      = 'swc';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript = fullfile(sTestRoot, 'start_integration.m');


%% arrange
xOnCleanupUnistallUtils = ut_init_autosar('utils_291');
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);
xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = ...
    onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv, xOnCleanupUnistallUtils}));


%% act
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sErrFile = ut_ep_model_analyse(stOpt);

%% assert
% check TL arch
oExpectedIfs = containers.Map;
oExpectedIfs('Two_SWCs/Subsystem/Two_SWCs') = { ...
    'in:sensor_reference', ...
    'in:sensor_position', ...
    'in:actuator_selection', ...
    'cal:Kp', ...
    'cal:Ki', ...
    'out:UpiArray', ...
    'out:UpiSum', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/Ki1', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/Unit Delay', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/sPI1'};
oExpectedIfs('Two_SWCs/Subsystem/Two_SWCs/controller_runnable') = { ...
    'in:reference', ...
    'in:position', ...
    'cal:Kp', ...
    'cal:Ki', ...
    'out:UpiSum', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/Ki1', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/Unit Delay', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/sPI1'};
oExpectedIfs('Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm') = { ...
    'in:reference', ...
    'in:position', ...
    'cal:Kp', ...
    'cal:Ki', ...
    'out:upi', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/Ki1', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/Unit Delay', ...
    'disp:Two_SWCs/Subsystem/Two_SWCs/controller_runnable/algorithm/sPI1'};
oExpectedIfs('Two_SWCs/Subsystem/Two_SWCs/driver_runnable') = { ...
    'in:UpiSum', ...
    'in:actuator_selection', ...
    'out:Upi', ...
    'out:UpiSumDistorted'};

i_checkTlArch(stOpt.sTlResultFile, oExpectedIfs);

% no errors/warnings expected
astMessages = ut_read_error_file(sErrFile);
MU_ASSERT_TRUE(isempty(astMessages), 'No errors/warnings expected here.');
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


