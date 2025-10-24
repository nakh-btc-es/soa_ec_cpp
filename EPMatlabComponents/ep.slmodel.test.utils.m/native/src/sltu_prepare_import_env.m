function [xOnCleanupDoCleanup, xEnv, sResultDir, stModelData] = sltu_prepare_import_env(sModelName, sModelSuite, sTestRootDir, sEnc)
% Prepare UT environment: create test root directory, upgrade ATS model and copy it into test root directory.
% 
%  [xOnCleanupDoCleanup, xEnv, sResultDir, stModelData] = ...
%                                         sltu_prepare_ats_env(sModelName, sModelSuite, sTestRootDir, sEnc, caxFindArgs)
%
%  INPUT             DESCRIPTION
%  - sModelName                       (String)      Name of the ATS/UT model.
%  - sModelSuite                      (String)      ATS/UT Suite name.
%  - sTestRootDir                     (String)      Full path to test root location. Note: If this directry is not
%                                                   existing yet, it it created here.
%  - sEnc                             (String)      optional: special encoding for the model (e.g. 'Shift_JIS')
%
%  OUTPUT            DESCRIPTION
%  - xOnCleanupDoCleanup              (Obj)         onCleanup object that ensures a proper cleanup is done when UT is
%                                                   finished.
%  - xEnv                             (Obj)         New EPEnvironment object that can be passed on to 
%                                                   lower-level SUT functions.             
%  - sResultDir                       (String)      Fresh directory without content located in TestRootDir.             
%  - stModelData                      (Struct) 
%      .sRootPath                       (String)    Path to the root directory of the model data
%      .sSlModelFile                    (String)    full path to SL Model file
%      .sSlInitScriptFile               (String)    full path to SL Init Script file
%      .sSlAddModelInfoFile             (String)    full path to SL Model Info file
%      .astSubModels                    (Struct)    array of structures with info about sub-models (for EC)
%         .sModelFile                   (String)       model file of the sub-model
%         .sInitScript                  (String)       init script file of the sub-model
%      .sTlModelFile                    (String)    full path to TL Model file
%      .sTlInitScriptFile               (String)    full path to TL Init Script
%      .sEnvFile                        (String)    full path to TL LegacyCode XML
%      .sCodeModel                      (String)    full path to CODE CodeModel XML
%      .bUpgradeSuccess                 (Bool)      true if upgrade was successful, otherwise false
%      .casErrors                       (Strings)   list of errors in case of a failed upgrade
%


%% optional args
if (nargin < 4)
    sEnc = '';
end
% note: for the *import* UTs we do not need any TL codegen because we are doing it anyway
[xOnCleanupDoCleanup, xEnv, sResultDir, stModelData] = ...
     sltu_prepare_ats_env(sModelName, sModelSuite, sTestRootDir, sEnc, {'TlCodegen', false});
end

