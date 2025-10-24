function ep_sim_close_model(stOpenInfo, varargin)
% This function opens the provided model (this can be a TargetLink or
% Simulink model). When kind of model is not defined a Simulink model is
% assumed (SL)
%
% function ep_sim_close_model(stOpenInfo,varargin)
%
%  INPUT              DESCRIPTION
%   - stOpenInfo           (struct)  result of ep_core_model_open
%       .sModelFile       (string)  save input param for model_close
%       .casModelRefs       (cell)  contains all model references
%       .abIsModelRefOpen   (cell)  TRUE if corresponding ModelRef was already
%                                   open/loaded, FALSE otherwise
%       .caInitScripts (cell array) save input param for model_close
%       .bIsTL           (boolean)  save input param for model_close
%       .bIsModelOpen       (bool)  TRUE if TL-Model is open, FALSE for
%                                   model is loaded
%       .sSearchPath      (string)  enhanced matlab search path or empty
%       .sDdFile          (string)  name of the DD to be reopened
%       .astAddDD          (array)  currently open additional DDs and Workspaces
%           .sFile        (string)  Full path to the DD File
%           .nDDIdx      (numeric)  Id of the DD workspace this DD is loaded in
%   - varargin           ([Key, Value]*)  Key-value pairs with the following 
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%    Key(string):            Meaning of the Value:
%         MessageFile             The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%


%% Parse input arguments and set up environment
try
    %% init environment
    xEnv = EPEnvironment();
    sMessageFile = [];
    
    %% Parse input arguments
    casValidKeys = {'MessageFile'};
    stArgs = ep_core_transform_args(varargin, casValidKeys);
    ep_sim_argcheck('MessageFile', stArgs, {'class', 'char'});
    
    if (isfield(stArgs, 'MessageFile'))
        sMessageFile = stArgs.MessageFile;
    end
    sModelFile = stOpenInfo.sModelFile;
    [sMdlPath, sModelName, sExt] = fileparts(sModelFile); %#ok sExt not used
    casOpenModels = find_system('type', 'block_diagram');
    
    bIsModelOpen = any(strcmpi(sModelName, casOpenModels));
    if bIsModelOpen
        ep_simenv_close(xEnv, sModelFile);
        i_evalPreCloseCallback(sMdlPath, sModelName);
        
        if isfield(stOpenInfo, 'abIsModelRefOpen')
            xContent = getfield(stOpenInfo, 'abIsModelRefOpen'); %#ok
            nLength = length(xContent);
            abContent = logical([]);
            
            for i = 1:nLength
                abContent(i) = xContent{i};
            end
            stOpenInfo = setfield(stOpenInfo, 'abIsModelRefOpen', abContent); %#ok
        end
        
        tic;     
        bIsClosed = ep_core_model_close(xEnv, stOpenInfo);
        
        % execute close hook again as workaround for clearing enums EPDEV-48903
        if bIsClosed
            i_execModelCloseScriptToClearEnums(sMdlPath);
        end
        
        fprintf('### Close Model "%s" Time : \n', sModelName);
        toc;
    end
    xEnv.attachMessages(sMessageFile);
    xEnv.exportMessages(sMessageFile);
    xEnv.clear();
    
catch exception   
    EPEnvironment.cleanAndThrowException(xEnv, exception, sMessageFile);
end
end


%%
function i_execModelCloseScriptToClearEnums(sModelPath)
try
    sModelCloseScript = ep_core_canonical_path(fullfile(sModelPath, 'btc_clear_enums.m'));
    if exist(sModelCloseScript, 'file')
        run(sModelCloseScript);
    end
catch oEx %#ok    
end
end


%%
function i_evalPreCloseCallback(sModelPath, sModelName)
sPreCloseCallback = [sModelName, '_preClose'];
sPreCloseCallbackFile = fullfile(sModelPath, [sPreCloseCallback, '.m']);
if exist(sPreCloseCallbackFile, 'file')
    try
        eval(sPreCloseCallback);
    catch oEx
        warning('EP:PRE_CLOSE_FAILED', '%s', oEx.getReport());
    end
end
end
