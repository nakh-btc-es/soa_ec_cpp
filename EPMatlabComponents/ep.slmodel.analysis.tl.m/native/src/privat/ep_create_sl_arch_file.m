function ep_create_sl_arch_file(stArgs, stModel, sMaFile)
% SL Use Case: Generates XML-File for the Simulink-Architecture (see simulink_architecture.xsd). 
%
% function ep_create_sl_arch_file(stArgs, stModel, sMaFile)
%
%   INPUT               DESCRIPTION
%     stArgs                (struct)  argument structure with the following data
%       .sSlResultFile      (string)    Path to the Simulink output file.
%       .sAddModelInfo      (string)    SL: full path to the additional info XML for the SL model
%          .xxx             (...)           ...
%       .astSlModules       (string)    SL: additional info for the SL model components
%       .sSlInitScript      (string)    SL: full path to the SL init script (might be empty)
%
%     stModel               (struct)  Model analysis struct produced by ep_model_info_get
%
%     sMaFile               (string)  optional: path to the ModelAnalysis.xml
%                                   
%   OUTPUT              DESCRIPTION
%       -                      -
%

%% internal
%
%   AUTHOR(S):
%     Steffen Kollmann
% $$$COPYRIGHT$$$


%% main
if (nargin > 2)
    if isfield(stModel, 'astSlTypeInfos')
        % TL-SL UseCase
        oTypeInfoMap = i_createTypeInfoMap(stModel.astSlTypeInfos);
    else
        % SL-Only UseCase
        oTypeInfoMap = i_createTypeInfoMap(stModel.astTypeInfos);
    end
    ep_legacy_ma_model_arch_convert(stArgs.xEnv, sMaFile, stArgs.sSlResultFile, stArgs, true, oTypeInfoMap);
else
    %TODO: New way must be implemented 
    error('DEV:ERROR', 'Alternative way not available yet.');
end
end


%%
function oTypeInfoMap = i_createTypeInfoMap(astTypeInfos)
oTypeInfoMap = containers.Map;
for i = 1:length(astTypeInfos)
    oTypeInfoMap(astTypeInfos(i).sType) = astTypeInfos(i);
end
end
