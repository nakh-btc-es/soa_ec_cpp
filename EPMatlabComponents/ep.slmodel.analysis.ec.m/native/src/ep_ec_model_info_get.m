function [stModel, astModules] = ep_ec_model_info_get(xEnv, stArgs)
% Retrieving SL/Code/Mapping info from an EC model.
%
% function [stModel, astModules] = ep_ec_model_info_get(xEnv, stArgs)
%
%   INPUT                              DESCRIPTION
%    xEnv                                   EPEnvironment object
%    stArgs                                 argument  struct with the following fields
%
%    FieldName:            Meaning of the Value:

%    - ModelFile                (string)*   The absolute path to the Simulink model.
%    - InitScriptFile           (string)*   The absolute path to the init script of the Simulink model.
%                                           (can be empty)
%    - AddModelInfoFile         (string)*   Location where the AddModelInfoFile shall be placed.
%    - SlArchFile               (string)*   Location where the SL arch file shall be placed.
%    - SlConstrFile             (string)*   Location where the SL constraints file shall be placed.
%    - MappingFile              (string)*   Location where the Mapping file shall be placed.
%    - ConstantsFile            (string)*   Location where the Constants file shall be placed.
%    - CodeModelFile            (string)*   Location where the CodeModel file shall be placed.
%    - AdaptiveStubcodeXmlFile  (string)*   Location where the StubCode (only for AA models) file shall be placed.
%    - MessageFile              (string)*   Location where the Message file shall be placed.
%    - ParameterHandling        (string)*   The parameter handling, either 'Off' or 'ExplicitParam'.
%    - TestMode                 (string)*   The test mode, either 'BlackBox' or 'GreyBox'.
%    - AddCodeModel             (string)*   ('yes' | 'no')
%                                           ----------------------------------------------------------------------------
%    - DSReadWriteObservable    (boolean)*   If set to true, Data Stores used as both DSRead and DSWrite are used as an 
%                                           output instead of rejecting them.            
%                                           ----------------------------------------------------------------------------
%
%  OUTPUT                              DESCRIPTION
%    stModel                    (struct)    Info about the model
%       .xxx
%    astModules                 (array)     Info (structs) about the modules the model consists of
%       .xxx
%



%%
stArgs = i_evalArgs(stArgs);
[~, bSuccess] = ep_ec_model_info_prepare(xEnv, stArgs);
if ~bSuccess
    error('EP:EC:ANALYSIS_FAILED', 'Analysing the EmbeddedCoder model failed.');
end

[stModel, astModules] = ep_sl_model_info_get(xEnv, stArgs);
ep_ec_post_sl_analysis_adapt(xEnv, stArgs.SlArchFile, stArgs.MappingFile, stArgs.CodeModelFile);
end


%%
function stArgs = i_evalArgs(stArgs)
if ~isfield(stArgs, 'GlobalConfigFolderPath')
    stArgs.GlobalConfigFolderPath = '';
end
if ~isfield(stArgs, 'Model')
    [~, stArgs.Model] = fileparts(stArgs.ModelFile);
end
if ~isfield(stArgs, 'LoadModel')
    stArgs.LoadModel = false;
end
end

