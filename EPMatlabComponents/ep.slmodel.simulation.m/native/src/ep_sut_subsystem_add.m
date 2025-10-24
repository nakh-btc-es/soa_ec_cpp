function [hSub, sNewSubsysPath] = ep_sut_subsystem_add(xEnv, hTargetBlock, stArgs, stSrcModelInfo)

stEnv = ep_core_legacy_env_get(xEnv, false);

% include subsystem
[hSub, ~, sNewSubsysPath, mModelRefReplacements, bIsScopeIntegrated] = atgcv_m13_subsys_add( ...
    stEnv, ...
    hTargetBlock, ...
    stSrcModelInfo.xSubsys, ...
    stSrcModelInfo.bIsTlModel, ...
    stArgs.ModelRefMode, ...
    stArgs.PreserveLibLinks, ...
    stSrcModelInfo.bSubsysIsRootModel);

% set position
adPosition = get_param(hSub, 'Position');
if (adPosition(2) < 100)
    adPosition(4) = adPosition(4) + 100 - adPosition(2);
    adPosition(2) = 100;
end
arNewPosition = [400 adPosition(2) 600 adPosition(4)];
set_param(hSub, 'Position', arNewPosition );


% FIRST adapt the physical paths in case that model references were not resolved but copied
% important to *first* adapt the physical path and then extend the map of model replacements !!!
if ~mModelRefReplacements.isempty()
    i_adaptPhysicalPaths(stSrcModelInfo.xSubsys, stSrcModelInfo.sExtractionModelFile, mModelRefReplacements);
end
    
% SECOND adapt the model sources where ModelWorkspace parameters are located
% now the model reference replacements can also be extended with the original model containing the SUT Subsystem
% if the latter became fully integrated into the extraction model
% --> this is required for adapting the model source of parameters/calibrations
if bIsScopeIntegrated
    sSutModel = i_getModelNameOfBlock(stSrcModelInfo.sSubsysPathPhysical);
    sTargetModel = i_getModelNameOfBlock(getfullname(hTargetBlock));
    mModelRefReplacements(sSutModel) = sTargetModel;
end
i_adaptSourceNodes(stSrcModelInfo.xSubsys, stSrcModelInfo.sExtractionModelFile, mModelRefReplacements);
end



%%
function i_adaptSourceNodes(hSubsysNode, sExtractionModelFile, mModelRefReplacements)
%check if we need to tune model workspace parameters
ahModelWsNodes = mxx_xmltree('get_nodes', hSubsysNode, './Calibration/Source[@kind=''ModelWorkspace'']');
if isempty(ahModelWsNodes)
    % without Calibrations nothing to do --> early return
    return;
end

bUnsavedChanges = false;
for i = 1:length(ahModelWsNodes)
    hSourceNode = ahModelWsNodes(i);
    sModelFile = mxx_xmltree('get_attribute', hSourceNode, 'file');
    if mModelRefReplacements.isKey(sModelFile)
        mxx_xmltree('set_attribute', hSourceNode, 'file', mModelRefReplacements(sModelFile));
        bUnsavedChanges = true;   
    end
end

if bUnsavedChanges
    mxx_xmltree('save', hSubsysNode, sExtractionModelFile);
end
end


%%
function i_adaptPhysicalPaths(hSubsysNode, sExtractionModelFile, mModelRefReplacements)
bHasXmlChanged = false;

% all blocks with physical path
ahBlocks = mxx_xmltree('get_nodes', hSubsysNode, './/*[@physicalPath]'); % include Displays inside nested Scopes
for i = 1:numel(ahBlocks)
    hBlock = ahBlocks(i);
    if i_adaptPhysPathOfBlock(hBlock, mModelRefReplacements)
        bHasXmlChanged = true;
    end
end

if bHasXmlChanged
    mxx_xmltree('save', hSubsysNode, sExtractionModelFile);
end
end


%%
function bHasDifferentLocation = i_adaptPhysPathOfBlock(hBlockNode, mModelRefReplacements)
sPhysPath = mxx_xmltree('get_attribute', hBlockNode, 'physicalPath');
[bHasDifferentLocation, sNewPhysPath] = i_getNewLocation(sPhysPath, mModelRefReplacements);
if bHasDifferentLocation
    mxx_xmltree('set_attribute', hBlockNode, 'physicalPath', sNewPhysPath);
end
end


%%
function [bHasDifferentLocation, sNewBlockPath] = i_getNewLocation(sBlockPath, mModelRefReplacements)
bHasDifferentLocation = false;
sNewBlockPath = sBlockPath;

sModelName = i_getModelNameOfBlock(sBlockPath);
if mModelRefReplacements.isKey(sModelName)
    sNewModelName = mModelRefReplacements(sModelName);
    if ~strcmp(sModelName, sNewModelName)
        sNewBlockPath = i_replaceModelName(sBlockPath, sModelName, sNewModelName);
        bHasDifferentLocation = true;
    end
end
end


%%
function sModelName = i_getModelNameOfBlock(sPath)
if any(sPath == '/')
    sModelName = regexprep(sPath, '/.*', '');
else
    sModelName = sPath;
end
end


%%
function sNewBlockPath = i_replaceModelName(sBlockPath, sModelName, sNewModelName)
if strcmp(sBlockPath, sModelName)
    sNewBlockPath = sNewModelName;
else
    sMatchPattern = ['^', regexptranslate('escape', sModelName), '/'];
    sNewBlockPath = regexprep(sBlockPath, sMatchPattern, [sNewModelName, '/']);
end
end
