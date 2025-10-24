function stModel = ep_model_info_export(stOpt, stModel)
% Export the model info structure to the corresponding backend XML files.
%
% function ep_model_info_export(stOpt, stModel)
%
%   INPUT               DESCRIPTION
%     stOpt               (struct)  structure with options for model analysis
%       .sModelMode       (string)    <'TL'> | 'SL'
%       .sModelAnalysis   (string)    full path to the ModelAnalysis.xml (Legacy way)
%
%       .astTlModules     (string)    TL: additional info for the TL model components
%          .xxx           (...)           ...
%       .sTlInitScript    (string)    TL: full path to the TL init script (might be empty)
%       .sAddModelInfo    (string)    SL: full path to the additional info XML for the SL model
%          .xxx           (...)           ...
%       .astSlModules     (string)    SL: additional info for the SL model components
%       .sSlInitScript    (string)    SL: full path to the SL init script (might be empty)
%
%     stModel             (struct)  model info struct as produced by "ep_model_info_get"
%
%   OUTPUT              DESCRIPTION
%       -                      -
%

%% input
if (~isfield(stOpt, 'sModelMode') || isempty(stOpt.sModelMode))
    stOpt.sModelMode = 'TL';
end

%% main
sModelAnalysis = stOpt.sModelAnalysis;

if isfield(stOpt, 'sAddModelInfo')
    [stModel, sModelAnalysis] = i_reduceModelInfo(stOpt.sAddModelInfo, stModel, sModelAnalysis);
end
ep_create_tl_arch_file(stOpt, stModel, sModelAnalysis);
if ~isempty(stModel.sSlModel)
    ep_create_sl_arch_file(stOpt, stModel, sModelAnalysis);
end
ep_create_ccode_arch_file(stOpt, stModel);
ep_create_mapping_file(stModel, stOpt.sMappingResultFile);
stModel.astConstants = ep_core_eval_hook('ep_hook_constants_mod', stModel.sModelPath, stModel.astConstants);
ep_create_architecture_constraint_files(stOpt, stModel);
end


%%
function [stModel, sModelAnalysis] = i_reduceModelInfo(sAddModelInfo, stModel, sModelAnalysis, bIsTlWorkflow)
if (nargin < 4)
    bIsTlWorkflow = true;
end

if (isempty(sAddModelInfo) || ~exist(sAddModelInfo, 'file'))
    return;
end
[p, f, e] = fileparts(sModelAnalysis);
sModelAnalysisOrig = fullfile(p, [f, '_orig', e]);
copyfile(sModelAnalysis, sModelAnalysisOrig);

stModel = ep_legacy_ma_reduce(stModel, sAddModelInfo, sModelAnalysis, bIsTlWorkflow);
end

