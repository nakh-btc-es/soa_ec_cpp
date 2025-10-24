function stOpenInfo = ep_sim_open_model(varargin)
% This function opens the provided model (this can be a TargetLink or
% Simulink model). When kind of model is not defined a Simulink model is
% assumed (SL)
%
% function stOpenInfo = ep_sim_open_model(varargin)
%
%  INPUT              DESCRIPTION
%  -varargin           ([Key, Value]*)  Key-value pairs with the following 
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%
%    Key(string):            Meaning of the Value:
%         Kind                    (TL|SL) kind of model, (TL for TargetLink 
%                                 Model, SL for Simulink Model, default: SL)
%         ModelFile*              Path to the TargetLink/Simulink model file (.mdl|.slx).
%
%         InitScripts   (cell)    Cell array of all init scripts (full path)
%                                 A script defining all parameters needed 
%                                 for initializing the TL/SL-model. 
%                                 If not provided, the TL/SL-model is
%                                 assumed to be selfcontained. 
%         AddPaths     (cell)     optional: cell array of string with paths
%                                 that are needed for initialization of model
%         InitModel    (boolean)  optional: check model initialization,
%                                 default: false
%         ActivateMil  (boolean)  TRUE if MIL mode should be activated
%                                 permanently (default: true) (TargetLink
%                                 Option, Kind = TL)
%         MessageFile             The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%
%         Progress     (object)   Progress object for progress information.
%  OUTPUT            DESCRIPTION
%  - stOpenInfo           (Struct)  Information about the open operation
%                                  (important later for closing the model)
%       .sModelFile       (string)  save input param for model_close
%       .casModelRefs       (cell)  contains all model references
%       .abIsModelRefOpen   (cell)  TRUE if corresponding ModelRef was already
%                                   open/loaded, FALSE otherwise
%       .caInitScripts      (cell)  save input param for model_close
%       .bIsTL           (boolean)  save input param for model_close
%       .bIsModelOpen       (bool)  TRUE if model was already open/loaded,
%                                   FALSE if model had to be loaded
%       .sSearchPath      (string)  enhanced matlab search path or empty
%       .sDdFile          (string)  currently open DD File
%       .astAddDD          (array)  currently open additional DDs and Workspaces
%           .sFile        (string)  Full path to the DD File
%           .nDDIdx      (numeric)  Id of the DD workspace this DD is loaded in
%       .sActiveVariant   (string)  currently active DataVariant in DD


%% Parse input arguments and set up environment
try
    % Init variables
    xEnv = EPEnvironment();
    sMessageFile = [];
    stOpenInfo = []; 
    stParam = [];
    

    %% Parse input arguments
    casValidKeys = {'Kind','ModelFile', 'InitScripts', 'AddPaths',...
        'ActivateMil', 'InitModel', 'MessageFile', 'Progress'};
    stArgs = ep_core_transform_args(varargin, casValidKeys);
     
    ep_sim_argcheck('MessageFile', stArgs, {'class', 'char'});
    
    if (isfield(stArgs, 'MessageFile'))
        sMessageFile = stArgs.MessageFile;
    end
    
    ep_sim_argcheck('Kind', stArgs, {'class', 'char'}, ...
        {'keyvalue_i', {'SL', 'TL'}});
    ep_sim_argcheck('ModelFile', stArgs, 'obligatory', {'class', 'char'});
    ep_sim_argcheck('ModelFile', stArgs, 'file');
    ep_sim_argcheck('InitScripts', stArgs, {'class', 'cell'});
    ep_sim_argcheck('AddPaths', stArgs, {'class', 'cell'});
    ep_sim_argcheck('InitModel', stArgs, {'class', 'logical'});
    ep_sim_argcheck('ActivateMil', stArgs, {'class', 'logical'});
    ep_sim_argcheck('Progress', stArgs, {'class','ep.core.ipc.matlab.server.progress.Progress'});
    
    sKind = 'SL';
    if (isfield(stArgs, 'Kind'))
        sKind = stArgs.Kind;
    end
    
    sModelFile = '';
    if (isfield(stArgs, 'ModelFile'))
        sModelFile = stArgs.ModelFile;
    end
    
    casInitScript = {};
    if (isfield(stArgs, 'InitScripts'))
        casInitScript = stArgs.InitScripts;
    end
    
    casAddPaths = {};
    if (isfield(stArgs, 'AddPaths'))
        casAddPaths = stArgs.AddPaths;
    end
    
    bInitModel = false;
    if (isfield(stArgs, 'InitModel'))
        bInitModel = stArgs.InitModel;
    end
    
    bActivateMil = true;
    if (isfield(stArgs, 'ActivateMil'))
        bActivateMil = stArgs.ActivateMil;
    end 
    
    if( isfield( stArgs, 'Progress' ) )
        xEnv.attachProgress(stArgs.Progress);
    end
    
    
    bIsTL = strcmpi(sKind, 'TL');
    
    %% init environment    
    xEnv.setProgress(5, 100, 'Open Model');
    stParam.sModelFile = sModelFile;
    stParam.caInitScripts = casInitScript;
    stParam.bIsTL = bIsTL;
    stParam.bCheck = bInitModel;
    stParam.casAddPaths = casAddPaths;
    stParam.bActivateMil = bActivateMil;
    
    % open the model 
    tic;
    sPwd = pwd;
    [sModelPath, sModelName] = fileparts(sModelFile);
    cd(sModelPath);
    stOpenInfo = ep_core_model_open(xEnv, stParam);
    i_evalPostOpenCallback(sModelPath, sModelName);
    
    cd(sPwd);
    sMessage = sprintf('### Open Model "%s" Time :', sModelName);
    disp(sMessage);
    toc;
        
    if isfield(stOpenInfo, 'abIsModelRefOpen')
        xContent = stOpenInfo.abIsModelRefOpen';
        cellXContent = num2cell(xContent);
        stOpenInfo.abIsModelRefOpen = cellXContent;
    end
       
    xEnv.setProgress(100, 100, 'Open Model');
    xEnv.attachMessages(sMessageFile);
    xEnv.exportMessages(sMessageFile);
    xEnv.clear();
    
catch exception   
    EPEnvironment.cleanAndThrowException(xEnv, exception, sMessageFile);
end
end


%%
function i_evalPostOpenCallback(sModelPath, sModelName)
sPostOpenCallback = [sModelName, '_postOpen'];
sPostOpenCallbackFile = fullfile(sModelPath, [sPostOpenCallback, '.m']);
if exist(sPostOpenCallbackFile, 'file')
    try
        eval(sPostOpenCallback);
    catch oEx
        warning('EP:POST_OPEN_FAILED', '%s', oEx.getReport());
    end
end
end
