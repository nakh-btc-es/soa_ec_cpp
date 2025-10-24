function [stMainDD, astAddDDs] = atgcv_dd_close(varargin)
% Close current DD and return info about it.
%
% function [stMainDD, astAddDDs] = atgcv_dd_close(varargin)
%
%   INPUT               DESCRIPTION
%     varargin            (key, value) pairs
%
%    ----- key ----------------------------------
%      Save               (boolean) if true, all DDs will be saved if before
%                                   being closed
%                                   (default = true)
%
%   OUTPUT              DESCRIPTION
%     stMainDD            (struct)  info about main DD (data see below)
%     astAddDDs           (array)   infos about additional DDs (data see below)
%
% ---------------------------------------------
%          stDD           (struct)  general DD info
%           .sFile        (string)    full path to the DD File
%           .nDDIdx      (numeric)    ID of the DD-Workspace the DD is loaded in
%    
%   <et_copyright>


%% internal 
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 206137 $
%   Last modified: $Date: 2015-11-16 15:02:51 +0100 (Mo, 16 Nov 2015) $ 
%   $Author: ahornste $
%

%%
stMainDD  = [];
astAddDDs = [];

stOpts = i_evalOptions(varargin{:});

%% main
xOnCleanupResetBatchMode = i_switchBatchModeOn(); %#ok cleanup obj

% Possibly more than one DD loaded
astDDInfos = dsdd('GetAllDDs');
if isempty(astDDInfos)
    return;
end

for i = 1:length(astDDInfos)
    stDDInfo = astDDInfos(i);
    
    if i_isTemporary(stDDInfo)
        % 1) temporary DDs cannot be saved without User interaction
        % 2) also do _not_ return infos about temp DDs
        i_closeDD(stDDInfo.treeIdx, false);
    else
        i_closeDD(stDDInfo.treeIdx, stOpts.save);
        
        if i_isMain(stDDInfo)
            stMainDD = i_getInfo(stDDInfo);
        else
            if isempty(astAddDDs)
                astAddDDs = i_getInfo(stDDInfo);
            else
                astAddDDs = [astAddDDs, i_getInfo(stDDInfo)]; %#ok<AGROW>
            end
        end
    end
end
% sometimes the closing above can result in an "untitled_2.dd" being now the 
% current main DD --> to get rid of it, close the main DD again
dsdd('Close', 'Save', 'off');
end


%%
function stOpts = i_evalOptions(varargin)
stOpts = struct( ...
    'save', true);

nArgs = length(varargin);
for i = 1:2:nArgs
    sOpt = lower(varargin{i});
    xVal = varargin{i + 1};
    
    if isfield(stOpts, sOpt)
        stOpts.(sOpt) = xVal;
    else
        error('INTERNAL:ERROR', 'Unknown Option "%s".', sOpt);
    end
end
end


%%
function i_closeDD(iDDIdx, bDoSave)
% save only if there are modifications
bDoSave = bDoSave && dsdd('IsModified', iDDIdx);
if bDoSave
    dsdd('Close', 'DDIdx', iDDIdx, 'Save', 'on');
else
    dsdd('Close', 'DDIdx', iDDIdx, 'Save', 'off');
end
end


%%
function bIsTemporary = i_isTemporary(stDDInfo)
bIsTemporary = ...
    logical(dsdd('GetAttribute', stDDInfo.hDDRoot, 'temporary')) || ...
    ~exist(stDDInfo.fileName, 'file');
end


%%
function xOnCleanupReset = i_switchBatchModeOn()
sBatchMode = ds_error_get('BatchMode');
ds_error_set('BatchMode', 'on');
xOnCleanupReset = onCleanup(@() ds_error_set('BatchMode', sBatchMode));
end


%%
function stInfo = i_getInfo(stDDInfo)
stInfo = struct( ...
    'sFile',  atgcv_canonical_path(stDDInfo.fileName), ...
    'nDDIdx', stDDInfo.treeIdx);
end


%%
function bIsMain = i_isMain(stDDInfo)
bIsMain = stDDInfo.treeIdx == 0;
end
