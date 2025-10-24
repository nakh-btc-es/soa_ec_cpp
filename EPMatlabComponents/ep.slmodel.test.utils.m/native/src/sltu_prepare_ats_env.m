function [xOnCleanupDoCleanup, xEnv, sResultDir, stModelData] = sltu_prepare_ats_env(sModelName, sModelSuite, sTestRootDir, sEnc, caxFindArgs)
% Prepare UT environment: create test root directory, upgrade ATS model and copy it into test root directory.
% 
%  [xOnCleanupDoCleanup, xEnv, sResultDir, stModelData] = ...
%                                                    sltu_prepare_ats_env(sModelName, sModelSuite, sTestRootDir, sEnc)
%
%  INPUT             DESCRIPTION
%  - sModelName                       (String)      Name of the ATS/UT model.
%  - sModelSuite                      (String)      ATS/UT Suite name.
%  - sTestRootDir                     (String)      Full path to test root location. Note: If this directry is not
%                                                   existing yet, it it created here.
%  - sEnc                             (String)      optional: special encoding for the model (e.g. 'Shift_JIS')
%  - caxFindArgs                      (cell)        optional: additional arguments for the model-find functionality
%
%  OUTPUT            DESCRIPTION
%  - xOnCleanupDoCleanup              (Obj)         onCleanup object that ensures a proper cleanup is done when UT is
%                                                   finished.
%  - xEnv                             (Obj)         New EPEnvironment object that can be passed on to 
%                                                   lower-level SUT functions.             
%  - sResultDir                       (String)      Fresh directory without content located in TestRootDir.             
%  - stModelData                      (Struct) 
%      .sRootPath                       (String)    Path to the root directory of the model data
%      .sSlModelFile                    (String)    full path to SL Model file
%      .sSlInitScriptFile               (String)    full path to SL Init Script file
%      .sSlAddModelInfoFile             (String)    full path to SL Model Info file
%      .astSubModels                    (Struct)    array of structures with info about sub-models (for EC)
%         .sModelFile                   (String)       model file of the sub-model
%         .sInitScript                  (String)       init script file of the sub-model
%      .sTlModelFile                    (String)    full path to TL Model file
%      .sTlInitScriptFile               (String)    full path to TL Init Script
%      .sEnvFile                        (String)    full path to TL LegacyCode XML
%      .sCodeModel                      (String)    full path to CODE CodeModel XML
%      .bUpgradeSuccess                 (Bool)      true if upgrade was successful, otherwise false
%      .casErrors                       (Strings)   list of errors in case of a failed upgrade
%


%% optional args
if (nargin < 4)
    sEnc = '';
end
if (nargin < 5)
    caxFindArgs = {};
end

%% encoding
% important to set the encoding *before* looking for the model (because of the implicit upgrade mechanism)
sCurrentEnc = i_setEnc(sEnc);

%% data
% special handling for every suite starting with UT and EC, SL, TL
if strncmpi(sModelSuite, 'UT', 2) || strcmp(sModelSuite, 'EC') || strcmp(sModelSuite, 'TL') || strcmp(sModelSuite, 'SL') 
    stModelData = sltu_ut_model_find('ModelName', sModelName, 'ModelSuite', sModelSuite, 'Upgrade', 'refresh', caxFindArgs{:});
else
    stModelData = ep_ats_model_find('ModelName', sModelName, 'ModelSuite', sModelSuite, 'Upgrade', 'refresh', caxFindArgs{:});
end
if ~stModelData.bUpgradeSuccess
    error('SLTU:PREPARE_ATS_ENV:ERROR', '%s\n', 'Model refresh was not successful.', stModelData.casErrors{:});
end

%% main
sPwd = pwd();
xEnv = EPEnvironment();
xOnCleanupDoCleanup = onCleanup(@() i_cleanup(sTestRootDir, sPwd, xEnv, sCurrentEnc));

% create root_dir for test and copy testdata
if exist(sTestRootDir, 'file')
    rmdir(sTestRootDir, 's');
end

copyfile(stModelData.sRootPath, sTestRootDir);
cd(sTestRootDir);
stModelData = i_relocateRoot(stModelData, pwd);


sResultDir = fullfile(pwd, 'ut_results');
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
end
mkdir(sResultDir);
end


%%
function stModelData = i_relocateRoot(stModelData, sNewRootPath)
sOldRootPath = stModelData.sRootPath;
stModelData.sRootPath = sNewRootPath;

casFields = fieldnames(stModelData);
for i = 1:length(casFields)
    sField = casFields{i};
    
     if ~isempty(regexp(sField, 'File$', 'once'))
        sOldFile = stModelData.(sField);

        if isfile(sOldFile)
            stModelData.(sField) = i_relocateRootOfFile(sOldFile, sOldRootPath, sNewRootPath);
        end
    end
end

casSubModelFileFields = {'sModelFile', 'sInitScript'};
for i = 1:numel(stModelData.astSubModels)
    stSubModel = stModelData.astSubModels(i);
        
    for k = 1:numel(casSubModelFileFields)
        sField = casSubModelFileFields{k};
        
        sOldFile = stSubModel.(sField);
        if ~isempty(sOldFile)
            stSubModel.(sField) = i_relocateRootOfFile(sOldFile, sOldRootPath, sNewRootPath);
        end
    end
    stModelData.astSubModels(i) = stSubModel;
end
end


%%
function sFile = i_relocateRootOfFile(sFile, sOldRootPath, sNewRootPath)
sOldFile = sFile;
if (length(sFile) > length(sOldRootPath))
    sCurrentRoot = sFile(1:length(sOldRootPath));
    if ~strcmpi(sCurrentRoot, sOldRootPath)
        error('SLTU:PREPARE_ATS_ENV:ERROR', 'File "%s" does not have "%s" as root path.', sFile, sOldRootPath);
    end
    sRelPath = sFile(length(sOldRootPath)+2:end);
    sFile = fullfile(sNewRootPath, sRelPath);
    
else
    if ~strcmpi(sFile, sOldRootPath)
        error('SLTU:PREPARE_ATS_ENV:ERROR', 'File "%s" does not have "%s" as root path.', sFile, sOldRootPath);
    end
    sFile = sNewRootPath;
end
if (~exist(sFile, 'file') && exist(sOldFile, 'file'))
    error('SLTU:PREPARE_ATS_ENV:ERROR', 'File "%s" was not successfully relocated to "%s".', sOldFile, sNewRootPath);
end
end


%%
function i_cleanup(sTestRoot, sPwd, xEnv, sEnc)
i_DEBUG_printMsg('starting callback ...');
if sltu_currently_debugging()
    warning('SLTU:PREPARE_ATS_ENV:ERROR', '%s: Currently in DEBUG mode: no cleanup done!', mfilename);
    return;
end
cd(sPwd);
try
    sltu_clear_mex;
    bdclose all;
    if sltu_tl_available()
        dsdd_free;
    end
    if exist(sTestRoot, 'dir')
        rmdir(sTestRoot, 's');
    end
    close all force;
    sltu_clear_classes;
catch oEx
    warning('SLTU:PREPARE_ATS_ENV:ERROR', 'Cleanup failed:\n%s\n%s', oEx.identifier, oEx.message);
end
try
    xEnv.clear();
catch oEx
    warning('SLTU:PREPARE_ATS_ENV:ERROR', 'Cleanup failed:\n%s\n%s', oEx.identifier, oEx.message);
end
try
    i_setEnc(sEnc);
catch oEx
    warning('SLTU:PREPARE_ATS_ENV:ERROR', 'Cleanup failed:\n%s\n%s', oEx.identifier, oEx.message);
end
sltu_cleanup();
i_DEBUG_printMsg('... finished callback');
end


%%
% note: function handles empty enc tolerantly by not changing anything and only
function sCurrentEnc = i_setEnc(sEnc)
sCurrentEnc = slCharacterEncoding();
if ~isempty(sEnc)
    if ~strcmp(sCurrentEnc, sEnc)
        slCharacterEncoding(sEnc);
    end
end
end


%%
function i_DEBUG_printMsg(sMsg)
fprintf('[DEBUG:%s:SLTU_PREPARE_CLEANUP_CALLBACK] %s\n', datestr(now, 'HH:MM:SS'), sMsg);
end
