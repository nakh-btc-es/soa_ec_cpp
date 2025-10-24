function bCompliant = isConfigAnalysisCompliant(~, oObj, stDOCfg)
% check if the provided object matches the compliant search criteria in config

stSearchGlobal = stDOCfg.SearchGlobal;

bIsSuccessfulMatch = i_isDataMatchingSearchCriteria(oObj, stSearchGlobal);
if i_doInterpretSuccessfulMatchAsNonCompliant(stSearchGlobal)
    bCompliant = ~bIsSuccessfulMatch;
else
    bCompliant = bIsSuccessfulMatch;
end
end


%%
function bIsMatching = i_isDataMatchingSearchCriteria(oObj, stSearchGlobal)
bIsMatching = i_isMatchingClass(oObj, stSearchGlobal.DataObjectClass);

if bIsMatching
    % if the class is accepted, check if one of the filters does also apply
    for f = 1:numel(stSearchGlobal.PropFilter)
        % assure that we have at least one property defined for the filter
        nFilterProperties = numel(stSearchGlobal.PropFilter(f).Property);
        bIsMatching = (nFilterProperties > 0);
        if ~bIsMatching
            warning('EP:EC:FILTER_WO_PROPS', 'Config inconsistent: Global filter without any properties.');
        end
        
        % check every property that is specified in filter individually
        for p = 1:nFilterProperties
            sPropName = stSearchGlobal.PropFilter(f).Property(p).Name;
            try
                sObjPropValue = eval(['oObj.' sPropName]); %#ok<EVLDOT> eval is required here since prop name may contain dots
                bIsMatching = ismember(sObjPropValue, cellstr(stSearchGlobal.PropFilter(f).Property(p).Value));
            
            catch oEx %#ok<NASGU>
                bIsMatching = false; % property not applicable means --> invalid matching
            end
            % break at once if any property of the filter does not match ==> filter does not match at all
            if ~bIsMatching
                break;
            end
        end
        
        % return at once if one of the filters is matching
        if bIsMatching
            return;
        end
    end
end
end


%%
% note1: xValidClasses could be a cell or a single string
% note2: an empty string or an empty cell array idicate that *all* classes are accepted as a valid match
%
function bIsMatchingClass = i_isMatchingClass(oObj, xValidClasses)
bDoAcceptAllClasses = isempty(char(xValidClasses));
bIsMatchingClass = bDoAcceptAllClasses || ismember(class(oObj), cellstr(xValidClasses));
end


%%
function bIsBlackList = i_doInterpretSuccessfulMatchAsNonCompliant(stSearchGlobal)
bIsBlackList = isfield(stSearchGlobal, 'FilterMethod') && strcmpi(stSearchGlobal.FilterMethod, 'BlackList');
end

