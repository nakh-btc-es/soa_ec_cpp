function varargout = sltu_ut_model_find(varargin)
% This function returns models from a common resource pool.
%
% Note: can be operated in two modes (depending on if the model name is provided or not):
% ==== INFO MODE ===================================
%   casModelNames = sltu_ut_model_find('ModelSuite', <xxx>)
%
% ==== RETRIEVE DATA MODE ==========================
%   stModelData = sltu_ut_model_find(varargin)
%
%  INPUT                          DESCRIPTION
%      varargin                     (key-value pairs)
%
% ------- Key --------------------------------- Value ------------------------------------------------------------------
%
%     ModelName              (string)    Name of the model 
%                                        Note: Use the enumeration 'RegisteredModels' of the corresponding 
%                                        Model Suite 'toString()'.
%
%     ModelSuite             (string)    Name of the model suite where the desired model is located.
%                                        Note: Use the MODEL_SUITE_ID of the corresponding Model Suite.
%
%     Upgrade                (string)    'no'      -- model is not upgraded
%                                        'yes'     -- model is upgraded if version does not match current ML/TL
%                                        'refresh' -- model is upgraded regardless the version
%                                        'force'   -- always upgrade to be sure (previous upgrade steps are ignored)
%                                        (optional parameter, default == 'yes')
%
%  OUTPUT            DESCRIPTION
%  - stModelData             
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


%%
stArgs = i_evalArgs(varargin{:});
stModelPool = ep_ats_model_pool_get();
sSuiteLocation = fullfile(stModelPool.sLocation, stArgs.sModelSuite);
if stArgs.bInfoMode
    varargout{1} = i_getModelNames(sSuiteLocation);
else
    varargout{1} = i_getModelData( ...
        sSuiteLocation, ...
        stArgs.sModelSuite, ...
        stArgs.sModelName, ...
        stArgs.sUpgrade, ...
        stArgs.bWithTlCodegen);
end
end


%%
function stArgs = i_evalArgs(varargin)
stArgs = struct( ...
    'sModelName',     '', ...
    'sModelSuite',    '', ...
    'sUpgrade',       'yes', ...
    'bWithTlCodegen', true, ...
    'bInfoMode',      false);

caxKeyVal = varargin;
for i = 1:2:length(caxKeyVal)
    sKey = caxKeyVal{i};
    xVal = caxKeyVal{i+1};
    
    switch lower(sKey)
        case 'modelname'
            stArgs.sModelName = char(xVal);
            
        case 'modelsuite'
            stArgs.sModelSuite = char(xVal);
            
        case 'upgrade'
            stArgs.sUpgrade = lower(char(xVal));
            if ~any(strcmp(stArgs.sUpgrade, {'no', 'yes', 'refresh', 'force'}))
                error('EP:DEV:ERROR', 'Upgrade mode "%s" is not supported.', stArgs.sUpgrade);
            end
            
        case 'tlcodegen'
            stArgs.bWithTlCodegen = logical(xVal);
            
        otherwise
            error('EP:DEV:ERROR', 'Parameter "%s" is not supported.', sKey);
    end
end

if isempty(stArgs.sModelName)
    stArgs.bInfoMode = true;
end
if isempty(stArgs.sModelSuite)
    error('EP:DEV:ERROR', 'Parameter "ModelSuite" has to be provided.');
end
end


%%
function casModelNames = i_getModelNames(sSuiteLocation)
astFiles = dir(sSuiteLocation);
abIsValid = arrayfun(@(stFile) stFile.isdir && ~any(strcmp(stFile.name, {'.', '..'})), astFiles);
if any(abIsValid)
    astValidDirs = astFiles(abIsValid);
    casModelNames = reshape(sort({astValidDirs(:).name}), [], 1);
else
    casModelNames = {};
end
end


%%
function stData = i_getModelData(sSuiteLocation, sModelSuite, sModelName, sUpgrade, bWithTlCodegen)

stMetaInfo = i_getMetaModelInfo(sSuiteLocation, sModelName);

sOrigModelRootDir = stMetaInfo.sRootDir;
if ~exist(sOrigModelRootDir, 'dir')
    error('SLTU:UT_SUITE:MODEL_ROOT_LOCATION_NOT_FOUND', ...
        'Location "%s" of model "%s" was not found.', sOrigModelRootDir, sModelName);
end

sCachedSuiteRootDir = sltu_context_tmpdir_get(sModelSuite);
sCachedModelRootDir = fullfile(sCachedSuiteRootDir, sModelName);
if ~exist(sCachedModelRootDir, 'dir')
    sltu_model_dir_copy(sOrigModelRootDir, sCachedModelRootDir);
end

stData = struct();

sSlModelFilePath    = '';
sSlInitScriptPath   = '';
sSlAddModelInfoPath = '';
sSlModelMlVer       = '';

sTlModelFilePath  = '';
sTlInitScriptPath = '';
sEnvFilePath      = '';
sTlModelMlVer     = '';
sTlModelTlVer     = '';

sWrapperModelFile = '';
sWrapperModelInitScriptFile = '';
sWrapperModelMlVer = '';

sRootDir = ep_core_canonical_path(sCachedModelRootDir);
for i = 1:numel(stMetaInfo.astModels)

    stModel = stMetaInfo.astModels(i);

    if isempty(stModel.Version.relPath)
        sModelDir = sRootDir;
    else
        sModelDir = fullfile(sRootDir, stModel.Version.relPath);
    end
    
    bIsTL = ~isempty(stModel.Version.tl);
    if bIsTL
        if ~isempty(sTlModelFilePath)
            error('SLTU:UT_SUITE:MODELS_OF_SAME_KIND', 'Multiple models only for different kinds.');
        end
        sTlModelMlVer = stModel.Version.ml;
        sTlModelTlVer = stModel.Version.tl;
        sTlModelFilePath = ep_core_canonical_path(stModel.fileName, sModelDir);
        if ~isempty(stModel.initScript)
            sTlInitScriptPath = ep_core_canonical_path(stModel.initScript, sModelDir);
        end

        for k = 1:numel(stModel.AddFiles)
            stAddFile = stModel.AddFiles(k);
            
            if strcmp(stAddFile.kind, 'LegacyEnv')
                sEnvFilePath = ep_core_canonical_path(stAddFile.name, sModelDir);
            else
                error('SLTU:UT_SUITE:UNEXPECTED_ADD_FILE_KIND', ...
                    'Additional file kind "%s" is not expected for TL models.', stAddFile.kind);
            end
        end

    else
        if ~isempty(sSlModelFilePath) && ~stModel.bWrapperModel
            error('SLTU:UT_SUITE:MODELS_OF_SAME_KIND', 'Multiple models only for different kinds.');
        else
            if (~stModel.bWrapperModel)

                sSlModelMlVer = stModel.Version.ml;
                sSlModelFilePath = ep_core_canonical_path(stModel.fileName, sModelDir);
                if ~isempty(stModel.initScript)
                    sSlInitScriptPath = ep_core_canonical_path(stModel.initScript, sModelDir);
                end
                for k = 1:numel(stModel.AddFiles)
                    stAddFile = stModel.AddFiles(k);

                    if strcmp(stAddFile.kind, 'AddModelInfo')
                        sSlAddModelInfoPath = ep_core_canonical_path(stAddFile.name, sModelDir);
                    else
                        error('SLTU:UT_SUITE:UNEXPECTED_ADD_FILE_KIND', ...
                            'Additional file kind "%s" is not expected for SL models.', stAddFile.kind);
                    end
                end
            end
        end

        if (stModel.bWrapperModel)
            sWrapperModelFile = ep_core_canonical_path(stModel.fileName, sModelDir);
            if ~isempty(stModel.initScript)
                sWrapperModelInitScriptFile = ep_core_canonical_path(stModel.initScript, sModelDir);
            end
            sWrapperModelMlVer = stModel.Version.ml;
        end
      
    end

end

stData.sRootPath = sRootDir;
stData.sSlModelFile = sSlModelFilePath;
stData.sSlInitScriptFile = sSlInitScriptPath;
stData.sSlAddModelInfoFile = sSlAddModelInfoPath;
stData.sWrapperModelFile = sWrapperModelFile;
stData.sWrapperModelMlVer = sWrapperModelMlVer;
stData.sWrapperModelInitScriptFile = sWrapperModelInitScriptFile;
stData.sTlModelFile = sTlModelFilePath;
stData.sTlInitScriptFile = sTlInitScriptPath;
stData.sEnvFile = sEnvFilePath;
stData.sCodeModel = '';
stData.bUpgradeSuccess = true;
stData.astSubModels = '';
stData.casErrors = {{}};


% early return if no model available (pure C-Code)
if (isempty(sSlModelFilePath) && isempty(sTlModelFilePath))
    return;
end

% upgrade if necessary
bUpgrade = false;
switch lower(sUpgrade)
    case 'force'
        bUpgrade = true;
        i_removeUpgradeMarker(stData.sRootPath);
        
    case 'refresh'
        bUpgrade = true;
        
    case 'yes'
        bUpgrade = ~i_isModelVersionMatchingCurrentVersion(sSlModelMlVer, sTlModelMlVer, sTlModelTlVer);
end
if bUpgrade
    if i_wasUpgradeAlreadyDone(stData.sRootPath)
        fprintf('\n[INFO] Skipping upgrade since already done.\n\n');
        return;
    end
    
    if ~isempty(sSlModelFilePath)
        [~, sSlModel] = fileparts(sSlModelFilePath);
        fprintf('\n[INFO] Upgrading SL model "%s".\n', sSlModel);
        [bSuccessSL, casErrors] = ep_ats_test_model_adapt(sSlModelFilePath, sSlInitScriptPath);
        if bSuccessSL
            fprintf('\n[INFO] Upgrading SL model "%s" successful.\n\n', sSlModel);
        else
            fprintf('\n[ERROR] Upgrading SL model "%s" failed.\n\n', sSlModel);
        end
        stData.bUpgradeSuccess = stData.bUpgradeSuccess && bSuccessSL;
        stData.casErrors = casErrors;
    end
    if ~isempty(sTlModelFilePath)
        [~, sTlModel] = fileparts(sTlModelFilePath);
        if i_isTlInstalled()
            if bWithTlCodegen
                fprintf('\n[INFO] Upgrading TL model "%s" with codegen.\n', sTlModel);
                [bSuccessTL, casErrors] = ep_ats_test_model_adapt(sTlModelFilePath, sTlInitScriptPath);
            else
                fprintf('\n[INFO] Upgrading TL model "%s" without codegen.\n', sTlModel);
                [bSuccessTL, casErrors] = ep_ats_test_model_adapt( ...
                    sTlModelFilePath, ...
                    sTlInitScriptPath, ...
                    'TlCodegen', false);
            end
            if bSuccessTL
                fprintf('\n[INFO] Upgrading TL model "%s" successful.\n\n', sTlModel);
            else
                fprintf('\n[ERROR] Upgrading TL model "%s" failed.\n\n', sTlModel);
            end
            stData.bUpgradeSuccess = stData.bUpgradeSuccess && bSuccessTL;
            stData.casErrors = casErrors;
        else
            fprintf('\n[ERROR] Upgrading TL model "%s" is not possbile. TL is not installed.\n\n', sTlModel);
            stData.bUpgradeSuccess = false;
        end
    end
    if stData.bUpgradeSuccess
        i_markThatUpgradeWasDone(stData.sRootPath);
    end
end
end


%%
function stMetaInfo = i_getMetaModelInfo(sSuiteLocation, sModelName)
sRootDir = fullfile(sSuiteLocation, sModelName);
if ~exist(sRootDir, 'dir')
    casNames = i_getModelNames(sSuiteLocation);
    if isempty(casNames)
        fprintf('\n       Selected model suite does not contain any models.\n\n');
    else
        fprintf('\n       Selected model suite does not contain model "%s".', sModelName);
        fprintf('\n       Full list of models inside the model suite:');
        fprintf('\n          * %s', casNames{:});
        fprintf('\n\n');
    end
    error('SLTU:UT_SUITE:MODEL_NOT_FOUND', 'Model "%s" is not available.', sModelName);
end

sMetaInfoXml = fullfile(sRootDir, 'MetaModelInfo.xml');
if ~exist(sMetaInfoXml, 'file')
    error('SLTU:UT_SUITE:MODEL_NOT_FOUND', 'Selected model directory does not contain ModelMetaInfo.xml.\n\n');
end

[hRoot, oOnCleanupCloseDoc] = i_openXml(sMetaInfoXml); %#ok<ASGLU> onCleanup object
stMetaInfo = struct( ...
    'sRootDir',  sRootDir, ...
    'astModels', i_readMetaModelInfo(hRoot));

% try to replace original root dir by model version root dir
sCommonRelPath = stMetaInfo.astModels(1).Version.relPath;
if isempty(sCommonRelPath)
    return;
end
for i = 2:numel(stMetaInfo.astModels)
    if ~strcmpi(stMetaInfo.astModels(i).Version.relPath, sCommonRelPath)
        return;
    end
end

stMetaInfo.sRootDir = fullfile(sRootDir, sCommonRelPath);
for i = 1:numel(stMetaInfo.astModels)
    stMetaInfo.astModels(i).Version.relPath = '';
end
end


%%
function astModels = i_readMetaModelInfo(hRoot)
ahModels = mxx_xmltree('get_nodes', hRoot, '/MetaModelInfo/Model');

ahModels_WrapperModel = mxx_xmltree('get_nodes', hRoot, '/MetaModelInfo/WrapperModel');
if (~isempty(ahModels_WrapperModel))
    ahModels = [ahModels, ahModels_WrapperModel];
end

astModels = arrayfun(@i_readModel, ahModels);
end


%%
function stModel = i_readModel(hModel)
stModel = mxx_xmltree('get_attributes', hModel, '.', 'fileName', 'initScript');

stModel.bWrapperModel = 0;
if (strcmp(mxx_xmltree('get_name', hModel), 'WrapperModel'))
    stModel.bWrapperModel = 1;
end

astVersions = mxx_xmltree('get_attributes', hModel, './Version', 'ml', 'tl', 'relPath');
if isempty(astVersions)
    % according to DTD this is not possible
    error('SLTU:UT_SUITE:NO_VERSION_FOUND', ...
        'MetaModelInfo does not contain any version info for model "%s".', stModel.fileName);
end
stVersion = i_findBestMatchingVersion(astVersions);
if isempty(stVersion)
    error('SLTU:UT_SUITE:NO_VERSION_FOUND', 'No suitable version found for model "%s".', stModel.fileName);
end
stModel.Version = stVersion;
stModel.AddFiles = mxx_xmltree('get_attributes', hModel, './AddFile', 'kind', 'name');
end


%%
function stVersion = i_findBestMatchingVersion(astVersions)
stVersion = [];
if isempty(astVersions)
    return;
end

bIsTl = ~isempty(astVersions(1).tl);
if (bIsTl && ~i_isTlInstalled())
    error('SLTU:UT_SUITE:TL_MODEL_WITHOUT_TL', 'Using TL model without TL being installed is not possible.');
end

if bIsTl
    casVers = {astVersions(:).tl};
    sCurrentVer = ep_core_version_get('tl');
else
    casVers = {astVersions(:).ml};
    sCurrentVer = ep_core_version_get('ml');
end

iBest = [];
sBestVerSoFar = '0.0'; % fake low version
for i = 1:numel(casVers)
    % version is suitable if its lower-equal than this current version
    bIsSuitable = ep_core_version_compare(sCurrentVer, casVers{i}) <= 0;
    
    if bIsSuitable
        % version is better if it's higher than the best version so far
        bIsBetter = ep_core_version_compare(sBestVerSoFar, casVers{i}) > 0;
        if bIsBetter
            iBest = i;
            sBestVerSoFar = casVers{i};
        end
    end
end

if ~isempty(iBest)
    stVersion = astVersions(iBest);
end
end


%%
function bIsInstalled = i_isTlInstalled()
bIsInstalled = exist('dsdd'); %#ok<EXIST>
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
function bIsMatching = i_isModelVersionMatchingCurrentVersion(sSlModelMlVer, sTlModelMlVer, sTlModelTlVer)
sCurrentMlVer = ep_core_version_get('ml');
bIsMatching = isempty(sSlModelMlVer) || strcmp(sSlModelMlVer, sCurrentMlVer);
if ~bIsMatching || isempty(sTlModelTlVer)
    return;
end
    
sCurrentTlVer = ep_core_version_get('tl');
bIsMatching = strcmp(sTlModelTlVer, sCurrentTlVer) && strcmp(sTlModelMlVer, sCurrentMlVer);
end


%%
function sMarkerFile = i_getMarkerFile(sDir)
sMarkerFile = fullfile(sDir, 'upgrade_done.txt');
end


%%
function i_removeUpgradeMarker(sDir)
sMarkerFile = i_getMarkerFile(sDir);
if exist(sMarkerFile, 'file')
    delete(sMarkerFile);
end
end


%%
function i_markThatUpgradeWasDone(sDir)
hFid = fopen(i_getMarkerFile(sDir), 'w');
if (hFid > 0)
    fclose(hFid);
else
    warning('EP:DEV:ERROR', 'Could not mark the upgrade as successfuly finished.');
end
end


%%
function bDone = i_wasUpgradeAlreadyDone(sDir)
bDone = exist(i_getMarkerFile(sDir), 'file');
end


