function stResult = ut_ec_aa_wrapper_analyze(sSuiteName, sModelName)
% IMPORTANT: THIS IS ONLY TEMPORARILY NEEDED UNTIL SIL IS SUPPORTED FOR EC AA WRAPPER
% 
% SL analysis and EC AA wrapper creation .
%
%  INPUT              DESCRIPTION
%    sSuiteName                 (string)        name of the suite the model is taken from (e.g. EC or UT_EC)
%    sModelName                 (string)        name of the model
%    bWithWrapperCreation       (boolean)       true if a wrapper shall be created (only possible for AUTOSAR models)
%


%%
if (nargin < 3)
    stOverrideArgs = struct();
end
bWithWrapperCreation = true;

%% prepare
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% wrapper creation
stAddResult = struct();
if bWithWrapperCreation
    stResultWrapper = ep_ec_model_wrapper_create( ...
        'ModelFile',    sModelFile, ...
        'InitScript',   sInitScript);
    if ~stResultWrapper.bSuccess
        MU_FAIL_FATAL(sprintf('Creating wrapper failed: %s', strjoin(stResultWrapper.casErrorMessages, '; ')));
    end
    evalin('base', 'clear all;')

    sModelFile = stResultWrapper.sWrapperModel;
    sInitScript = stResultWrapper.sWrapperInitScript;
    
    stAddResult.stWrapper = stResultWrapper;
end


%% load the model to be analysed
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU> onCleanup object


%% act
stResult = ep_sl_model_analyze('ModelFile', sModelFile, 'InitScriptFile', sInitScript);


%% additional info that may be needed for UT
casAddInfos = fieldnames(stAddResult);
for i = 1:numel(casAddInfos)
    sAddInfo = casAddInfos{i};    
    stResult.(sAddInfo) = stAddResult.(sAddInfo);
end

% note: add Env cleanup object to return struct to avoid the automatic deleting of the results folder too early
stResult.xOnCleanupDoCleanupEnv = xOnCleanupDoCleanupEnv;
end
