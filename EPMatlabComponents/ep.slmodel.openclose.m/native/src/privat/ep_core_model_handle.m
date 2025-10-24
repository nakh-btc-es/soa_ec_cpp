function stModelHandle = ep_core_model_handle(sCmd, stModelHandle)
% Allocating and freeing additional resources for models.
%
%  function stModelHandle = ep_core_model_handle(sCmd, stModelHandle)
%
%   INPUT                       DESCRIPTION
%   - sCmd                         (string)   'allocate' | 'free'            
%   - stModelHandle                (struct)   structure with info about opened model
%
%   OUTPUT                      DESCRIPTION
%   - stModelHandle                (struct)   modified input structure
%
% $$$COPYRIGHT$$$-2017


%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%%
switch lower(sCmd)
    case 'allocate'
        stModelHandle = i_allocateResources(stModelHandle);
        
    case 'free'
        stModelHandle = i_freeResources(stModelHandle);
        
    otherwise
        error('EP:CORE:UNKNOWN_COMMAND', 'Unknown command "%s".', sCmd);
end
end


%%
function stModelHandle = i_allocateResources(stModelHandle)
stModelHandle.xInternalCoreHandle = ''; % as default do not allocate anything if not needed
if stModelHandle.bIsTL
    xOnCleanupRemoveHooks = ep_core_tl_get_config_path('extend');
    if ~isempty(xOnCleanupRemoveHooks)
        stModelHandle.xInternalCoreHandle = ep_core_storage('add', xOnCleanupRemoveHooks);
    end
end
end


%%
function stModelHandle = i_freeResources(stModelHandle)
if (isfield(stModelHandle, 'xInternalCoreHandle') && ~isempty(stModelHandle.xInternalCoreHandle))
    xOnCleanupRemoveHooks = ep_core_storage('get', stModelHandle.xInternalCoreHandle);
    if ~isempty(xOnCleanupRemoveHooks)
        try
            if (isa(xOnCleanupRemoveHooks, 'onCleanup') && (xOnCleanupRemoveHooks.isvalid))
                delete(xOnCleanupRemoveHooks); % delete the onCleanup object which will trigger the reversion
            end
        catch oEx
            warning('EP:CORE:REMOVE_TL_HOOK_EXTENSION_FAILED', '%s', oEx.message);
        end
        ep_core_storage('remove', stModelHandle.xInternalCoreHandle);
    end
    stModelHandle.xInternalCoreHandle = '';
end
end
