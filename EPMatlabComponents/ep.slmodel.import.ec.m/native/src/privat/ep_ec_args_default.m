function caxArgs = ep_ec_args_default(sResultDir, varargin)
% Define some default values to make debugging and testing easier.


%%
if ((nargin < 1) || isempty(sResultDir))
    sResultDir = i_createLocalResultDir();
end


%%
casValidKeys = ep_ec_args_eval();

stArgs = ep_core_transform_args(varargin, casValidKeys);

% model file
if ~isfield(stArgs, 'ModelFile')
    stArgs.ModelFile = i_getModelFileOfCurrentModel();
end

stDefaultArgs = struct( ...
    'CompilerFile',             fullfile(sResultDir, 'compiler.xml'), ...
    'AddModelInfoFile',         fullfile(sResultDir, 'AddModelInfo.xml'), ...
    'MappingFile',              fullfile(sResultDir, 'mapping.xml'), ...
    'CodeModelFile',            fullfile(sResultDir, 'CodeModel.xml'), ...
    'SlArchFile',               fullfile(sResultDir, 'slArch.xml'), ...
    'SlConstrFile',             fullfile(sResultDir, 'slConstr.xml'), ...
    'ConstantsFile',            fullfile(sResultDir, 'ecConstants.xml'), ...
    'DSReadWriteObservable',    false, ...
    'MessageFile',              fullfile(sResultDir, 'error.xml'));

stArgs = i_mergeStructs(stArgs, stDefaultArgs);
caxArgs = reshape([fieldnames(stArgs), struct2cell(stArgs)]', 1, []);
end


%%
function sModelFile = i_getModelFileOfCurrentModel()
sModelFile = '';
sGcs = gcs;
if ~isempty(sGcs)
    sModel = bdroot(sGcs);
    sModelFile = get_param(sModel, 'FileName');
end
end


%%
function sResultDir = i_createLocalResultDir()
sResultDir = fullfile(pwd, 'results_ec_analysis');
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
end
mkdir(sResultDir);
end


%%
function stStruct = i_mergeStructs(stStruct, stAddStruct)
casAddFields = fieldnames(stAddStruct);
for i = 1:numel(casAddFields)
    sField = casAddFields{i};
    
    if ~isfield(stStruct, sField)
        stStruct.(sField) = stAddStruct.(sField);
    end
end
end


