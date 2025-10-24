function bAdaptSuccess = tu_test_model_adapt_by_build(sModelFile, sInitScript, bWithTlUpgrade, bCleanDd)
% try to adapt SL/TL model to current config versions of ML/SL/TL
%
% function  tu_test_model_adapt(sModelFile, sInitScript, bWithUpgrade, bCleanDd)
%
%
%   INPUT               DESCRIPTION
%      sModelFile         (string)    full(!) path to model file (*.mdl)
%      sInitScript        (string)    optional: full(!) path to init script(*.m) only if needed
%      bWithTlUpgrade      (bool)     optional: do a tl_upgrade (dafault=true)
%      bCleanDd            (bool)     optional: do a cleanup on DD before udating (default=true)
%
%   OUTPUT              DESCRIPTION
%      bAdaptSucces        (bool)     return true if adaptation was successful
%     
%   REMARKS    
%      ! note: original model and DD will be overwritten !
%
%      Note: Function requires TL3.0 and ML2009a and higher.
%     
%   <et_copyright>

%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alex Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision$
%   Last modified: $Date$ 
%   $Author$
%

stWarningState = warning();
xOnCleanupRestore = onCleanup(@() warning(stWarningState));

sPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sPwd));

bAdaptSuccess = true;
try
    sModelFile = i_getAbsPath(sModelFile);
    if ~exist(sModelFile, 'file')
        error('TU:MODEL_ADAPT:MISSING_FILE', 'Could not find model file "%s".', sModelFile);
    end
    
    % go to model location
    [sPath, sModel] = fileparts(sModelFile);
    if ~isempty(sPath)
        cd(sPath);
    end
        
    % if model has init script
    if (nargin < 2) 
        sInitScript = '';
    else
        if ~isempty(sInitScript)
            sInitScript = i_getAbsPath(sInitScript);
            if ~exist(sInitScript, 'file')
                error('TU:MODEL_ADAPT:MISSING_FILE', 'Could not find init script "%s".', sInitScript);
            end
        end
    end
    if (nargin < 3)
        bWithTlUpgrade = true;
    end
    if (nargin < 4)
        bCleanDd = true;
    end
    
    % just in case remove all DDs from memory
    if i_isTargetLinkInstalled()
        dsdd('Close', 'Save', 'off');
        dsdd('unlock');  clear dsdd; dsdd_free();
    end
    
    % open model for analysis
    stOpen = i_modelOpen(sModelFile, sInitScript);
    i_fixSimulinkTypes(stOpen.hModel);
    
    % Note: following fix applies when Simulink 7.7 or higher is being used.
    %
    % For Simulink 7.6 and lower it was not possible to set the Logging format.
    % When coming from Simulink < 7.7 (ML2011a), the logging format should
    % be changed to future-safe "Dataset". Otherwise there will be warnings
    % during MIL Simulations.
    %
    if (~verLessThan('simulink', '7.7') && i_verLessThan(stOpen.sModelVerSL, '7.7'))
        % Note: set() only possible if Model has no Reference to external Config
        if ~isa(stOpen.hConfigSet, 'Simulink.ConfigSetRef')
            for i = 1:length(stOpen.casModelRefs)
                hModelRef = get_param(stOpen.casModelRefs{i}, 'handle');
                set_param(hModelRef, 'SignalLoggingSaveFormat', 'Dataset');
                save_system(hModelRef);
            end
            set_param(stOpen.hModel, 'SignalLoggingSaveFormat', 'Dataset');
        end
    end
        
    % for SL model take a shortcut
    if ~stOpen.bIsTL        
        i_upgradeSlModel(sModel, stOpen);
        
        % save and close system
        i_modelClose(stOpen, true);
        return;
    end
    
    % ------ from now on only TL models ----------
    if ~i_isTargetLinkInstalled()
        warning('TU:MODEL_ADAPT:TL_UPGRADE_NOT_POSSIBLE', ...
            'TargetLink model properties cannot be upgraded because TargetLink is not installed.');
        bAdaptSuccess = false;
        return;
    end
    
    sOrig = ds_error_get('BatchMode');
    ds_error_set('BatchMode', 'on');

    % delete stored information about generated code from DD if needed
    if bCleanDd
        ahChilds = dsdd('GetChildren', '/Subsystems');
        for i = 1:length(ahChilds)
            dsdd('Delete', ahChilds(i));
        end
    end
    % first upgrade DD
    % note: since TL 3.4, the dsdd_upgrade function has been replaced by 
    % dsdd('Upgrade'[,<DD_Identifier>])
    if i_isTlVersionLess('3.4')
        dsdd_upgrade();
    else
        dsdd('Upgrade');
    end
    i_validateDd(sModel);
    
    pause(2); % pause after upgrading and validating DD

    if bWithTlUpgrade
        bUpgradeSuccess = false;
        bCodeSuccess    = false;
        i_handleModelState(sModel);
        try
            ds_error_clear();
            bUpgradeSuccess = i_upgradeModel(sModel, stOpen.casModelRefs);
            pause(2); % pause after upgrading model
            
            bCodeSuccess = i_generateCodeByBuild(sModel, stOpen.casModelRefs);
            if ~bCodeSuccess
                i_printGenerateError(sModel);
                
                % most often tu_test_model_adapt fails generating code with 
                % the exception:
                % E00000: ERROR USING I_WRITELOGFILE:
                %***         Error opening dsdd_validate.log
                %***         No such file or directory
                % ===> try to generate such a file manually and look how it goes
                % 
                pause(1);
                i_tryFopenDsddValidate(sModel);
                pause(2);
                
                % now try again to generate code
                bCodeSuccess = i_generateCode(sModel, stOpen.casModelRefs, 'TL_CODE_HOST');
                if ~bCodeSuccess
                    i_printGenerateError(sModel);
                end
            end
            
        catch oEx
            % just a warning, otherwise ignore
            i_warning('TU:MODEL_ADAPT:ERROR_GEN_CODE', ...
                'Exception generating code for model "%s" with TL upgrade.\n\n%s', ...
                sModel, i_getErrorStackAndMessage(oEx));
        end
        i_handleModelState();
        if (~bUpgradeSuccess || ~bCodeSuccess)
            fprintf(['\nTU:MODEL_ADAPT:ERROR_GEN_CODE:  ', ...
                'Could not create code for model "%s" with TL upgrade.\n'], sModel);
            
            % try alternative way without TL upgrade
            ds_error_set('BatchMode', sOrig);
            i_modelClose(stOpen, false);
            bdclose all; dsdd('unlock'); clear mex; %#ok<CLMEX>
            
            pause(5);
            bAdaptSuccess = tu_test_model_adapt(sModelFile, sInitScript, false);            
            return;
        end
    else
        % try out codegen twice, wait some seconds in between
        ds_error_clear();

        bCodeSuccess = i_generateCodeByBuild(sModel, stOpen.casModelRefs);
        if ~bCodeSuccess
            i_printGenerateError(sModel);

            % most often tu_test_model_adapt fails generating code with 
            % the exception:
            % E00000: ERROR USING I_WRITELOGFILE:
            %***         Error opening dsdd_validate.log
            %***         No such file or directory
            % ===> try to generate such a file manually and look how it goes
            % 
            pause(1);
            i_tryFopenDsddValidate(sModel);
            pause(2);

            % now try again to generate code
            bCodeSuccess = i_generateCode(sModel, stOpen.casModelRefs, 'TL_CODE_HOST');
            if ~bCodeSuccess
                bAdaptSuccess = false;
                i_printGenerateError(sModel);
            end
        end
    end
    ds_error_set('BatchMode', sOrig);
    
    % save and close system
    i_modelClose(stOpen, true);
    
    % just in case remove all DDs from memory
    dsdd('Close', 'Save', 'off');
    dsdd('unlock'); clear dsdd;
    close all force; % to get rid of model figures (plotting windows)
    
catch oEx
    error('TU:MODEL_ADAPT:ERROR_ADAPT', ...
        'Exception adapting model file "%s".\n\n%s', ...
        sModelFile, i_getErrorStackAndMessage(oEx));
end
end


%% i_getProjectfile 
% get projectfile from the model file without opening it in Simulink
function sDdFile = i_getProjectfile(sModelFile)
[sModelPath, sModelName, sExt] = fileparts(sModelFile); %#ok<ASGLU>

if strcmpi(sExt, '.mdl')
    sDdFile = i_getProjectfileFromMDL(sModelFile);
else
    sDdFile = i_getProjectfileFromSLX(sModelFile);
end
end


%% i_getProjectfileFromMDL 
% get projectfile from MDL format
function sDdFile = i_getProjectfileFromMDL(sModelFile)
sDdFile = '';

sText = i_readFile(sModelFile);
if ~isempty(regexp(sText, 'TargetLink Simulation Frame', 'once'))
    casDdFile = regexp(sText, 'DS_PROJECTFILE\s*"([^"]*)', 'once', 'tokens');
    if isempty(casDdFile)
        sDdFile = tl_pref('get', 'projectfile');
    else
        sDdFile = casDdFile{1};
    end 
end
end


%% i_getProjectfileFromSLX
% get projectfile from SLX format
function sDdFile = i_getProjectfileFromSLX(sModelFile)
sDdFile = '';

sTmpDir = tempname();
mkdir(sTmpDir);
try
    [p, sModelName] = fileparts(sModelFile); %#ok<ASGLU>
    sTmpFile = fullfile(sTmpDir, [sModelName, '.zip']);
    copyfile(sModelFile, sTmpFile, 'f');
    unzip(sTmpFile, sTmpDir);
    sDiagramFile = fullfile(sTmpDir, 'simulink', 'blockdiagram.xml');
    if exist(sDiagramFile, 'file')
        sDdFile = i_getProjectfileFromBlockdiagramXML(sDiagramFile);
    else
        error('TU:MODEL_ADAPT:MISSING_FILE', ...
            'Expected XML file "%s" not found.', sDiagramFile);    
    end
    
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_READ_FILE', ...
        'Error reading out SLX file "%s".\n\n%s', ...
        sModelFile, i_getErrorStackAndMessage(oEx));    
end

try
    rmdir(sTmpDir, 's');
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_RMDIR', ...
        'Error removing temp dir "%s".\n\n%s', ...
        sTmpDir, i_getErrorStackAndMessage(oEx));
end
end


%% i_getProjectfileFromBlockdiagramXML
% read-out the DD-reference from the XML diagram file of the SLX-format
function sDdFile = i_getProjectfileFromBlockdiagramXML(sDiagramFile)
sDdFile = '';

if isempty(which('mxx_xmltree'))
    error('TU:MODEL_ADAPT:XMLTREE_MISSING', ...
        'Tool "mxx_xmltree" needed for SLX model format support. Cannot proceed.');
end

hDoc = mxx_xmltree('load', sDiagramFile);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));
try
    sXPath = '/ModelInformation/Model/UserParameters/P[@Name="DS_PROJECTFILE"]';
    hPrjNode = mxx_xmltree('get_nodes', hDoc, sXPath);
    if ~isempty(hPrjNode)
        sDdFile = mxx_xmltree('get_content', hPrjNode);
    else
        sXPath = '/ModelInformation/Model/UserParameters/P[@Name="TL_MAIN_DATA"]';
        hMainDataNode = mxx_xmltree('get_nodes', hDoc, sXPath);
        if ~isempty(hMainDataNode)
            % information about DD file not really necessary in main function
            sDdFile = tl_pref('get', 'projectfile');
        end
    end
catch oEx
    mxx_xmltree('clear', hDoc);
    error('TU:MODEL_ADAPT:ERROR_READ_BLOCKDIAGRAM', ...
        'Error reading out blockdiagram file "%s".\nGot error "%s".', ...
        sDiagramFile, i_getErrorStackAndMessage(oEx));    
end
end


%% i_readFile
% read content of a text file into a string
function sText = i_readFile(sFile)
hFile = fopen(sFile, 'r');
if (hFile < 0)
    error('TU:MODEL_ADAPT:ERROR_OPEN_FILE', ...
        'File "%s" could not be opened.', sFile);
end

sText = '';
try
    sText = fread(hFile, [1, Inf], '*char');
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_READ_FILE', ...
        'Error reading file "%s".\n\n%s', sFile, i_getErrorStackAndMessage(oEx));
end

try
    fclose(hFile);
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_CLOSE_FILE', ...
        'Error closing file "%s".\n\n%s', ...
        sFile, i_getErrorStackAndMessage(oEx));
end
end


%% persistent params in tl_upgrade
function i_persistentTlParamSet()
try
    clear tl_upgrade;
    tl_upgrade( ...
        'LoadModelOnly',    true, ...
        'UseTL2xPortNames', false);
    
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_SET_PARAM', ...
        'Setting persisent params for "tl_upgrade" failed with error.\n\n%s', ...
        i_getErrorStackAndMessage(oEx));
end
end


%% i_upgradeModel
function bAllUpgradeSuccess = i_upgradeModel(sModel, casModelRefs)
if ~isempty(casModelRefs)
    casModel = [{sModel}, casModelRefs];
else
    casModel = {sModel};
end
bIsPreTl4 = i_isTlVersionLess('4.0');

bAllUpgradeSuccess = true;
for i = 1:length(casModel)
    ds_error_clear();
    sModel = casModel{i};
    if bIsPreTl4
         tl_upgrade( ...
            'Model',            sModel, ...
            'UpgradeLibs',      true, ...
            'RebuildSfcn',      true, ...
            'LoadModelOnly',    true, ...
            'UseTL2xPortNames', false);
    else
        tlUpgrade( ...
            'Model', sModel, ...
            'CheckModel', 'FixIssues');
    end
    bUpgradeSuccess = ~ds_error_check();
    if ~bUpgradeSuccess
        stErr = ds_error_get();
        i_warning('TU:MODEL_ADAPT:ERROR_UPDATE_MODEL', ...
            'Error updating model "%s" with TL upgrade:\n"%s"', ...
            sModel, stErr.msg);
    end
    
    % check also if model init still possible
    if bUpgradeSuccess
        bUpgradeSuccess = i_checkInit(sModel);
    end

    if bUpgradeSuccess
        save_system(sModel);
    else
        bAllUpgradeSuccess = false;        
    end
end
end


%%
function bSuccessful = i_checkInit(sModel)
bSuccessful = false;
try
    sys = feval(sModel, [], [], [], 0); %#ok
    
    % because of TL-bug, the simhandle needs to be deleted;
    % otherwise the TL-codegen will potentially fail
    % (see BTS/34627)
    hSim = tlds(0, 'get', 'simhandles');
    if ~isempty(hSim)
        tlds(hSim(end), 'delete');
    end
    
    bSuccessful = true;
catch oEx
    i_warning('TU:MODEL_ADAPT:INIT_FAILED', ...
        'Model "%s" cannot be intialized:\n\n%s', sModel, ...
        i_getErrorStackAndMessage(oEx));
end
end


%%
% Using function with one arg sets the state. Using it without any argument
% restores the original state.
function i_handleModelState(sModelName)
persistent sAccelMode;
persistent sModel;

if (nargin > 0)
    sModel = sModelName;
    sAccelMode = get_param(sModel, 'SimulationMode');
    if ~strcmpi(sAccelMode, 'normal')
        set_param(sModel, 'SimulationMode', 'normal');
    end
else % restore
    if ~isempty(sAccelMode) && ~strcmpi(sAccelMode, 'normal')
        set_param(sModel, 'SimulationMode', sAccelMode);
    end
end
end


%% i_isTlVersionLess
function bIsLess = i_isTlVersionLess(sCompareTlVersion)
bIsLess = true;
if ~isempty(which('verLessThan'))
    bIsLess = verLessThan('TL', sCompareTlVersion);
else
    try
        stTlVer = ver('tl');
        
    catch oEx %#ok<NASGU>
        % just ignore exception; TL might not be installed
        stTlVer = [];
    end
    if ~isempty(stTlVer)
        bIsLess = i_verLessThan(stTlVer.Version, sCompareTlVersion);    
    end
end
end


%% i_verLessThan
function bIsLess = i_verLessThan(sVersion, sCompareVersion)
bIsLess = false;

sCompareRest = sCompareVersion;
sRest        = sVersion;
while ~bIsLess
    if (isempty(sCompareRest) && isempty(sRest))
        return;
    end
    if isempty(sCompareRest)
        sCompareRest = '0';
    end
    if isempty(sRest)
        sRest = '0';
    end
        
    [sCompareNum, sCompareRest] = strtok(sCompareRest, '.'); %#ok<STTOK>
    dCompareNum = str2double(sCompareNum);

    [sNum, sRest] = strtok(sRest, '.'); %#ok<STTOK>
    dNum = str2double(sNum);
    
    if (isnan(dCompareNum) || isnan(dNum))
        error('TU_ADAPT:ERROR', ...
            'Cannot compare versions: "%s" and "%s".', ...
            sVersion, sCompareVersion);
    end
    
    if (dCompareNum > dNum)
        bIsLess = true;
        return;
    end    
end
end


%% model close
function i_modelClose(stOpenRes, bWithSave)

[sModelPath, sModelName, sExt] = fileparts(stOpenRes.sModelFile); %#ok sExt not used

% update/refresh model references (otherwise dialogs for ML2015b)
try
    if (bWithSave && ~isempty(stOpenRes.casModelRefs))
        sSlprj = fullfile(pwd, 'slprj');
        if exist(sSlprj, 'dir')
            clear mex; %#ok<CLMEX>
            try
                rmdir(sSlprj, 's');
            catch
            end
        end
        for i = 1:length(stOpenRes.casModelRefs)
            i_checkInit(stOpenRes.casModelRefs{i});
            save_system(stOpenRes.casModelRefs{i});
        end
        i_checkInit(sModelName);
    end

catch oEx
    i_warning('TU:MODEL_UPDATE:REFRESH_FAILED', '%s', ...
        i_getErrorStackAndMessage(oEx));
end

% close current DD for TL models
if stOpenRes.bIsTL
    if bWithSave
        dsdd('Close', 'Save', 'on');
    else
        dsdd('Close', 'Save', 'off');
    end
    dsdd('unlock'); clear dsdd; dsdd_free();
end

if bWithSave
    % save first the libs
    i_closeSaveLibs(sModelName);
    
    if ~isempty(stOpenRes.casModelRefs)
        for i = 1:length(stOpenRes.casModelRefs)
            if ~i_closeSystemRobust(stOpenRes.casModelRefs{i}, true)
                % try again
                pause(1);
                i_closeSystemRobust(stOpenRes.casModelRefs{i}, true);
            end
        end
    end
    
    % just make sure that the modelworkace is in sync
    try
        hMdlWs = get_param(sModelName, 'modelworkspace');
        hMdlWs.reload;
    catch oEx %#ok<NASGU>
        % just ignore
        lasterror('reset'); %#ok<LERR>
    end
    
    if ~i_closeSystemRobust(sModelName, true)
        % try again after pausing
        pause(1);
        i_closeSystemRobust(sModelName, true);
    end
else
    i_closeSystemRobust(sModelName, false);
    if ~isempty(stOpenRes.casModelRefs)
        for i = 1:length(stOpenRes.casModelRefs)
            i_closeSystemRobust(stOpenRes.casModelRefs{i}, false);
        end
    end
end

i_clearDlls(sModelPath, 'dll');
i_clearDlls(sModelPath, 'mexw32');
i_clearDlls(sModelPath, 'mexw64');
end


%% unload all DLLs with provided extension from memory
function i_clearDlls(sDir, sExt)
astDll = dir( fullfile(sDir, ['*.', sExt]) );
for k = 1:length(astDll)
    try clear(astDll(k).name); catch, end %#ok<CTCH>
end
end


%% model open
function stRes = i_modelOpen(sModelFile, sInitScript)
xInfo = Simulink.MDLInfo(sModelFile);

stRes = struct( ...
    'sModelFile',   sModelFile, ...
    'sModelVerSL',  xInfo.SimulinkVersion, ...
    'casModelRefs', {{}}, ...
    'casLibs',      {{}}, ...
    'bIsTL',        false, ...
    'hConfigSet',   [], ...
    'hModel',       []);

try    
    % get DD file <--> info if model is TL or SL
    sDdFile = i_getProjectfile(sModelFile);
    bIsTL = ~isempty(sDdFile);
    stRes.bIsTL = bIsTL;
    
    if (bIsTL && ~i_isTargetLinkInstalled())
        error('TU:MODEL_ADAPT:UPGRADING_TL_MODEL_WITHOUT_TL', '%s', ...
            'You are trying to upgrade TL model "%s" without having TL installed. This is not possible.');    
    end

    [sMdlPath, sMdlName, sExt] = fileparts(sModelFile); %#ok only name is interesting

    % suppress warnings and interaction
    i_warning('off');
    xOnCleanupRestore = onCleanup(@() i_warning('on'));
    if bIsTL
        sBatchMode = ds_error_get('BatchMode');
        ds_error_set('BatchMode', 'on');
        xOnCleanupRestoreDS = ...
            onCleanup(@() ds_error_set('BatchMode', sBatchMode));
    end
    
    if ~isempty(sInitScript)
        i_callInitScript(sInitScript);
    end

    % load the model into workspace
    try
        if bIsTL
            if i_isTlVersionLess('4.0')
                i_persistentTlParamSet();
            end
        end
        %stRes.hModel = load_system(sMdlName); % not supported by ML2007a
        load_system(sMdlName); 
        stRes.hModel = get_param(sMdlName, 'Handle');
        stRes.hConfigSet = getActiveConfigSet(sMdlName);
        
        % load all libs
        stRes.casLibs = i_loadLibs(sMdlName);
        
        % and open also all ModelRefs
        if ~isempty(which('find_mdlrefs'))
            casModelRefs = find_mdlrefs(sMdlName)'; % ' for making row-vector
            
            % last ref is always the model itself, so throw info away
            casModelRefs(end) = [];
            
            if ~isempty(casModelRefs)
                for i = 1:length(casModelRefs)
                    load_system(casModelRefs{i});
                end
                stRes.casModelRefs = casModelRefs;
            end
        end
        
    catch oEx
        error('TU:MODEL_ADAPT:ERROR_LOAD_MODEL', ...
            'Exception loading model "%s".\n\n%s', ...
            sMdlName, i_getErrorStackAndMessage(oEx));
    end
    
    % check if current DD is the one we need for model
    if bIsTL
        % get and load DD
        sDD = dsdd_manage_project('GetProjectFile', sMdlName);
        if i_isTlVersionLess('3.3')
            sCurrDd = dsdd('GetEnv', 'ProjectFile');
        else
            sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
        end
                  
        % current DD not the one we need, so load the right one
        if ~strcmp(sDD, sCurrDd)
            dsdd('Close', 'Save', 'on');
            dsdd('Open', 'file', sDD, ...
                'Upgrade', 'off'); % prevent PopUp, upgrade will be done later
        end
    end

catch oEx
    error('TU:MODEL_ADAPT:ERROR_LOAD_MODEL', ...
        'Exception loading model file "%s".\n\n%s', ...
        sModelFile, i_getErrorStackAndMessage(oEx));
end
end


%% call init script
function i_callInitScript(sInitScript)
sPwd = pwd;
xOnCleanupReturn = onCleanup(@() cd(sPwd));
[sPath, sScript] = fileparts(sInitScript);    
if (~isempty(sPath) && ~strcmp(sPath, '.'))
    cd(sPath);
end
evalin('base', sScript);
end


%% get abs path
function sAbsFile = i_getAbsPath(sRelFile)
[sRelPath, sFile, sExt] = fileparts(sRelFile);
if ~isempty(sRelPath)
    sPwd = pwd();
    xOnCleanupReturn = onCleanup(@() cd(sPwd));
    cd(sRelPath);
end
sAbsFile = fullfile(pwd(), [sFile, sExt]);
end


%%
function bCodeSuccess = i_generateCodeByBuild(sModel, casModelRefs)
ds_error_clear();
for i = 1:length(casModelRefs)
    sModelRef = casModelRefs{i};
    i_closeSaveLibs(sModelRef);
    close_system(sModelRef, 1); % model refs have to be closed for codegen
end
try
    tl_build_host( ...
        'Model',                  sModel, ...
        'AllCodeGenerationUnits', 'on');    
    tl_set_sim_mode( ...
        'Model',   sModel, ...
        'simMode', 'TL_BLOCKS_HOST');
catch oEx
    fprintf('\nTU_ADAPT:WARNING: Error generating code for model "%s":\n"%s"\n', sModel, oEx.message);    
end
bCodeSuccess = ~ds_error_check();

for i = 1:length(casModelRefs)
    load_system(casModelRefs{i});
end
end


%%
function bCodeSuccess = i_generateCode(sModel, casModelRefs, sSimMode)
ds_error_clear();
for i = 1:length(casModelRefs)
    sModelRef = casModelRefs{i};
    i_closeSaveLibs(sModelRef);
    close_system(sModelRef, 1); % model refs have to be closed for codegen
end
sOptGenerateAll = 'GenerateAll';
if ~i_isTlVersionLess('3.2')
    sOptGenerateAll = 'IncludeSubItems';
end
tl_generate_code( ...
    'Model',         sModel, ...
    'SimMode',       sSimMode, ...
    sOptGenerateAll, 'on' );
if ~i_isTlVersionLess('3.4')
    % for TL >= 3.4 handle also the generation of AUTOSAR RTE Code
    ahSubs = dsdd('Find', '/Subsystems', 'objectKind', 'Subsystem');
    if ~isempty(ahSubs)
        casTlSubs = cell(1, length(ahSubs));
        for i = 1:length(ahSubs)
            casTlSubs{i} = dsdd('GetAttribute', ahSubs(i), 'Name');
        end
        if ~i_isTlVersionLess('4.3')
            sApplication = dsdd_manage_application('GetApplication');
            stConfig = tl_get_host_simconfig();
            sTlBuild = tlGetBuildDirPath(sApplication, stConfig.board, stConfig.cc);
            if ~exist(sTlBuild, 'dir')
                mkdir(sTlBuild);
            end
            tl_handle_rtecg_call(sModel, casTlSubs, 'TLSim', sTlBuild);
        else
            tl_handle_rtecg_call(sModel, casTlSubs, 'TLSim');
        end
    end
end
for i = 1:length(casModelRefs)
    load_system(casModelRefs{i});
end
bCodeSuccess = ~ds_error_check();            
end


%% i_printGenerateError
function i_printGenerateError(sModel)
stErr = ds_error_get();
if ~isempty(stErr)
    fprintf('\nTU_ADAPT:WARNING: Error generating code for model "%s" with TL upgrade:\n"%s"\n', sModel, stErr.msg);
else
    fprintf('\nTU_ADAPT:WARNING: Unknown rrror generating code for model "%s" with TL upgrade.\n"', sModel);    
end
ds_error_clear();
end


%% i_tryFopenDsddValidate
function i_tryFopenDsddValidate(sModel)
try
    hFid = fopen('dsdd_validate.log', 'wt');
    if (hFid > 0)
        fclose(hFid);
    else
        error('TU:MODEL_ADAPT:ERROR_CREATE_FILE', ... 
            'Could not manually create file "dsdd_validate.log" for model: "%s"', ...
            sModel);
    end
catch oEx
    error('TU:MODEL_ADAPT:ERROR_CREATE_FILE', ... 
        'Could not manually create file "dsdd_validate.log" for model: "%s".\n\n%s', ...
        sModel, i_getErrorStackAndMessage(oEx));
end
end


%% i_validateDd
function i_validateDd(sModel)
ds_error_clear();

% Note: 
% for TL3.3 (and maybe others) dsdd_validate() is resetting the warning level
% --> memorize it before and reset it after calling
stMem = warning();
dsdd_validate({'/Config', '/Pool'}, 'Level', 4, 'LogFile', 'dsdd_validate.log');
warning(stMem);

if ds_error_check()
    stErr = ds_error_get();
    if isempty(stErr)
        stErr.msg = 'unknown error';
    end
    error('TU:MODEL_ADAPT:INVALID_DD', ...
        'Upgraded DD of model "%s" is invalid.\n%s', sModel, stErr(1).msg);
end
end


%% get stack info and message from exception as string
function sErrMsg = i_getErrorStackAndMessage(oEx, nCauseLevel)
if (nargin < 2)
    nCauseLevel = 0;
end
if (nCauseLevel < 1)
    sCauseLevel = '======== main error ===========';
else
    sCauseLevel = sprintf('-------- caused by (%d) -----------', nCauseLevel);
end
sStack = sprintf('stack:\n');
for i = 1:length(oEx.stack)
    sStack = [sStack, sprintf('%i) file: "%s", func: "%s" line: %i\n', ...
        i, oEx.stack(i).file, oEx.stack(i).name, oEx.stack(i).line)]; %#ok<AGROW>
end
sSubErrMsg = '';
for i = 1:length(oEx.cause)
    sSubErrMsg = [sSubErrMsg, i_getErrorStackAndMessage(oEx.cause{i}, nCauseLevel + 1)]; %#ok<AGROW>
end

sErrMsg = sprintf('%s\n%s\n\n%s\n\n%s', sCauseLevel, oEx.message, sStack, sSubErrMsg);
end


%% i_loadLibs
function casLibs = i_loadLibs(sModelName)
if isempty(sModelName)
    return;
end
astLibInfo = libinfo(sModelName);
if isempty(astLibInfo)
    casLibs = {};
else
    casLibs = unique({astLibInfo(:).Library});
    for i = 1:length(casLibs)
        try
            load_system(casLibs{i});
        catch oEx
            i_warning('TU:MODEL_ADAPT:LOAD_LIB_FAILED', ...
                'Loading Library "%s" failed.\n%s', casLibs{i}, ...
                i_getErrorStackAndMessage(oEx));
        end
    end
end
end


%% i_closeSaveLibs
function i_closeSaveLibs(sModelName)
if isempty(sModelName)
    return;
end

% do not save any of the following libs
casBlackListLibs = {...
    'tllib', ...
    'tl_autosar_lib', ...
    'tl_ar_addon_lib', ...
    'tl_ar_addon_test_support_lib', ...
    'simulink', ...
    'simulink_extras', ...
    'atgcv_lib', ...
    'evlib'}; 

% get all lib references in model
astLibInfo = libinfo(sModelName);

if ~isempty(astLibInfo)
    % ignore all unresolved/inactive lib references
    astLibInfo = astLibInfo(strcmpi({astLibInfo.LinkStatus}, 'resolved'));
    
    % remove double entries
    casLibs = unique({astLibInfo(:).Library});
    
    % exclude tllib and simulink from libs
    abSelect = true(1, length(casLibs));
    for i = 1:length(casLibs)
        abSelect(i) = ~any(strcmpi(casLibs{i}, casBlackListLibs));
    end
    casLibs = casLibs(abSelect);
    
else
    casLibs = {};
end
if isempty(casLibs)
    return;
end

% avoid libs from certain places: MATLABROOT, DSPACE_ROOT
sDspaceRoot = i_dspaceroot();
if isempty(sDspaceRoot)
    sDspaceRoot = getenv('TL_ROOT');
end

if ~isempty(sDspaceRoot)
    casBlackListPaths = { ...
        matlabroot(), ...
        sDspaceRoot};
else
    casBlackListPaths = { ...
        matlabroot()};
end


% try only to update Libs in the "vicinity" of the Model (== current dir)
% -- root can be at most 2 levels higher than current directory
sVicinityRoot = fileparts(fileparts(pwd));
casWhiteListPaths = {sVicinityRoot};

for j = 1:length(casLibs)
    sLib  = casLibs{j};
    try
        sFile = get_param(sLib, 'FileName');
    catch oEx %#ok<NASGU>
        % ignore Libs that are not even open and cause get_param to fail
        continue;
    end
    
    % first the BlackList
    bIsValid = true;
    for i = 1:length(casBlackListPaths)
        sPath = casBlackListPaths{i};
        nPathLen = length(sPath);

        % lib is invalid if it has a black-list root-path
        bIsValid = ~strncmpi(sPath, sFile, nPathLen);
        
        % if invalid, stop now; otherwise keep going
        if ~bIsValid
            break;
        end
    end
    
    % if Lib is not on BlackList check if it is on WhiteList with reversed logic
    if bIsValid
        bIsValid = false;
        for i = 1:length(casWhiteListPaths)
            sPath = casWhiteListPaths{i};
            nPathLen = length(sPath);

            % lib is valid if it has a white-list root-path
            bIsValid = strncmpi(sPath, sFile, nPathLen);

            % if invalid, stop now; otherwise keep going
            if bIsValid
                break;
            end
        end
    end
    
    
    if bIsValid
        i_closeSystemRobust(sLib, true);
    else
        i_closeSystemRobust(sLib, false);
    end
end
end


%%
function sPath = i_dspaceroot()
if exist('tl_env', 'file')
    sPath = tl_env('GetProductRoot');
else
    sPath = '';
end
end


%% i_closeSystemRobust
function bSuccess = i_closeSystemRobust(sSystem, bDoSave, bDoRepeat)
if (nargin < 3)
    bDoRepeat = true;
end
bSuccess = false;
try
    close_system(sSystem, double(bDoSave));
    bSuccess = true;
catch oEx
    if bDoRepeat
        if strcmpi(oEx.identifier,  'Simulink:Engine:InvModelClose')
            i_tryTerminateSystem(sSystem);
            bSuccess = i_closeSystemRobust(sSystem, bDoSave, false);
        elseif strcmpi(oEx.identifier,  'Simulink:Commands:SaveSysNotFullyLoaded')
            bSuccess = i_closeSystemRobust(sSystem, false, false);
        end
    else
        disp(['Error closing system -- ', i_getErrorStackAndMessage(oEx)]);
    end
end
end


%%
function i_tryTerminateSystem(sSystem)
try
    evalin('base', sprintf('%s([],[],[],''term'')', sSystem));
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_TERM_MODEL', 'Terminating system "%s" failed.\n%s', sSystem, oEx.message);
end
end


%%
function i_upgradeSlModel(sModel, stOpen)
for i = 1:length(stOpen.casModelRefs)
    i_slUpdateRobust(stOpen.casModelRefs{i});
end
i_slUpdateRobust(sModel);
end


%%
function i_slUpdateRobust(sModel)
i_warning('off');
onCleanupRestore = onCleanup(@() i_warning('on'));
try
    slupdate(sModel, 0);
catch oEx
    i_warning('TU:MODEL_ADAPT:ERROR_SL_UPDATE', 'Error upgrading Simulink model "%s".\n\n%s', ...
        sModel, i_getErrorStackAndMessage(oEx));
end
end


%% i_fixSimulinkTypes
function i_fixSimulinkTypes(hModel)
if isempty(which('slRemoveDataTypeAndScale'))
    return;
end

[astFixed, astManual] = slRemoveDataTypeAndScale(hModel, 1); %#ok<ASGLU>
for i = 1:length(astManual)
    stData = astManual(i);
    
    ccFound = ...
        regexp(stData.OldDTStr, 'slDataTypeAndScale\(\(''([^'']+)', 'tokens');
    if isempty(ccFound)
        continue;
    end
    
    sNewParamStr = ccFound{1}{1};    
    set_param(stData.BlockName, stData.ParamName, sNewParamStr);
end
end


%%
function i_warning(varargin)
persistent stState;

if (nargin == 1)
    sCmd = lower(varargin{1});
    switch sCmd
        case 'on'
            if ~isempty(stState)
                warning(stState)
                stState = [];
            end
            
        case 'off'
            if isempty(stState)
                stState = warning('off', 'all');
            end
            
        otherwise
            error('TU:MODEL_ADAPT:INTERNAL_ERROR', ...
                'Unknown command "%s".', sCmd);
    end
else
    % check if official warnings are currently switched off
    % if yes --> use fprintf
    if isempty(stState)
        warning(varargin{:});
    else
        fprintf(['%s\n', varargin{2}, '\n\n'], varargin{1}, varargin{3:end});
    end
end
end


%%
function bIsInstalled = i_isTargetLinkInstalled()
bIsInstalled = ~isempty(which('dsdd'));
end
