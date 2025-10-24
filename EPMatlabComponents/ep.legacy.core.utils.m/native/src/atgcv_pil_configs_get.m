function casPilConfigs = atgcv_pil_configs_get()
% return name of all PIL configurations that are possible in the current environment 
%
% function casPilConfigs = atgcv_pil_configs_get()
% 
%
%   INPUT               DESCRIPTION
%
%
%   OUTPUT              DESCRIPTION
%   casPilConfigs        Cell array of strings with the available PIL
%                        configurations.
%
%
%
%   REMARKS
%
%   <et_copyright>

%% Internal
%   REFERENCE(S):
%     Design Document:
%
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%

%% main
try
    try
        stSimConfig = tl_global_options('simconfig');
    catch
        stErr = lasterror();
        sMsg = sprintf('Error using tl_global_options: %s', stErr.message);
        
        % use global messenger
        stEnv = 0;
        stErr = osc_messenger_add(stEnv, 'ATGCV:API:INTERNAL_ERROR', ...
            'msg', sMsg);
        osc_throw(stErr);
    end
    casPilConfigs = {stSimConfig(:).name};     
    
catch
%%  panic
    osc_throw(osc_lasterror);
end

%% end
return;

