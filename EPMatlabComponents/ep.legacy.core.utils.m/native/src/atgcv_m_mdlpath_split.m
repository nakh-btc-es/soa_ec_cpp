function [sParentModelPath, sBlockName] = atgcv_m_mdlpath_split(sModelPath)
%  splits the provided model path into block name and parent path
%
%  [sParentModelPath, sBlockName] = atgcv_m_mdlpath_split(sModelPath)
%
%  NOTE: In contrast to using fileparts() this function sticks to the Simulink
%        rules in context of Model Paths:
%        1) "//" is not a path seperator but an escaped slash "/"
%        2) "." -- dots in model names are allowed and not meant as a
%           fileextension
%

%%
sParentModelPath = '';
sBlockName = '';
if ((nargin < 1) || isempty(sModelPath))
    return;
end
if ~ischar(sModelPath)
    error('ATGCV:INTERNAL:WRONG_USAGE', 'Input has to be a string.');
end

% Note: we don't want to find escaped slashes 
%       --> so convert them before searching
%       --> afterwards use the found indexes on the original string
sTmpPath = regexprep(sModelPath, '//', 'xx');
aiFound = regexp(sTmpPath, '/');

if isempty(aiFound)
   sBlockName = sModelPath;
else
    iIdx = aiFound(end);
    if (iIdx > 1)
        sParentModelPath = sModelPath(1:iIdx-1);
    end
    if (iIdx < length(sModelPath))
        sBlockName = sModelPath(iIdx+1:end);
    end
end
end


