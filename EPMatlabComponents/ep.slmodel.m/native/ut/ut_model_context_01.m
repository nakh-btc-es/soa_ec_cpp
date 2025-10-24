function ut_model_context_01
% First test dummy for EPModelContext.
%
%   ...


%% prepare
sModelFile = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata', 'tiny', 'tiny.mdl');

[hModel, xOnCleanupCloseModel] = i_copyAndLoadModel(sModelFile); %#ok onCleanup object
hSub = i_findSubsystem(hModel, 'top_A');

%% test
oMcModel = EPModelContext.get(hModel);
MU_ASSERT_TRUE(oMcModel.isValid(), 'Model context for model handle shall be valid.');


%%
sVarName = i_getRandomName();
[xVar, nScope] = oMcModel.getVariable(sVarName);
MU_ASSERT_TRUE(isequal(nScope, 0), 'Variable shall not be there.');
MU_ASSERT_TRUE(isempty(xVar), 'Variable shall not be there.');

%%
% create the variable inside the base workspace
iValue = int8(3);
oMcModel.evalinGlobal(sprintf('%s=int8(%d);', sVarName, iValue));

[iFoundValue, nScope] = oMcModel.getVariable(sVarName);
MU_ASSERT_TRUE(isequal(nScope, 1), 'Variable shall be in global scope.');
MU_ASSERT_TRUE(isequal(iFoundValue, iValue), ...
    'Unexpected value for created variable in base workspace.');
MU_ASSERT_TRUE(isequal(class(iFoundValue), class(iValue)), ...
    'Unexpected class for created variable in base workspace.');


%%
% create a shadowing variable in model workspace
iOtherValue = uint16(7);
oMcModel.evalinLocal(sprintf('%s=uint16(%d);', sVarName, iOtherValue));

[iFoundValue, nScope] = oMcModel.getVariable(sVarName);
MU_ASSERT_TRUE(isequal(nScope, 2), 'Variable shall be in model scope.');
MU_ASSERT_TRUE(isequal(iFoundValue, iOtherValue), ...
    'Unexpected value for shadowing variable in model workspace.');
MU_ASSERT_TRUE(isequal(class(iFoundValue), class(iOtherValue)), ...
    'Unexpected class for shadowing variable in model workspace.');


%%
% try to do the same via the model context of the Subsystem
oMcBlock = EPModelContext.get(hSub);
MU_ASSERT_TRUE(oMcBlock.isValid(), 'Model context for block (Subsystem) handle shall be valid.');

[iFoundValue, nScope] = oMcModel.getVariable(sVarName);
MU_ASSERT_TRUE(isequal(nScope, 2), 'Variable shall be in model scope.');
MU_ASSERT_TRUE(isequal(iFoundValue, iOtherValue), ...
    'Context Subsystem: Unexpected value for shadowing variable in model workspace.');
MU_ASSERT_TRUE(isequal(class(iFoundValue), class(iOtherValue)), ...
    'Context Subsystem: Unexpected class for shadowing variable in model workspace.');

%%
% remove the variable from model workspace
oMcBlock.evalinLocal(sprintf('clear %s', sVarName));

[iFoundValue, nScope] = oMcBlock.getVariable(sVarName);
MU_ASSERT_TRUE(isequal(nScope, 1), 'Variable shall be in global scope.');
MU_ASSERT_TRUE(isequal(iFoundValue, iValue), ...
    'Unexpected value for created variable in base workspace.');
MU_ASSERT_TRUE(isequal(class(iFoundValue), class(iValue)), ...
    'Unexpected class for created variable in base workspace.');

%%
% remove the variable also from base workspace
oMcBlock.evalinGlobal(sprintf('clear %s', sVarName));

[xVar, nScope] = oMcBlock.getVariable(sVarName);
MU_ASSERT_TRUE(isequal(nScope, 0), 'Variable shall not be there.');
MU_ASSERT_TRUE(isempty(xVar), 'Variable shall not be there.');
end




%%
function [hModel, xOnCleanupCloseModel] = i_copyAndLoadModel(sModelFile)
[sDataDir, sModelName, sExt] = fileparts(sModelFile);
sTmpDir = fullfile(pwd, ['tmp', datestr(now, 'MMSSFFF')]);
copyfile(sDataDir, sTmpDir);

hModel = load_system(fullfile(sTmpDir, [sModelName, sExt]));

xOnCleanupCloseModel = onCleanup(@() i_closeModelAndRmdir(hModel, sTmpDir));
end


%%
function sName = i_getRandomName()
[~, sName] = fileparts(tempname());
end


%%
function i_closeModelAndRmdir(hModel, sDir)
try
    close_system(hModel);
    rmdir(sDir, 's');
catch
end
bdclose all;
end


%%
function hSub = i_findSubsystem(hModel, sName)
hSub = find_system(hModel, 'Name', sName, 'BlockType', 'SubSystem');
end
