function atgcv_m13_mdl_callbacks_copy(stEnv, hSrcMdl, hDestMdl)
% copy all global callbacks of the source model to the destination model
%
% function atgcv_m13_mdl_callbacks_copy(stEnv hSrcMdl, hDestMdl)
%
%   INPUTS             DESCRIPTION
%     stEnv            (struct)      environment struct
%       .hMessenger    (object)         messenger object for entering errors
%     hSrcMdl          (handle)      source model
%     hDestMdl         (handle)      destination model
%
%   OUTPUTS:
%       ---              ---
%
%   REMARKS:
%     Note that the original callback functions of the destination model will
%     be overwritten during this process.
%

%% internal
%   AUTHOR(S):
%     Alex Hornstein
% $$$COPYRIGHT$$$-2016
%



%%
cellfun(@(x) i_copyFcn(stEnv, hSrcMdl, hDestMdl, x), i_getModelCallbacks());
end


%%
function bSuccess = i_copyFcn(~, hSrcMdl, hDestMdl, sFcnName)
bSuccess = false;
try
    sFcnContent = get_param(hSrcMdl, sFcnName);
    if ischar(sFcnContent)
        set_param(hDestMdl, sFcnName, sFcnContent);
    end
    bSuccess = true;
catch oEx
    % TODO: enter a messenger warning!!
    warning('ATGCV:MIL:CALLBACK_NOT_COPIED', ...
        'Failed to copy callback "%s".\n%s', sFcnName, oEx.message)
end
end


%%
function casCallbackFcns = i_getModelCallbacks()
% casCallbackFcns = { ...
%     'PreLoadFcn', ...
%     'PostLoadFcn', ...
%     'InitFcn', ...
%     'StartFcn', ...
%     'PauseFcn', ...
%     'ContinueFcn', ...
%     'StopFcn', ...
%     'PreSaveFcn', ...
%     'PostSaveFcn', ...
%     'CloseFcn'};

casCallbackFcns = {};
sMultiKey = atgcv_sim_settings('REUSE_MODEL_CALLBACKS');
if isempty(sMultiKey)
    return;
end

casCallbackFcns = i_splitMultiValue(sMultiKey);
end


%%
% * split multivalue at separator ';'
% * trim the resulting parts
% * remove all blanks (empty strings)
function casValues = i_splitMultiValue(sMultiValue)
casValues = strtrim(regexp(sMultiValue, ';', 'split'));
casValues(cellfun(@isempty, casValues)) = []; 
end

