function stResult = ep_sim_debug_model(varargin)
% This function exports a model with the given information to a provided
% location.
%
% function ep_sim_debug_model(varargin)
%
%  INPUT              DESCRIPTION
%   - varargin           ([Key, Value]*)  Key-value pairs with the following 
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%    Key(string):            Meaning of the Value:
%         ExportDir*              Export directory of the M-debug
%                                 environment.
%         DebugVectorFiles*  (cell array)            
%                                 Paths to the debug vector XML Files (see
%                                 DebugVector.xsd)
%         DebugModelFile     (string)         
%                                 Path to the debug model XML File (see
%                                 DebugModel.xsd)
%         ModelName*         (string)     
%                                 Name of the extraction model (without 
%                                 path - assumed to be available in the 
%                                 ExportDir)
%         InitScript         (string)            
%                                 Full file of the initial script file to 
%                                 the original model file. (Might not be
%                                 defined)
%         Paths*    (cell array)  Cell array of strings, which contains
%                                 necessary paths for the extraction model.
%         Mode                   (MIL|SIL|PIL) Simulation kind, (SIL and PIL 
%                                 for TargetLink models. Default: MIL)
%         IsTlModel*   (boolean)  True when model is TargetLink Model.
%         AutomaticStart   
%                      (boolean)  Automatically start of the debug
%                                 environment (Default : false)
%         HiddenMode   
%                      (boolean)  When true, the debug model will just be
%                                 loaded (not open to the user). Option is
%                                 good for automatic test scenarios.
%                                 (Default : false)
%         SelfContainedModel
%                      (boolean)  When true, the debug model is self
%                                 contained. (Default : false)
%         ShowExpectedValues
%                      (boolean)  When true, the debug model will show
%                                 the excepted values (Default : false)
%         EnableTLHook (boolean)  When false, internal TL hooks in the
%                                 extraction model generation will be 
%                                 removed.  (Default : false)
%         MessageFile  (string)   The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%
%         Progress     (object)   Progress object for progress information.
%  OUTPUT            DESCRIPTION
%


%%
stResult = struct( ...
    'sModelFile',  '', ...
    'sInitScript', '');

try
    %% init environment
    xEnv = EPEnvironment();
    
    sMessageFile = [];
    
    %% Parse input arguments
    casValidKeys = {'Mode','ExportDir','MessageFile', ...
        'Progress','DebugVectorFiles','ModelName', 'DebugModelFile', ...
        'InitScript','Paths','IsTlModel','AutomaticStart', ...
        'HiddenMode', 'EnableTLHook', 'SelfContainedModel', ...
        'ShowExpectedValues'};
    stArgs = ep_core_transform_args(varargin, casValidKeys);
    
    ep_sim_argcheck('ExportDir', stArgs, 'obligatory', {'class', 'char'});
    ep_sim_argcheck('ExportDir', stArgs, 'dir');
    ep_sim_argcheck('DebugVectorFiles', stArgs, 'obligatory', {'class', 'cell'});
     
    ep_sim_argcheck('DebugModelFile', stArgs, {'class', 'char'});
    ep_sim_argcheck('DebugModelFile', stArgs, 'file');
    ep_sim_argcheck('DebugModelFile', stArgs, {'xsdvalid', 'DebugModel.xsd'});
    
    ep_sim_argcheck('ModelName', stArgs, 'obligatory', {'class', 'char'});
    ep_sim_argcheck('InitScript', stArgs, {'class', 'char'});
    ep_sim_argcheck('Paths', stArgs, 'obligatory', {'class', 'cell'});
    ep_sim_argcheck('Mode', stArgs, 'obligatory', {'class', 'char'});
    ep_sim_argcheck('Mode', stArgs, {'class', 'char'}, {'keyvalue_i', {'MIL', 'PIL','SIL'}});   
    ep_sim_argcheck('IsTlModel', stArgs, {'class', 'logical'});
    ep_sim_argcheck('AutomaticStart', stArgs, {'class', 'logical'});
    ep_sim_argcheck('HiddenMode', stArgs, {'class', 'logical'});
    ep_sim_argcheck('EnableTLHook', stArgs, {'class', 'logical'});
    ep_sim_argcheck('SelfContainedModel', stArgs, {'class', 'logical'});
    ep_sim_argcheck('ShowExpectedValues', stArgs, {'class', 'logical'});
    ep_sim_argcheck('MessageFile', stArgs, {'class', 'char'});
    ep_sim_argcheck('Progress', stArgs, {'class','ep.core.ipc.matlab.server.progress.Progress'});
    
    
    sExportDir = stArgs.ExportDir;
    casVectorFiles = stArgs.DebugVectorFiles;
    nLength = length(casVectorFiles);
    
    for i = 1:nLength
        sVectorFile = casVectorFiles{i};
        stArg = struct('VectorFile', sVectorFile);
        ep_sim_argcheck('VectorFile', stArg, {'class', 'char'});
        ep_sim_argcheck('VectorFile', stArg, 'file');
        ep_sim_argcheck('VectorFile', stArg, {'xsdvalid', 'DebugVector.xsd'});  
    end
    
    sModelName = stArgs.ModelName;
    sInitScript = [];
    sDebugModelFile = [];
     if (isfield(stArgs, 'DebugModelFile'))
        sDebugModelFile = stArgs.DebugModelFile;
    end
    if (isfield(stArgs, 'InitScript'))
        sInitScript = stArgs.InitScript;
    end
    casPaths = stArgs.Paths;
    sMode = 'MIL';
    if (isfield(stArgs, 'Mode'))
        sMode = stArgs.Mode;
    end
    bSilMode = strcmp(sMode,'SIL');
    bIsTlModel = stArgs.IsTlModel;
    
    bAutomaticStart = false;
    if( isfield( stArgs, 'AutomaticStart' ) )
        bAutomaticStart = stArgs.AutomaticStart;
    end
    
    bEnableTLHook = false;
    if( isfield( stArgs, 'EnableTLHook' ) )
        bEnableTLHook = stArgs.EnableTLHook;
    end
    
    bHiddenMode = false;
    if( isfield( stArgs, 'HiddenMode' ) )
        bHiddenMode = stArgs.HiddenMode;
    end
    
    bSelfContainedModel = false;
    if( isfield( stArgs, 'SelfContainedModel' ) )
        bSelfContainedModel = stArgs.SelfContainedModel;
    end
    
    bShowExpectedValues = false;
    if( isfield( stArgs, 'ShowExpectedValues' ) )
        bShowExpectedValues = stArgs.ShowExpectedValues;
    end
    
    if (isfield(stArgs, 'MessageFile'))
        sMessageFile = stArgs.MessageFile;
    end   
    hProgress = [];
    if( isfield( stArgs, 'Progress' ) )
        hProgress =stArgs.Progress;
        xEnv.attachProgress(stArgs.Progress);
    end
    
    tic;
    [~, sName] = fileparts(sModelName);
    sStartScript = [sName, '_debug_start.m'];
    
     
    nLength = length(casVectorFiles);
    for i = 1:nLength
        sVectorFile = casVectorFiles{i};
        astNames(i) = ep_simenv_debug_vector(xEnv, sVectorFile, sExportDir);
    end
    
    stEnv = ep_core_legacy_env_get(xEnv, false);
    
    % PORM-14736 (try to close model with the same name
    % debug model was open already
    try
        evalin('base',sprintf('bdclose(''%s'')',sName));
    catch
    end
   
    atgcv_mdebugenv_create(stEnv, sExportDir, sModelName, ...
        astNames, sStartScript, sInitScript, casPaths, ...
        bIsTlModel, bSilMode, bSelfContainedModel, bHiddenMode, ...
        bShowExpectedValues, sDebugModelFile, bEnableTLHook, hProgress);
    
    if bAutomaticStart
        cd(sExportDir);
        [~, sStartScriptName] = fileparts(sStartScript);
        eval(sStartScriptName);
    end
    disp('### Debug Model Time :');
    toc;
    
    stResult.sModelFile  = fullfile(sExportDir, sModelName);
    stResult.sInitScript = fullfile(fileparts(stResult.sModelFile), sStartScript);
    
    xEnv.attachMessages(sMessageFile);
    xEnv.exportMessages(sMessageFile);
    xEnv.clear();
    
catch oEx   
    EPEnvironment.cleanAndThrowException(xEnv, oEx, sMessageFile);
end
end

