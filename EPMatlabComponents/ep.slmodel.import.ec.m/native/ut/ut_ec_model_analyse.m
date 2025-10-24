function [stResult, oEx] = ut_ec_model_analyse(sModelFile, sInitScript, sResultDir, varargin)
caxTestArgs = i_evalArgs(sModelFile, sInitScript, varargin{:});
caxAnalysisArgs = ep_ec_args_default(sResultDir, caxTestArgs{:});
try
    [~, ~, stResult] = ep_ec_model_analyze(caxAnalysisArgs{:});
catch oEx
    if (nargout < 2)
        rethrow(oEx);
    end
    
    stEcArgs = ep_ec_args_eval(caxAnalysisArgs{:});
    stResult = struct();
    stResult.sSlInitScript = stEcArgs.InitScriptFile;
    stResult.sResultDir = stEcArgs.ResultDir;
    stResult.sMessageFile = stEcArgs.MessageFile;
    stResult.sParameterHandling = stEcArgs.ParameterHandling;
    stResult.sTestMode = stEcArgs.TestMode;
    stResult.bAddCodeModel = stEcArgs.AddCodeModel;
    
    stResult.stModel        = []; 
    stResult.astModules     = [];
    stResult.sCodeModel     = stEcArgs.CodeModelFile;
    stResult.sMappingFile   = stEcArgs.MappingFile;
    stResult.sSlArchFile    = stEcArgs.SlArchFile;
    stResult.sSlConstrFile  = stEcArgs.SlConstrFile;
    stResult.sAddModelInfo  = stEcArgs.AddModelInfoFile;
    stResult.sCompilerFile  = stEcArgs.CompilerFile;
end
end


%%
function caxArgs = i_evalArgs(sModelFile, sInitScript, varargin)
stArgs = struct( ...
    'ModelFile',            sModelFile, ...
    'InitScriptFile',       sInitScript, ...
    'ParameterHandling',    'ExplicitParam', ...
    'TestMode',             'GreyBox', ...
    'AddCodeModel',         'yes');

if (nargin > 2)
    stAddArgs = ep_core_transform_args(varargin);
    stArgs = i_combineStructs(stArgs, stAddArgs);
end
caxArgs = reshape([fieldnames(stArgs), struct2cell(stArgs)]', 1, []);
end


%%
function stStruct = i_combineStructs(stStruct, stAddStruct)
casAddFields = fieldnames(stAddStruct);
for i = 1:numel(casAddFields)
    sField = casAddFields{i};
    
    stStruct.(sField) = stAddStruct.(sField);
end
end
