function ut_mlcode_parameters_01
% Check limitation for TL4.4: Currently the handling of Parameters in ML-Code Function blocks is not supported.
%
%  REMARKS
%       Limitation: DD-Info for Parameters inside ML Function blocks is currently inadequate to derive the MIL variable
%                   from it (state of TL4.4p0).
%
%       --> Cosequence of Limitation: Usage of Parameters in ML Function blocks should not destabilize the model
%           analysis. A proper message should inform about the rejection of such parameters.
%


%%
if isempty(getenv('I_WANT_TO_CLAIM_TL_MCODE_LICENSE'))
    MU_MESSAGE('TEST SKIPPED: Currently not clear how to use TL4.4 license for ML functions.');
    return;
end

%% check pre-req
if (ep_core_version_compare('TL4.4') < 0)
    MU_MESSAGE('TEST SKIPPED: Test model using array of structs only for TL4.4 and higher.');
    return;
end


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'mlcode_params_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'tl44', 'ml_func_param_01');

sTlModel      = 'ml_func_param_01_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sTlInitScript = fullfile(sTestRoot, 'init_ml_func_param_01.m');
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'xEnv',          xEnv);
stOpt = ut_prepare_options(stOpt, sResultDir);

sErrFile = ut_ep_model_analyse(stOpt);


%% check test results
i_checkWarningForParameterInMlFunction(sErrFile);

% NOTE: not clear if "paramD" should really be expected as CAL (it is defined as nested Chart parameter on MIL level)

xExp = containers.Map;
xExp('top_A/Subsystem/top_A') = { ...
    'in:top_A/Subsystem/top_A/In1', ...
    'out:top_A/Subsystem/top_A/Out1', ...
    'out:top_A/Subsystem/top_A/Out2', ...
    'cal:top_A/Subsystem/top_A/Chart:paramC', ...
    'cal:top_A/Subsystem/top_A/Chart:paramD', ...
    'disp:top_A/Subsystem/top_A/Chart:y1', ...
    'disp:top_A/Subsystem/top_A/Chart:y2', ...
    'disp:top_A/Subsystem/top_A/Chart:x1'};

xExp('top_A/Subsystem/top_A/Chart') = { ...
    'in:top_A/Subsystem/top_A/Chart/u1', ...
    'out:top_A/Subsystem/top_A/Chart/y1', ...
    'out:top_A/Subsystem/top_A/Chart/y2', ...
    'cal:top_A/Subsystem/top_A/Chart:paramC', ...
    'cal:top_A/Subsystem/top_A/Chart:paramD', ...
    'disp:top_A/Subsystem/top_A/Chart:x1'};

i_checkTlInterfaces(stOpt.sTlResultFile, xExp);
end


%%
function i_checkWarningForParameterInMlFunction(sErrFile)
astMsg = ut_read_error_file(sErrFile);
if ~isempty(astMsg)
    casMsgIds = {astMsg(:).id};
    iIdx = find(strcmp('ATGCV:MOD_ANA:PARAMCHECK_MIL_NOT_FOUND', casMsgIds));
    if (length(iIdx) == 1)
        stMsg = astMsg(iIdx);        
        MU_ASSERT_TRUE(strcmp(stMsg.stKeyValues.variable, 'paramA'), ...
            'Expecting parameter "paramA" to be mentioned in message.');
    else
        MU_FAIL('Expecting exactly one message for a not found MIL parameter.');
    end
else
    MU_FAIL('Expecting messages for inconsistent readout of MIL parameter for ML Function block.');
end
end



%%
function i_checkTlInterfaces(sArchFile, xExpected)
xActual = i_readTlInterfaces(sArchFile);

casExpectedSubs = xExpected.keys;
casActualSubs = xActual.keys;
i_assertExpected('subsystem', casExpectedSubs, casActualSubs);

for i = 1:numel(casExpectedSubs)
    sSub = casExpectedSubs{i};
    
    casExpectedIfs = xExpected(sSub);
    if xActual.isKey(sSub)
        casActualIfs = xActual(sSub);
    else
        casActualIfs = {};
    end
    
    i_assertExpected(['Interface for ', sSub], casExpectedIfs, casActualIfs);
end
end


%%
function xRead = i_readTlInterfaces(sArchFile)
xRead = containers.Map;

hDoc = mxx_xmltree('load', sArchFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hDoc));

ahSubs = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem');
for i = 1:numel(ahSubs)
    hSub = ahSubs(i);
    xRead(i_getPath(hSub)) = i_getInterfacesInSub(hSub);
end
end


%%
function casInterfaces = i_getInterfacesInSub(hSub)
ahIfObjects = mxx_xmltree('get_nodes', hSub, './*[not(self::subsystem)]');
casInterfaces = arrayfun(@i_getInterfaceObjectKey, ahIfObjects, 'UniformOutput', false);
end


%%
function sInterfaceKey = i_getInterfaceObjectKey(hIfObj)
sKind = mxx_xmltree('get_name', hIfObj);
switch sKind
    case 'inport'
        sInterfaceKey = ['in:', i_getPath(hIfObj)];
        
    case 'outport'
        sInterfaceKey = ['out:', i_getPath(hIfObj)];
        
    case 'calibration'
        sInterfaceKey = ['cal:', i_getPath(hIfObj), ':', i_getName(hIfObj)];
        
    case 'display'
        sInterfaceKey = ['disp:', i_getPath(hIfObj), ':', i_getName(hIfObj)];
        
    otherwise
        error('UT:UNEXPECTED_KIND', 'Unexpected TL interface object kind "%s".', sKind);
end
end


%%
function sPath = i_getPath(hObj)
sPath = mxx_xmltree('get_attribute', hObj, 'path');
end


%%
function sName = i_getName(hObj)
sName = mxx_xmltree('get_attribute', hObj, 'name');
end


%%
function i_assertExpected(sContext, casExpected, casActual)
casMissing = setdiff(casExpected, casActual);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('Expected %s "%s" not found.', sContext, casMissing{i}));
end
casUnexpected = setdiff(casActual, casExpected);
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('Unexpected %s "%s" found.', sContext, casUnexpected{i}));
end
end



