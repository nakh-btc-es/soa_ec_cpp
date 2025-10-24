function  stEval = ep_sim_tlds_eval()
% Evaluate the TL TLDS database.
%
% function stEval = ep_sim_tlds_eval()
%
%   INPUT               DESCRIPTION
%     --
%
%   OUTPUT              DESCRIPTION
%     stEval                 (struct)
%        .bTLDS                 (boolean)  flag if TLDS could be evaluated
%        .anExecutionTime       (number)   array with execution times
%        .anStackSize           (number)   array with stack sizes
%


%%
stEval = struct( ...
    'bTLDS',           false, ...
    'anExecutionTime', [], ...
    'anStackSize',     []);

if ~atgcv_use_tl
    return; % not allowed to use TL --> early return
end

stSimLogStruct = i_getMostRecentSimLog();
if isempty(stSimLogStruct)
    return; % no current logging found --> early return
end
stEval.bTLDS = true;

[iTimeLogIdx, iStackLogIdx] = i_findTimeAndStackLogIndices(stSimLogStruct);
if ((iTimeLogIdx > 0) && (iStackLogIdx > 0)) 
    try
        stEval.anExecutionTime = stSimLogStruct.logs{iTimeLogIdx}.signal.y;
        stEval.anStackSize = stSimLogStruct.logs{iStackLogIdx}.signal.y;
    catch
        % just safety code here
    end
end
end


%%
function [iTimeLogIdx, iStackLogIdx] = i_findTimeAndStackLogIndices(stSimLogStruct)
iTimeLogIdx  = 0;
iStackLogIdx = 0;

for i = 1:stSimLogStruct.nlogs
    sBlock = stSimLogStruct.logs{i}.block;
    
    % search the last simulation for the 'exec time' logged signal
    if ~isempty(strfind(sBlock, 'exec time'))
        iTimeLogIdx = i;
    end
    % search the last simulation for the 'stack size' logged signal
    if ~isempty(strfind(sBlock, 'stack size'))
        iStackLogIdx = i;
    end
end
end


%%
function stSimLogStruct = i_getMostRecentSimLog()
stSimLogStruct = [];

castSimArray = tlds(0, 'get', 'simulations');
if isempty(castSimArray)
    return;
end

% get most recent simulation data
stSimLogStruct = castSimArray{end};
try
    % close the TLDS GUI figure
    close(stSimLogStruct.figure);
catch
    % just safety code here
end
end

