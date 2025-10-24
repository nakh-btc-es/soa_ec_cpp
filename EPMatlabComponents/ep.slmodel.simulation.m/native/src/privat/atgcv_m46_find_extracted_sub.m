function [hTopSub, sExtractedSub] = atgcv_m46_find_extracted_sub(sModel)
% Find the extracted root Subsystem inside the provided mode.
%
% function [hTopSub, sExtractedSub] = atgcv_m46_find_extracted_sub(sModel)
%
%   INPUT               DESCRIPTION
%      sModel               (string)    Model name of extraction model
%
%   OUTPUT              DESCRIPTION
%      hTopSub              (handle)    handle of the _inner_ Subsystem of the
%                                       TL-TopLevel Subsystem
%                                       example: <Model>/<Top>/Subsystem/<Top>
%                                       (might be empty if not found)
%
%    sExtractedSub          (string)    extracted Subsystem 
%                                       (might be empty if not found)
%   REMARKS
%
%   Note: Many implicit ASSUMPTIONS in this function!!!
%

%%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

[hTopSub, sExtractedSub] = i_findExtractedSubFromOrigModel(sModel);
end


%%
% NOTE: _dangerous_ function <-- assuming that BTC Frame is named "btc"
function bIsBtcFrame = i_isBtcFrame(hSub)
bIsBtcFrame = false;
if ~isempty(hSub)
    sName = get_param(hSub, 'Name');
    bIsBtcFrame = strcmpi(sName, 'btc');
end
end


%%
% Note: _dangerous_ function <-- assuming the following
%       1) the Subsystem hierarachy is like this:
%             <Model>/<BTC_Frame>/<TLSubFromOriginalModel>
%       2) the <BTC_Frame> Sub contains a TL_Function Block
%
function [hTopSub, sExtractedSub] = i_findExtractedSubFromOrigModel(sModel)
hTopSub = [];
sExtractedSub = '';
casTopSub = ep_find_system(sModel, ...
    'LookUnderMasks', 'on', ...
    'Tag',            'MIL Subsystem');
if ~isempty(casTopSub)
    sTopSub = getfullname(casTopSub{1});
    hTopSub = get_param(sTopSub, 'Handle');
    if i_isBtcFrame(hTopSub)
        cahTopFunction = ep_find_system(hTopSub, ...
            'LookUnderMasks', 'on',...
            'FollowLinks',    'off', ...
            'SearchDepth',    2,...
            'MaskType',       'TL_Function');
        for i = 1:length(cahTopFunction)
            hFunction = cahTopFunction(i);
            sPath = get(hFunction, 'Parent');
            if ~strcmp(sPath, sTopSub)
                sExtractedSub = sPath;
                break;
            end
        end
    else
        % If BTC-Frame not found, assume that the TopLevel found is taken from
        % the original model.
        sExtractedSub = sTopSub;
    end
end
end
