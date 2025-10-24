function [mHandledModelRefs, casNewModelRefFiles] = ep_model_references_replace(hSub, mKnownModelRefs, sPostFix, sTargetDir)
% This function replaces model references with copies on the toplevel of a given model or subsystem.
%
% function [mHandledModelRefs, casNewModelRefFiles] = ...
%                                   ep_model_references_replace(hSub, mKnownModelRefs, sPostFix, sTargetDir)
%
%  INPUT                DESCRIPTION
%  hSub                 (handle)        Handle of the subsystem/model to be resolved.
%  mKnownModelRefs      (map)           Map containing already copied model references.
%  sPostFix             (string)        Unique name section to be added to copied model references.
%  sTargetDir           (string)        Target directory where copied model references will be put.
%
%  OUTPUT               DESCRIPTION
%  mHandledModelRefs    (map)           A map containing all copied model references. Includes those in mKnownModelRefs.
%  casNewModelRefFiles  (cell-array)    A cell array containing all full filenames of now new copied models.


%%
ahAllModelRefs = ep_find_system(hSub,...
    'LookUnderMasks', 'on', ...
    'FollowLinks',    'off', ...
    'BlockType',      'ModelReference');
iModelRefs = numel(ahAllModelRefs);
casMdlNames = cell(1, iModelRefs);
casMdlRefBlockPaths = cell(1, iModelRefs);
abSelect = false(1, iModelRefs);

for i=1:iModelRefs
    if strcmp(get_param(ahAllModelRefs(i), 'ProtectedModel'), 'off')
        abSelect(i) = true;
        casMdlNames{i} = get_param(ahAllModelRefs(i), 'ModelName');
        casMdlRefBlockPaths{i} = getfullname(ahAllModelRefs(i));
    end
end

casMdlNames = casMdlNames(abSelect);
casMdlRefBlockPaths = casMdlRefBlockPaths(abSelect);

[mHandledModelRefs, casNewModelRefFiles] = i_copyToplevelMdlRefs(casMdlNames, mKnownModelRefs, sPostFix, sTargetDir);

for i = 1:numel(casMdlRefBlockPaths)
    i_setModelReference(casMdlRefBlockPaths{i}, mHandledModelRefs);
end
end


%%
function [mHandledModelRef, casNewModelRefFiles] = i_copyToplevelMdlRefs(casMdlNames, mKnownModelRefs, sPostFix, sTargetDir)

casNewModelRefFiles = {};
if isempty(mKnownModelRefs)
    mHandledModelRef = containers.Map;
else
    mHandledModelRef = containers.Map(mKnownModelRefs.keys, mKnownModelRefs.values);
end
for i=1:numel(casMdlNames)
    sMdlName = casMdlNames{i};
    if ~mHandledModelRef.isKey(sMdlName)
        sFileName = get_param(sMdlName, 'FileName');
        [~, ~, sMdlExt] =  fileparts(sFileName);
        sTargetName = [sMdlName, sPostFix];
        sTargetFile = fullfile(sTargetDir, [sTargetName, sMdlExt]);
        copyfile(sFileName, sTargetFile);
        
        mHandledModelRef(sMdlName) = sTargetName;
        casNewModelRefFiles{end+1} = sTargetFile; %#ok<AGROW>
    end
end
end


%%
function i_setModelReference(sModelRefBlock, mKnownMdlRef)
% Note: reading out parameter argument values (or instance values) needs to be done *before* setting a new name;
%       otherwise this information gets lost
if verLessThan('Matlab','9.6')
    stParamArgValues = get_param(sModelRefBlock, 'ParameterArgumentValues');
    set_param(sModelRefBlock, 'ModelName', mKnownMdlRef(get_param(sModelRefBlock, 'ModelName')));
    set_param(sModelRefBlock, 'ParameterArgumentValues', stParamArgValues);
else
    stInstanceParams = get_param(sModelRefBlock, 'InstanceParameters');
    set_param(sModelRefBlock, 'ModelName', mKnownMdlRef(get_param(sModelRefBlock, 'ModelName')));
    set_param(sModelRefBlock, 'InstanceParameters', stInstanceParams);
end
end