function stArgs = ut_sl_args_get(~, sModelFile, sInitScript, sResultDir, stOverrideArgs)
if (nargin < 5)
    stOverrideArgs = struct();
end

stArgs = struct( ...
    'ResultDir',              sResultDir, ...
    'ModelFile',              sModelFile, ...
    'InitScriptFile',         sInitScript, ...
    'AddModelInfoFile',       '', ...
    'SlArchFile',             fullfile(sResultDir, 'slArch.xml'), ...
    'SlConstrFile',           fullfile(sResultDir, 'slConstr.xml'), ...
    'MessageFile',            fullfile(sResultDir, 'error.xml'), ...
    'ParameterHandling',      'ExplicitParam', ...
    'DSReadWriteObservable',  false, ...
    'TestMode',               'GreyBox');

% TODO: remove when feature is finished
% warning('EP:DEV', 'Using temporaray feature toggles.');
%stArgs.ToggledFeatures = {'ALLOW_ARRAY_OF_BUSES_PORTS'};

[~, stArgs.Model] = fileparts(stArgs.ModelFile);

stArgs = i_mergeStruct(stArgs, stOverrideArgs);
end


%%
function stArgs = i_mergeStruct(stArgs, stOverrideArgs)
casArgNames = fieldnames(stOverrideArgs);
for i = 1:numel(casArgNames)
    sArgName = casArgNames{i};
    
    if isfield(stArgs, sArgName)
        stArgs.(casArgNames{i}) = stOverrideArgs.(casArgNames{i});
    else
        error('UT:ERROR:WRONG_USAGE', 'Argument "%s" does not exist!', sArgName);
    end
end
end