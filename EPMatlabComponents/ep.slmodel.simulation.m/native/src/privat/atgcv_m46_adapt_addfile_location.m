function atgcv_m46_adapt_addfile_location(sModel)
% Sets the TL SIL mode to the given model
%
% function atgcv_m46_adapt_addfile_location(sModel)
%
%   INPUT               DESCRIPTION
%   sModel               (string)    Model name of the TL model
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document:
%        Section : M46
%        Download:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%


% NOTE: THIS IS SPECIAL BEHAVIOUR FOR BTS/34216
[hTopSub, sExtractedSub] = atgcv_m46_find_extracted_sub(sModel);
if (isempty(hTopSub) || isempty(sExtractedSub))
    % nothing to do: the Model does not comply to the expected BTC-ExtractionModel
    return;
end
sTopSub = getfullname(hTopSub);
if strcmp(sTopSub, sExtractedSub)
    % nothing to do: the extracted Sub is already at the TopLevel
    return;
end


cahAddFiles = ep_find_system(hTopSub, ...
    'LookUnderMasks', 'on', ...
    'FollowLinks',    'off', ...
    'MaskType',       'TL_AddFile');
if isempty(cahAddFiles)
    return;
end

nIndex = 0;
for i = 1:length(cahAddFiles)
    hAddFile = cahAddFiles(i);
    sPath = get(hAddFile,'Path');
    if strcmp(sPath, sTopSub)
        % AddFile block already at the highest level --> do nothing
        continue;
    end
    sParentPath = i_findParentFunctionScope(sPath);
    if strcmp(sParentPath, sExtractedSub) % top level scope
        [nValue, errorflag] = tl_get(hAddFile, 'addfilemode');
        if ~errorflag
            bIncludeInGeneratedFile = isequal(nValue, 1);
            % ONLY WHEN FILE IS "Include in generated file"
            if bIncludeInGeneratedFile
                sName = get(hAddFile, 'Name');
                sNewLocation = [sTopSub, '/', sName, '_', num2str(nIndex)];
                hNewFileBlock = add_block('tllib/Addfile', sNewLocation);
                i_tlSet(hNewFileBlock, 'addfilemode', nValue);
                
                i_transferProperties(hAddFile, hNewFileBlock);
                
                nIndex = nIndex + 1;
            end
        end
    end
end
end


%%
function i_transferProperties(hSourceAddFile, hTargetAddFile)
casProps = { ...
    'blockcomment', ...
    'codefile', ...
    'fileinfo'};
for i = 1:length(casProps)
    sProp = casProps{i};
    [xPropValue, errorflag] = tl_get(hSourceAddFile, sProp);
    if ~errorflag
        i_tlSet(hTargetAddFile, sProp, xPropValue);
    end
end
% not necessary to be visible in subsystems
i_tlSet(hTargetAddFile, 'visible', 0);
end


%%
function i_tlSet(varargin)
errorflag = tl_set(varargin{:}); %#ok use output arg to prevent exceptions
end


%%
function sParentPath = i_findParentFunctionScope(sPath)
sParentPath = '';
if isempty(sPath)
    return;
end
casFunction = ep_find_system(sPath, 'LookUnderMasks','off',...
    'FollowLinks', 'off', 'SearchDepth', 1,...
    'MaskType','TL_Function');
if( isempty(casFunction) )
    sPath = get_param(sPath,'Parent');
    sParentPath = i_findParentFunctionScope(sPath);
else
    sParentPath = sPath;
end
end