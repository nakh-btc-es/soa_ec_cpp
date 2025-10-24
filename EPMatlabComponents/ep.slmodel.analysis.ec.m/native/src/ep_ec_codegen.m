function [stResult, bSuccess] = ep_ec_codegen(xModel, bReuseExistingCode, sUserCodegenPath)
% Generates/reuses code for the provided model and returns as much info as possible.
%
% function [stResult, bSuccess] = ep_ec_codegen(xModel, bReuseExistingCode, sUserCodegenPath)
%
%   INPUT               DESCRIPTION
%     xModel              (string/handle)   optional: model name/handle (if not provided the current model is used)
%     bReuseExistingCode  (boolean)         option to look for existing code
%     sUserCodegenPath    (string)          user defined path to look for the existing code
%
%  OUTPUT               DESCRIPTION
%     stResult            (struct)                  info data
%       .oBuildInfo       (object)                  the RTW.BuildInfo object
%       .sCodegenPath     (string)                  the Codegen path
%       .casMissingFiles  (cell array of strings)   list of missing code files
%
%
%  NOTE_1: Model is assumed to be open!
%  NOTE_2: For "reuse existing code": If during retrieval a relocation of the generated code is detected the returned
%          build info object is adapted to the current location.
%

%%
if ((nargin < 1) || isempty(xModel))
    xModel = bdroot(gcs);
end
if ((nargin < 2) || isempty(bReuseExistingCode))
    bReuseExistingCode = false;
end
if (nargin < 3)
    sUserCodegenPath = '';
end

hModel = i_normalizeModel(xModel);
if bReuseExistingCode
    [stResult, bSuccess] = i_reuseAndCheckExistingCode(hModel, sUserCodegenPath);
else
    [stResult, bSuccess] = i_generateNewCode(hModel);
end
end


%%
function [stResult, bSuccess] = i_generateNewCode(hModel)
oConfig = i_getModelConfig(hModel);
aoRestoreAdaptions = i_adaptForCodegen(oConfig, hModel); %#ok<NASGU> onCleanup object

% -------- generating code
tic;
try
    sModel = get_param(hModel, 'name');
    rtwbuild(sModel, 'generateCodeOnly', true);
catch oEx
    sReport = oEx.getReport('basic', 'hyperlinks', 'off');
    warning('EP:EC:CODEGEN_FAILED', '%s', sReport);
    rethrow(oEx);
end

fprintf('Code generation time : %g\n', toc);
% --------

stResult = i_getBuildResult(sModel);
bSuccess = true;
end


%%
% Note: Build info that is captured dynamically during post-hook evaluation is always avaiable by design. However, in
% some cases it can contain false information (see EP-2439). Build info stored on disc seems to be more reliable.
% However, it is not clear if the storing inside the mat-file can somehow be blocked by a user setting.
%
function stResult = i_getBuildResult(sModel)
% as a fallback prepare the captured build info from the posthook ...
oBuildInfo = i_getCapturedBuildInfoFromPosthook();

% ... however, in the first place try to read out the info from the generated buildInfo.mat on disc
sCodeDir = RTW.getBuildDir(sModel).BuildDirectory;
oGeneratedBuildInfo = i_loadBuildInfo(sCodeDir);
if ~isempty(oGeneratedBuildInfo)
    oBuildInfo = oGeneratedBuildInfo;
end

sCodegenPath = oBuildInfo.getLocalBuildDir;
stResult = struct( ...
    'oBuildInfo',      oBuildInfo, ...
    'sCodegenPath',    sCodegenPath, ...
    'casMissingFiles', {{}});
end


%%
function oBuildInfo = i_loadBuildInfo(sCodeDir)
oBuildInfo = [];
sBuildInfoFile = fullfile(sCodeDir, 'buildInfo.mat');
if exist(sBuildInfoFile, 'file')
    stFileContentBuildInfo = load(sBuildInfoFile);
    oBuildInfo = stFileContentBuildInfo.buildInfo;
end
end


%%
function oBuildInfo = i_getCapturedBuildInfoFromPosthook()
oBuildInfo = evalin('base', 'EPEcaBuildInfo');
evalin('base', 'clear EPEcaBuildInfo');
end


%%
function aoRestoreAdaptions = i_adaptForCodegen(oConfig, hModel)
bIsDirtyBefore = strcmp(get_param(hModel, 'Dirty'), 'on');
aoRestoreAdaptions = [ ...
    i_setParam(oConfig, 'GenerateSampleERTMain', 'off'), ...
    i_setParam(oConfig, 'GenerateReport', 'off'), ...
    i_appendToParam(oConfig, 'PostCodeGenCommand', ';assignin(''base'', ''EPEcaBuildInfo'', buildInfo);')];
if ~bIsDirtyBefore
    % if the model was not in dirty state before, try to restore this by "hiding" the dirty status
    % note: this should be OK, since *every* change done here was (hopefully) reverted by the restore onCleanup objects
    aoRestoreAdaptions(end + 1) = onCleanup(@() set_param(hModel, 'Dirty', 'off'));
end
end


%%
function hModel = i_normalizeModel(xModel)
hModel = get_param(xModel, 'handle');
end


%%
function oActiveConfigSet = i_getModelConfig(xModel)
oModel = get_param(xModel, 'object');
oActiveConfigSet = oModel.getActiveConfigSet;
if isa(oActiveConfigSet, 'Simulink.ConfigSetRef')
    oActiveConfigSet = oActiveConfigSet.getRefConfigSet;
end
end


%%
function aoOnCleanupRestore = i_setParam(axObj, sParam, xNewValue)
aoOnCleanupRestore = [];

for i = 1:numel(axObj)
    xObj = axObj(i);
    xOrigValue = get_param(xObj, sParam);
    if isempty(aoOnCleanupRestore)
        aoOnCleanupRestore = onCleanup(@() set_param(xObj, sParam, xOrigValue));
    else
        aoOnCleanupRestore(end + 1) = onCleanup(@() set_param(xObj, sParam, xOrigValue)); %#ok<AGROW>
    end
    set_param(xObj, sParam, xNewValue);
end
end


%%
function oOnCleanupRestore = i_appendToParam(xObj, sParam, sPostFix)
sOrigValue = get_param(xObj, sParam);
oOnCleanupRestore = onCleanup(@() set_param(xObj, sParam, sOrigValue));

set_param(xObj, sParam, [sOrigValue, sPostFix]);
end


%%
function [stResult, bSuccess] = i_reuseAndCheckExistingCode(hModel, sUserCodegenPath)
casCandidateCodegenPath = i_getCandidateCodegenPaths(hModel, sUserCodegenPath);
[stResult, bSuccess] = i_findExistingBuildInfo(casCandidateCodegenPath);
if bSuccess
    [stResult.casMissingFiles, bSuccess] = i_validateBuildInfo(stResult.oBuildInfo);
end
end


%%
function casCandidateCodegenPaths = i_getCandidateCodegenPaths(hModel, sUserCodegenPath)
sModel = get_param(hModel, 'name');
stBuildDirInfo = RTW.getBuildDir(sModel);
if isempty(sUserCodegenPath)
    casCandidateCodegenPaths = {stBuildDirInfo.BuildDirectory};
else
    % first candidate path: look directly in user codegen path
    sModelPath = fileparts(get_param(hModel, 'FileName'));
    sUserCodegenPath = ep_core_feval('ep_core_canonical_path', sUserCodegenPath, sModelPath);
    
    % second candidate path: look also one level deeper inside the corresponding <model-name>_rtw folder
    sRelBuildDir = stBuildDirInfo.RelativeBuildDir;
    sUserCodegenRtwPath = fullfile(sUserCodegenPath, sRelBuildDir);
    
    casCandidateCodegenPaths = {sUserCodegenPath, sUserCodegenRtwPath};
end
end


%%
function [stInfo, bSuccess] = i_findExistingBuildInfo(casCandidateCodegenPaths)
stInfo = struct( ...
    'oBuildInfo',      [], ...
    'sCodegenPath',    '', ...
    'casMissingFiles', {{}});

bSuccess = true;
if isempty(casCandidateCodegenPaths)
    return;
end

for i = 1:numel(casCandidateCodegenPaths)
    sCodeDir = casCandidateCodegenPaths{i};
    
    if exist(sCodeDir, 'dir')
        oBuildInfo = i_loadBuildInfo(sCodeDir);
        if ~isempty(oBuildInfo)
            oBuildInfo = i_adaptLocalPathsIfRelocated(oBuildInfo, sCodeDir);
            stInfo.oBuildInfo = oBuildInfo;
            stInfo.sCodegenPath = sCodeDir;
            break;
        end
    end
end

if isempty(stInfo.oBuildInfo)
    bSuccess = false;
end
end


%%
function oBuildInfo = i_adaptLocalPathsIfRelocated(oBuildInfo, sCodeDir)
sActualLocalAnchorDir = ep_core_canonical_path(fileparts(sCodeDir));
sStoredLocalAnchorDir = ep_core_canonical_path(oBuildInfo.Settings.LocalAnchorDir);

bWasRelocated = ~strcmp(sActualLocalAnchorDir, sStoredLocalAnchorDir);
if bWasRelocated
    oBuildInfo.Settings.LocalAnchorDir = sActualLocalAnchorDir;
end
end


%%
function [casMissingFiles, bSuccess] = i_validateBuildInfo(oBuildInfo)
casSourceFiles = oBuildInfo.getFullFileList;
casMissingFiles = casSourceFiles(~isfile(casSourceFiles));
bSuccess = isempty(casMissingFiles);
end
