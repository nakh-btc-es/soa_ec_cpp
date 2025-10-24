function [stModel, astModules] = ep_sl_model_info_get(xEnv, stArgs)
% Analyse SL model and export all architecture/constraint files.
%
% function [stModel, astModules] = ep_sl_model_info_get(xEnv, stArgs)
%
%   INPUT               DESCRIPTION
%   xEnv                        (class)     Environment object keeping information on environment
%   stArgs                      (struct)    Struct keeping various key/value pairs (as seen below)
%    - ModelFile                (string)*   The absolute path to the Simulink model.
%    - InitScriptFile           (string)*   The absolute path to the init script of the Simulink model. (can be empty)
%    - AddModelInfoFile         (string)    The absolute path to additional model information.
%                                           The format is described by the AddModelInfo.dtd.
%
%    - FixedStepSolver          (string)    'yes' | 'no'
%                                           Handling when a non-fixed-step solver is ecountered: If 'yes', the solver
%                                           is automatically set to fixed-step. Otherwise an error is issued.
%                                           (default == 'no')
%    - ParamSearchFunc          (handle)    ... TODO overrides ParameterHandling ...
%    - ParameterHandling        (string)    'Off' | 'ExplicitParam'
%                                           Shall parameters be taken into account. (default == 'ExplicitParam')
%    - TestMode                 (string)    'BlackBox' | 'GreyBox'
%                                           Shall locals be taken into account. (default == 'GreyBox')
%    - SlArchFile               (string)*   Location where the SL architecture file shall be placed.
%    - SlConstrFile             (string)*   Location where the SL constraint file shall be placed.
%    - CompilerFile             (string)*   Location where the Compiler file shall be placed.
%    - MessageFile              (string)*   Location where the Message file shall be placed.
%    - Progress                 (object)    Object for tracking progress, e.g. UI workflow.
%    - DSReadWriteObservable   (boolean)    if set Data Stores with both
%                                           read/write access within a certain scope are treated as observable
%                                           Writers instead of being rejected
%

%% main
astModules = ep_arch_get_model_modules(stArgs.Model);
stModel = ep_sl_model_info_prepare(xEnv, stArgs);

stModelEnh = ep_sl_model_info_enhance(xEnv, stModel, stArgs.DSReadWriteObservable);
stModelEnh = i_validateAndAdapt(xEnv, stModelEnh);
if isfield(stArgs, 'SlConstrFile')
    ep_sl_model_constraints_export(stModelEnh, stArgs.SlConstrFile);
end

stArchInfo = struct( ...
    'sAddModelInfoFile',  stArgs.AddModelInfoFile, ... 
    'sInitScriptFile',    stArgs.InitScriptFile, ... 
    'stModel',            stModelEnh, ...
    'astModules',         astModules);

stModel.astSubsystems = stModelEnh.astSubsystems;
stModel.astParams = i_filterRelevantParams(stModel);
ep_sl_arch_info_export(xEnv, stArchInfo, stArgs.SlArchFile);     
end


%%
function stModel = i_validateAndAdapt(xEnv, stModel)
aiUnsupportedSlFunctionIdx = i_findUnsupportedSlFunctions(stModel.astSlFunctions);
if isempty(aiUnsupportedSlFunctionIdx)
    
    return;
end

abIsSubSupported = true(size(stModel.astSubsystems));
for i = 1:numel(stModel.astSubsystems)
    stSub = stModel.astSubsystems(i);
    
    if ~isempty(stSub.astSlFuncRefs)
        aiUsedUnsupportedFuncIdx = intersect(aiUnsupportedSlFunctionIdx, [stSub.astSlFuncRefs.iVarIdx]);
        if ~isempty(aiUsedUnsupportedFuncIdx)
            % use the unsupported SL Func for message
            stUnsupportedSlFunc = stModel.astSlFunctions(aiUsedUnsupportedFuncIdx(1)); 
            slFunctionPaths = stUnsupportedSlFunc.sPath;
            for j = 2:numel(aiUsedUnsupportedFuncIdx)
                stUnsupportedSlFunc = stModel.astSlFunctions(aiUsedUnsupportedFuncIdx(j));
                slFunctionPaths = [slFunctionPaths '; ' stUnsupportedSlFunc.sPath]; %#ok<AGROW>
            end
            xEnv.addMessage('ATGCV:MOD_ANA:UNSUPPORTED_SL_FUNCTION_ACCESS', ...
                'subsystemName', stSub.sPath, ...
                'slFunction',    slFunctionPaths);
            
            abIsSubSupported(i) = false;
        end
    end
end

stModel.astSubsystems = ep_sl_subsystems_filter(stModel.astSubsystems, abIsSubSupported);
end


%%
function aiUnsupportedSlFunctionIdx = i_findUnsupportedSlFunctions(astSlFunctions)
if isempty(astSlFunctions)
    aiUnsupportedSlFunctionIdx = [];
else
    abIsSupported = arrayfun(@i_isSlFuncSupported, astSlFunctions);
    aiUnsupportedSlFunctionIdx = find(~abIsSupported);
end
end


%%
function bIsSupported = i_isSlFuncSupported(stSlFunc)
bIsSupported = (stSlFunc.nInports) < 1 && (stSlFunc.nOutports < 1);
end

%%
function astRelevantParams = i_filterRelevantParams(stModel)
astAllParamRefs = [stModel.astSubsystems(:).astParamRefs];

if isempty(astAllParamRefs)
    astRelevantParams = [];
else
    aiIndexes = unique([astAllParamRefs(:).iVarIdx]);
    astRelevantParams = stModel.astParams(aiIndexes);
end
end