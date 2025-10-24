function [mModelRefCopyMap, hSubNew] = ep_model_subsystems_resolve(stArgs)
% This function imports subsystem content into the extraction model by
% breaking links, subsystem references, SLDDs and model references.
%
% function [mModelRefCopyMap, hSubNew] = ep_model_subsystems_resolve(stArgs)
%
%  INPUT            DESCRIPTION
%  stArgs           (struct)        A struct containing all input arguments
%
%       FIELD               DESCRIPTION
%       stEnv               (struct)        Old environment structure. TO BE REMOVED/REFACTORED.
%       hSub                (handle)        Handle of the subsystem/model to be resolved.
%       iModelRefMode       (int)           Model reference handling mode.
%                                           0 = Use original models.
%                                           1 = Copy model references. (new self-contained)
%                                           2 = Monolithic extraction model. (old self-contained)
%       mKnownModelRefs     (map)           Map containing already copied model references.
%                                           Only needed if iModelRefmode = 1.
%       sPostFix            (string)        Unique name section to be added to copied model references.
%                                           Only needed if iModelRefmode = 1.
%       sTargetDir          (string)        Target directory where copied model references will be put.
%                                           Only needed if iModelRefmode = 1.
%       casPreserveLibLinks (cell-array)    Defines a list of library names for which the links must not be broken.
%                                           For some libraries it is possible that a link break leads to an invalid
%                                           extraction model. E.g (SimScape). Hence no Simulation is possible.
%  OUTPUT           DESCRIPTION
%  mModelRefCopyMap (map)           A map containing all copied model references. Includes those in mKnownModelRefs.
%                                   Empty if iModelRefMode is 0 or 2.
%  hSubNew          (handle)        If the incoming handle is changed due to the removal of a subsystem reference,
%                                   it is being outputted through this parameter. Otherwise identical to input.


%%
hSubNew = stArgs.hSub;
if isempty(stArgs.mKnownModelRefs)
    mModelRefCopyMap = containers.Map;
else
    mModelRefCopyMap = containers.Map(stArgs.mKnownModelRefs.keys, stArgs.mKnownModelRefs.values);
end

if (stArgs.iModelRefMode == ep_sl.Constants.KEEP_REFS)
    % using original model, no need to resolve anything
    return;
end

bMadeChanges = true;
while bMadeChanges
    
    iChangedAmount = atgcv_m13_break_links(stArgs.hSub, stArgs.casPreserveLibLinks);
    bMadeChanges = iChangedAmount > 0;
    
    if ~bMadeChanges
        [iChangedAmount, hSubNew] = ep_simenv_subsystemref_remove(stArgs.stEnv, stArgs.hSub);
        stArgs.hSub = hSubNew;
        bMadeChanges = iChangedAmount > 0;
    end
    
    if ~bMadeChanges
        iChangedAmount = atgcv_m13_configsub_replace(stArgs.stEnv, stArgs.hSub, stArgs.casPreserveLibLinks);
        bMadeChanges = iChangedAmount > 0;
    end    
end

switch stArgs.iModelRefMode
    case ep_sl.Constants.COPY_REFS
        [mTempMap, casNewModelRefFiles] = ...
            ep_model_references_replace(stArgs.hSub, stArgs.mKnownModelRefs, stArgs.sPostFix, stArgs.sTargetDir);
        if ~isempty(mTempMap)
            stArgs.mKnownModelRefs = containers.Map(mTempMap.keys, mTempMap.values);
        end
        for i = 1:numel(casNewModelRefFiles)
            stArgs = i_resolveChildReferences(stArgs, casNewModelRefFiles{i});
        end
        mModelRefCopyMap = stArgs.mKnownModelRefs;
        
    case ep_sl.Constants.BREAK_REFS
        casNewSubsystemPaths = atgcv_m13_modelref_remove(stArgs.stEnv, stArgs.hSub);
        for i = 1:numel(casNewSubsystemPaths)
            stArgs.hSub = getSimulinkBlockHandle(casNewSubsystemPaths{i});
            ep_model_subsystems_resolve(stArgs);
        end
        
    otherwise
        error('INTERNAL:ERROR', 'Unexpected iConfigMode: %d.', stArgs.iModelRefMode);
end
end


%%
function i_breakDataDependencies(hRefModel, sPostFix)
i_breakMatFileDependencies(hRefModel);
oActiveConfigSet = getActiveConfigSet(hRefModel);
if isa(oActiveConfigSet, 'Simulink.ConfigSetRef')
    i_breakConfigReference(oActiveConfigSet, hRefModel, sPostFix);
else
    oActiveConfigSet.getComponent('Solver').StartTime = '0';
end

if ~verLessThan('Matlab', '9.6')
    set_param(hRefModel, 'EnableAccessToBaseWorkspace', 'on');
end
set_param(hRefModel, 'DataDictionary', '');
end


%%
function i_breakMatFileDependencies(hRefModel)
hModelWS = get_param(hRefModel, 'ModelWorkspace');
if ~strcmp(hModelWS.DataSource, 'Model File')
    %Ensure that no external file is needed as the data source before copying
    hModelWS.DataSource = 'Model File';
end
end


%%
function i_breakConfigReference(oActiveConfigSet, hRefModel, sPostFix)
oNewConfigSet = copy(getRefConfigSet(oActiveConfigSet));
sNewConfigName = ['EPConfig' sPostFix];
set_param(oNewConfigSet, 'Name', sNewConfigName);
oNewConfigSet.getComponent('Solver').StartTime = '0';
attachConfigSet(hRefModel, oNewConfigSet);
setActiveConfigSet(hRefModel, sNewConfigName);
end


%%
function stArgs = i_resolveChildReferences(stArgs, sNewMdlRefFile)
hRefModel = load_system(sNewMdlRefFile);
stArgs.hSub = hRefModel;

i_breakDataDependencies(hRefModel, stArgs.sPostFix);
mTempMap = ep_model_subsystems_resolve(stArgs);

if isempty(mTempMap)
    stArgs.mKnownModelRefs = containers.Map;
else
    stArgs.mKnownModelRefs = containers.Map(mTempMap.keys, mTempMap.values);
end
if verLessThan('Matlab', '9.3')
    save_system(hRefModel, '')
else
    save_system(hRefModel, '', 'SaveDirtyReferencedModels', 'on');
end
end
