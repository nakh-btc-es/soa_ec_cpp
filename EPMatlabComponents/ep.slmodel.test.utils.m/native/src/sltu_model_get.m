function [stTestData, bUpgradeSuccess] = sltu_model_get(sModelName, sModelSuite, bUpgrade)
% This function returns models for testing. An upgrade to the current ML version is implicitly done if not requested otherwise.
%
% function stTestData = sltu_model_get(sModelName, sModelSuite, bUpgrade)
%
%  INPUT                          DESCRIPTION
%  - sModelName                     (String)    Name of the model 
%                                               Note: Use the enumeration 'RegisteredModels' of the corresponding 
%                                               Model Suite 'toString()'.
%
%  - sModelSuite                    (String)    Name of the model suite where the desired model is located.
%                                               Note: Use the MODEL_SUITE_ID of the corresponding Model Suite.
%
%  - bUpgrade                       (boolean)   optional: If true, permits an automatic model upgrade (default == true).
%
%  OUTPUT            DESCRIPTION
%  - stTestData             
%      .sTestDataPath               (String)    Path to the test data
%      .sSlModel                    (String)    SL Model file name with extension
%      .sSlInitScript               (String)    SL Init Script file name with extension
%      .sTlModel                    (String)    TL Model file name with extension
%      .sTlInitScript               (String)    TL Init Script file name with extension
%      .sSlAddModelInfo             (String)    SL Model Info file name with extension
%      .sEnvFile                    (String)    Environment XML file with extension
%      .sCodeModel                  (String)    Code Model XML file
%
%      .sModelKey                   (String)    the Model enumeration as string
%      .sModelSuite                 (String)    the suite this model was retrieved from
%  - bUpgradeSuccess                (Bool)      Flag to indicate the success of the optional upgrade process
%
%



%%
if (nargin < 3)
    bUpgrade = true;
end
if bUpgrade
    sUpgrade = 'yes';
else
    sUpgrade = 'no';
end

stModelData = sltu_ut_model_find('ModelName', sModelName, 'ModelSuite', sModelSuite, 'Upgrade', sUpgrade);


stTestData = struct( ...
    'sTestDataPath',   stModelData.sRootPath, ...
    'sSlModel',        i_getRelFilePath(stModelData.sSlModelFile, stModelData.sRootPath), ...
    'sSlInitScript',   i_getRelFilePath(stModelData.sSlInitScriptFile, stModelData.sRootPath), ...
    'sTlModel',        i_getRelFilePath(stModelData.sTlModelFile, stModelData.sRootPath), ...
    'sTlInitScript',   i_getRelFilePath(stModelData.sTlInitScriptFile, stModelData.sRootPath), ...
    'sSlAddModelInfo', i_getRelFilePath(stModelData.sSlAddModelInfoFile, stModelData.sRootPath), ...
    'sEnvFile',        i_getRelFilePath(stModelData.sEnvFile, stModelData.sRootPath), ...
    'sCodeModel',      i_getRelFilePath(stModelData.sCodeModel, stModelData.sRootPath), ...
    'sModelKey',       sModelName, ...
    'sModelSuite',     sModelSuite);
bUpgradeSuccess = stModelData.bUpgradeSuccess;
end


%%
function sRelPath = i_getRelFilePath(sFullFile, sRootDir)
if ~isempty(sFullFile)
    sRelPath = sltu_file_path_relativize(sFullFile, sRootDir);
else
    sRelPath = '';
end
end



