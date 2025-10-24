function sModelFile = atgcv_m13_save_model(sModelName, bClose, bIncludeRefs, sSuffix)
% 
% function sModelFile = atgcv_m13_save_model(sModelName,bClose,bIncludeRefs, sSuffix)
%
%   INPUT               DESCRIPTION
%       sModel          (string) Model name of the simulink model
%       bClose          (boolean) Close the model after saving
%       bIncludeRefs    (boolean) includes references when closing model
%       sSuffix         (string) The suffix of the file (mdl|slx)
%   OUTPUT              DESCRIPTION
%     


%%
if (nargin < 4)
    sSuffix = '.slx';
end

if atgcv_use_tl
    % close model without DD requester
    sBatchMode = ds_error_get('BatchMode');
    ds_error_set('BatchMode', 'on');
    
    oOnCleanupResetBatchMode = onCleanup(@() ds_error_set('BatchMode', sBatchMode));
end

if ~atgcv_debug_status
    sWarn = warning;
    warning off all;
    oOnCleanupResetWarnings = onCleanup(@() warning(sWarn));
end

sModelFile = [sModelName sSuffix];
i_closeSaveModel(sModelName, sModelFile, bClose, bIncludeRefs);
end


%%
function bHasDirtyModelRefs = i_hasDirtyModelReferences(sModelName)
bHasDirtyModelRefs = false;
casAllMdls = ep_find_mdlrefs(sModelName);
if (numel(casAllMdls) < 2)
    return;
end

casRefMdls = casAllMdls(1:end-1);
for i = 1:numel(casRefMdls)
    sRefModel = casRefMdls{i};
    
    try
        sDirtyFlag = get_param(sRefModel, 'Dirty');
        bHasDirtyModelRefs = strcmp(sDirtyFlag, 'on');
        if bHasDirtyModelRefs
            return;
        end
    catch oEx
        % model reference could already be closed; in this case just be robust
    end
end
end


%%
function i_closeSaveModel(sModelName, sModelFile, bClose, bCloseRefs)
casAddOptions = {};
if i_hasDirtyModelReferences(sModelName)
    if ~verLessThan('matlab', '9.3')
        % from ML2017b onwards we should make sure that dirty model references are save also; otherwise saving or closing
        % the model with a save will not work and produce an error
        casAddOptions = {'SaveDirtyReferencedModels', 'on'};
    else
        error('EP:SIM:SAVE_DIRTY_MODEL_REFS', ...
            'Cannot save model "%s" because it references models that are in a dirty state.', sModelName);
    end
end

if bClose
    if bCloseRefs
        i_closeModelReferences(sModelName);
    end
    close_system(sModelName, sModelFile, casAddOptions{:});
else
    save_system(sModelName, sModelFile, casAddOptions{:});
end
end

%%
function i_closeModelReferences(sName)
casRefs = ep_find_mdlrefs(sName, 'AllLevels', false);
%remove last entry since it is the extraction model itself
casRefs = casRefs(1:end-1);
for i = 1:length(casRefs)
    %i_closeModelReferences(casRefs(i));
    if bdIsLoaded(casRefs(i))
        i_closeModelReferences(char(casRefs(i)));
        close_system(casRefs(i), 1);
    end
end
end

