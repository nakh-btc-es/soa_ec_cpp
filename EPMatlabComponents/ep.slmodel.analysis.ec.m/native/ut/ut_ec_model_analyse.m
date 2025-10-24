function stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs)
if (nargin < 5)
    stOverrideArgs = struct();
end

sModel = i_getRelevantModelName(sModelFile);
stOrigSettings = i_getConfigSettings(sModel);

oEx = [];
stArgs = ut_get_ec_args(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);
try
    [stModel, astModules] = ep_ec_model_info_get(xEnv, stArgs);
catch oEx
    stModel = [];
    astModules = [];
end
xEnv.exportMessages(stArgs.MessageFile);

stPostSettings = i_getConfigSettings(sModel);
SLTU_ASSERT_EQUAL_STRUCT(stOrigSettings, stPostSettings);


% --- result ----------
stResult = struct( ...
    'bSuccess',          isempty(oEx), ...
    'oException',        oEx, ...
    'sAddModelInfo',     stArgs.AddModelInfoFile, ...
    'sSlArch',           stArgs.SlArchFile, ...
    'sSlConstr',         stArgs.SlConstrFile, ...
    'sMapping',          stArgs.MappingFile, ...
    'sConstantsFile',    stArgs.ConstantsFile, ...
    'sCodeModel',        stArgs.CodeModelFile, ...
    'sStubAA',           stArgs.AdaptiveStubcodeXmlFile, ...
    'sMessages',         stArgs.MessageFile, ...
    'stModel',           stModel, ...
    'astModules',        astModules);

% -- cleanup -----
coder.report.close; % to avoid keeping open the annoying EC codegen reports
end


%%
% try to find the model for which C-code is generated 
% note: for the AUTOSAR-Wrapper workflow it's the referenced AUTOSAR model
function sModel = i_getRelevantModelName(sModelFile)
[~, sModel] = fileparts(sModelFile);
[bIsWrapper, sOrigModel] = i_checkForAutosarWrapperModel(sModel);
if bIsWrapper
    sModel = sOrigModel;
end
end


%%
function [bIsWrapper, sOrigModel] = i_checkForAutosarWrapperModel(sModel)
bIsWrapper = false;
sOrigModel = sModel;

casWrapperSys = find_system(sModel, ...
    'SearchDepth', 1, ...
    'BlockType', 'SubSystem', ...
    'Tag', ep_ec_tag_get('Autosar Wrapper Model'));
if isempty(casWrapperSys)
    return;
end
bIsWrapper = true;

casModelBlocks = find_system(casWrapperSys{1}, ...
    'searchdepth', 1, ...
    'BlockType', 'ModelReference');
if (numel(casModelBlocks) > 1)
    casModelBlocks = find_system(casWrapperSys{1}, ...
        'searchdepth', 1, ...
        'BlockType', 'ModelReference', ...
        'Tag', ep_ec_tag_get('Autosar Main ModelRef'));
end
if isempty(casModelBlocks)
    return;
end

sOrigModel = get_param(casModelBlocks{1}, 'ModelName');
end


%%
function stSettings = i_getConfigSettings(sModel)
stSettings = struct( ...
    'bIsReference',          false, ...
    'casConfigSets',         {getConfigSets(sModel)}, ...
    'Name',                  '', ...
    'PostCodeGenCommand',    '', ...
    'GenerateSampleERTMain', '');
oConfigSet = getActiveConfigSet(sModel);
if ~isempty(oConfigSet)
    if isa(oConfigSet, 'Simulink.ConfigSetRef')
        oConfigSet = oConfigSet.getRefConfigSet;
        stSettings.bIsReference = true;
    end
end
if isempty(oConfigSet)
    return;
end

stSettings.Name = get_param(oConfigSet, 'Name');
stSettings.PostCodeGenCommand = get_param(oConfigSet, 'PostCodeGenCommand');
stSettings.GenerateSampleERTMain = get_param(oConfigSet, 'GenerateSampleERTMain');
end
