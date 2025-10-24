function xUserPref = replaceAndEvaluateMacros(oItf, xUserPref, dataObject)%#ok
% This function replaces known macros in the user defined preferences and evaluates user preferences that are based on
% the interface's corresponding data object (e.g: '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile')
%
% function [xUserString, bHasDataObject] = replaceAndEvaluateMacros(oItf, xUserPref, dataObject)
%


%%
% first filter out the bad cases
if isempty(xUserPref) || (~ischar(xUserPref) && ~iscell(xUserPref))
    return;
end

%%
try
    casUserPrefParts = cellstr(xUserPref);
catch
    return;
end

caxUserPrefParts = cell(size(casUserPrefParts));
for i = 1:numel(casUserPrefParts)
    try
        [sStringPart, bHasDataObject] = replaceMacros(oItf, casUserPrefParts{i}, 'dataObject');
        if bHasDataObject
            xEvalResult = eval(sStringPart);
        else
            xEvalResult = sStringPart;
        end
        caxUserPrefParts{i} = xEvalResult;
    catch
        caxUserPrefParts{i} = casUserPrefParts{i};
    end
end
if all(cellfun(@ischar, caxUserPrefParts))
    xUserPref = strjoin(caxUserPrefParts, '');
else
    if (numel(caxUserPrefParts) == 1)
        xUserPref = caxUserPrefParts{1};
    else
        xUserPref = caxUserPrefParts;
    end
end
end

