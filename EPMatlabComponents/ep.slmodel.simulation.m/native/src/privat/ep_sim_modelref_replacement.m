function varargout = ep_sim_modelref_replacement(sCmd, varargin)
%
% function varargout = ep_sim_modelref_replacement(sCmd, varargin)
%
%  Following commands:
%
% ===== mark ==============================
% Marks a subsystem as a replaced model reference block with information about the formerly referenced model.
%
%  Example: ep_sim_modelref_replacement('mark', xSubsystem, sRefModel)
%
%   INPUTS               DESCRIPTION
%     sCmd                 (string)          'mark'
%     xSubsystem           (handle/string)   handle or model path of the replacement subsystem
%     sRefModel            (string)          name of the model that was formerly referenced (without extensions!)
%
%   OUTPUT               DESCRIPTION
%     -                     -
%
% ===== find ==============================
% Searches for subsystems that have replaced model reference blocks inside the provided model context.
%
%  Example: mSubToRefModel = ep_sim_modelref_replacement('find', xModelContext)
%
%   INPUTS               DESCRIPTION
%     sCmd                 (string)          'find'
%     xModelContext        (handle/string)   handle or model path of the model context from which the search starts
%
%   OUTPUT               DESCRIPTION
%     mSubToRefModel       (map)             containers.Map object mapping subsystem paths to formerly refernced models
%   


%%
switch lower(sCmd)
    case 'mark'
        sSubsysPath = getfullname(varargin{1});
        sModelName = varargin{2};
        i_markAsReplacedModelRef(sSubsysPath, sModelName);
        
    case 'find'
        sModelContext = getfullname(varargin{1});
        varargout{1} = i_findReplacedModelRefs(sModelContext);
        
    otherwise
        error('EP:ERROR:WRONG_USAGE', 'Unknown command "%s".', sCmd);
end
end


%%
function i_markAsReplacedModelRef(sSubsysPath, sModelName)
set_param(sSubsysPath, 'Tag', i_getReplacementTag());
set_param(sSubsysPath, 'UserData', sModelName);
set_param(sSubsysPath, 'UserDataPersistent', 'on');
end


%%
function mSubToRefModel = i_findReplacedModelRefs(sModelContext)
mSubToRefModel = containers.Map();

casMarkedSubs = ep_find_system(sModelContext, ...
    'LookUnderMasks', 'on', ...
    'FollowLinks',    'off', ...
    'BlockType',      'SubSystem', ...
    'Tag',            i_getReplacementTag());
for i = 1:numel(casMarkedSubs)
    sMarkedSub = casMarkedSubs{i};
    sRefModel = get_param(sMarkedSub, 'UserData');
    
    mSubToRefModel(sMarkedSub) = sRefModel;
end
end


%%
function sTag = i_getReplacementTag()
sTag = 'BTC_REPLACED_MODEL_REF';
end
