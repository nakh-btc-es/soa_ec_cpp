function ut_tl_reusable_incremental_01
% Checking that the TL feature-combination "reusable" and "incremental" are correctly handled by analysis.
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

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'reuse_incr_01');
if (ep_core_version_compare('TL4.3') < 0)
    sDataDir = fullfile(ut_local_testdata_dir_get(), 'reusable', 'incremental');
else
    sDataDir = fullfile(ut_local_testdata_dir_get(), 'reusable', 'incremental_tl43');
end

sTlModel      = 'reusable';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);

%% assert
oExpectedDisps = containers.Map;

oExpectedDisps('top_A/Subsystem/top_A') = { ...
    'top_A/Subsystem/top_A/sub_D/Subsystem/Log Op', ...
    'top_A/Subsystem/top_A/sub_D/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Subsystem/Log Op', ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Subsystem/Log Op', ...
    'top_A/Subsystem/top_A/sub_B/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_B/Subsystem/Log Op', ...
    'top_A/Subsystem/top_A/sub_C/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_C/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_B') = { ...
    'top_A/Subsystem/top_A/sub_B/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_B/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_B/Subsystem') = { ...
    'top_A/Subsystem/top_A/sub_B/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_C') = { ...
    'top_A/Subsystem/top_A/sub_C/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_C/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_C/Subsystem') = { ...
    'top_A/Subsystem/top_A/sub_C/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_D') = { ...
    'top_A/Subsystem/top_A/sub_D/Subsystem/Log Op', ...
    'top_A/Subsystem/top_A/sub_D/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Subsystem/Log Op', ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_D/Subsystem') = { ...
    'top_A/Subsystem/top_A/sub_D/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_D/sub_X') = { ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_D/sub_X/Subsystem') = { ...
    'top_A/Subsystem/top_A/sub_D/sub_X/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_D/sub_Y') = { ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Unit Delay', ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Subsystem/Log Op'};

oExpectedDisps('top_A/Subsystem/top_A/sub_D/sub_Y/Subsystem') = { ...
    'top_A/Subsystem/top_A/sub_D/sub_Y/Subsystem/Log Op'};

% oExpectedDisps('top_A/Subsystem/top_A/sub_E') = {};
% oExpectedDisps('top_A/Subsystem/top_A/sub_E/someSub') = {};
% oExpectedDisps('top_A/Subsystem/top_A/sub_E/someSub/Subsystem') = {};
oExpectedDisps('top_A/Subsystem/top_A/sub_F') = {};
oExpectedDisps('top_A/Subsystem/top_A/sub_F/someSub') = {};
oExpectedDisps('top_A/Subsystem/top_A/sub_F/someSub/Subsystem') = {};

i_checkTlArch(stOpt.sTlResultFile, oExpectedDisps);
end


%%
function i_checkTlArch(sTlArchFile, oExpectedDisps)
oFoundDisps = i_readDisps(sTlArchFile);

i_compareResults('DISP variables', oExpectedDisps, oFoundDisps);
end


%%
function oDisps = i_readDisps(sTlArchFile)
oDisps = containers.Map;

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
    oDisps(sPath) = i_readDispsOfSub(hSub);
end
end


%%
function casDisps = i_readDispsOfSub(hSub)
astRes = mxx_xmltree('get_attributes', hSub, './display', 'path');
if isempty(astRes)
    casDisps = {};
else
    casDisps = {astRes(:).path};
end
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
        
        SLTU_ASSERT_STRINGSETS_EQUAL(xExpObj, xFoundObj, ...
            i_failMessage([sContext, ' --- ' sKey], xExpObj, xFoundObj));
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


