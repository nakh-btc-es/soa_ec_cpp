function [xCleanupTestEnv, stTestData] = sltu_prepare_simenv_base(sModelName, sSuite, sTestDataPath, sTestRootSuffix, bOpenModel, sEnc)
% Utility base function to prepare test environment for simulation and debug
%
% Structure is:
%   <TestRoot>/model  - place for the original model
%   <TestRoot>/data   - test data for the simulation
%

%% prepare folders
sltu_cleanup();
sFullTestDataPath = ep_core_canonical_path(fullfile(ut_testdata_dir_get(), sTestDataPath));

if (nargin < 4) || isempty(sTestRootSuffix)
    sTestRoot = fullfile(pwd, ['sim_', sModelName]);
else
    sTestRoot = fullfile(pwd, ['sim_', sModelName, '_', sTestRootSuffix]);
end
if (nargin < 5)
    bOpenModel = true;
end
if (nargin < 6)
    sEnc = '';
end

sPwd = pwd();
if ~exist(sTestRoot, 'dir')
    mkdir(sTestRoot);
end
xOnCleanupRemoveTestRoot = onCleanup(@() i_robustRemove(sPwd, sTestRoot));
xOnLeavingGoIntoTestRoot = onCleanup(@() i_robustCd(sTestRoot));

sTestRootModel = fullfile(sTestRoot, 'model');
sTestRootData  = fullfile(sTestRoot, 'data');

%% open model in test location
[xOnCleanupRemoveEnv, xEnv, ~, stModelData] = ...
    sltu_prepare_ats_env(sModelName, sSuite, sTestRootModel, sEnc, {'TlCodegen', false});
sModelKind = i_getModelKindFromSuiteName(sSuite);
switch sModelKind
    case 'SL'
        sModelFile  = stModelData.sSlModelFile;
        sInitScriptFile = stModelData.sSlInitScriptFile;
        bIsTL = false;
        
    case 'TL'
        sModelFile  = stModelData.sTlModelFile;
        sInitScriptFile = stModelData.sTlInitScriptFile;
        bIsTL = true;
        
    otherwise
        error('UT:INTERNAL:ERROR', 'Unknown model kind "%s".', sModelKind);
end

if bOpenModel
    xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScriptFile, bIsTL);
else
    xOnCleanupCloseModel = [];
end
xCleanupTestEnv = onCleanup(@() cellfun(@delete, ...
    {xOnCleanupCloseModel, xOnCleanupRemoveEnv, xOnCleanupRemoveTestRoot}));

% copy test data
try
    copyfile(sFullTestDataPath, sTestRootData);
catch oEx
    if strcmp(oEx.identifier, 'MATLAB:COPYFILE:OSError') ...
            && strcmp(oEx.message, 'Invalid cross-device link') ...
            && isunix
        if ~exist(sTestRootData, 'dir')
            mkdir(sTestRootData);
        end
        system(['cp -R "', sFullTestDataPath, '"/* "', sTestRootData, '"']);
    else
        return;
    end
end


% make name of extraction model file unique (see EPDEV-55574) by making the name of the extraction model unique
sExtractionModelFileOrig = fullfile(sTestRootData, 'extraction.xml');
sDate = datestr(now, 'ddyyyyHHMMSSFFF');  
sExtractionModelFile = fullfile(fileparts(sExtractionModelFileOrig), ['ExtractionModel_' sDate '.xml']);
movefile(sExtractionModelFileOrig, sExtractionModelFile, 'f');

if strcmp(sModelKind, 'SL')
    sInputHarnessFile  = fullfile(sTestRootData, 'harnessIn.xml');
    sOutputHarnessFile = fullfile(sTestRootData, 'harnessOut.xml');
else
    sInputHarnessFile  = '';
    sOutputHarnessFile = '';
end

% return values
stTestData = struct( ...
    'xEnv',                   xEnv, ...
    'sModelName',             sModelName, ...
    'sFullTestDataPath',      sFullTestDataPath, ...
    'sTestRootModel',         sTestRootModel, ...
    'sTestRootData',          sTestRootData, ...
    'sModelFile',             sModelFile, ...
    'sInitScriptFile',        sInitScriptFile, ...
    'sModelKind',             sModelKind, ...
    'sExtractionModelFile',   sExtractionModelFile, ...
    'sInputHarnessFile',      sInputHarnessFile, ...
    'sOutputHarnessFile',     sOutputHarnessFile); 
end


%%
function i_robustCd(sDir)
if exist(sDir, 'dir')
    cd(sDir);
end
end


%%
function i_robustRemove(sPwd, sTestRootDir)
cd(sPwd);
if exist(sTestRootDir, 'dir')
    try
        stWarningState = warning('off');
        oRestore = onCleanup(@() warning(stWarningState));
        
        rmdir(sTestRootDir, 's');
        
    catch oEx
        clear oRestore;
        warning('SLTU:FAILED_CLEANUP', 'Test root "%s" could not be removed.\n%s', sTestRootDir, oEx.getReport());
    end 
end
end


%%
function sModelKind = i_getModelKindFromSuiteName(sSuite)
switch sSuite 
    case {'SL', 'EC', 'UT_MIL_SL', 'UT_SL', 'UT_EC'}
        sModelKind = 'SL';
        
    case {'TL', 'UT_MIL_TL', 'UT_TL', 'UT_DA'}
        sModelKind = 'TL';
        
    otherwise
        error('UT:INTERNAL:ERROR', 'Unknown suite "%s". Cannot derive model kind.', sSuite);
end
end

