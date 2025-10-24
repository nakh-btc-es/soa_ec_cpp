function atgcv_last_tlds_handle_clear(sModelName)
% clears the last TLDS handle in a TL model if available
%
% function bResult = atgcv_isa(xObject, sKind)
%
%   INPUT               DESCRIPTION
%      sModelName          (string)     optional: name of the model
%                                       if not provided "gcs" is used
%     
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%     
%   <et_copyright>


%% internal
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 204929 $
%   Last modified: $Date: 2015-10-16 16:14:16 +0200 (Fr, 16 Okt 2015) $ 
%   $Author: ahornste $


%%
% NOTE:  the removing of SimHandles is needed as a workaround for TL issue
%        without this a following CodeGen will fail
% NOTE2: actually it is just needed if Logging is active in the Model
%        also probably it is not needed for higher versions of TL
if ~atgcv_use_tl() 
    return;
end

if (nargin < 1)
    sModelName = gcs;
end
if isempty(sModelName)
    return;
end

if i_hasTldsTrigger(sModelName)
    hSim = tlds(0, 'get', 'simhandles');
    if ~isempty(hSim)
        tlds(hSim(end), 'delete');
    end
end
end


%%
function bHasTrigger = i_hasTldsTrigger(sModel)
bHasTrigger = false;
try
    casFcn = {'InitFcn', 'StartFcn', 'StopFcn'};
    for i = 1:length(casFcn)
        sFcn = casFcn{i};
        
        sVal = get_param(sModel, sFcn);
        bHasTrigger = bHasTrigger || ~isempty(strfind(sVal, 'tlds'));
        if bHasTrigger
            return; % early return
        end
    end
catch
end
end
