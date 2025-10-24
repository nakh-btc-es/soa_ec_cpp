function ep_create_tl_arch_file(stArgs, stModel, sMaFile)
% TL Use Case: Generates XML-File for the Targetlink-Architecture (see targetlink_architecture.xsd). 
%
% function ep_create_tl_arch_file(stArgs, stModel, sMaFile)
%
%   INPUT               DESCRIPTION
%     stArgs                (struct)  argument structure with the following data
%       .sTlResultFile      (string)    Path to the TargetLink output file.
%       .astTlModules       (string)      TL: additional info for the TL model components
%          .xxx             (...)             ...
%       .sTlInitScript      (string)      TL: full path to the TL init script (might be empty)
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
%%

%% main
if (nargin > 2)
    oTypeInfoMap = i_createTypeInfoMap(stModel.astTypeInfos);
    ep_legacy_ma_model_arch_convert(stArgs.xEnv, sMaFile, stArgs.sTlResultFile, stArgs, false, oTypeInfoMap);
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

