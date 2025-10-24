function oItf = getCodeVariable(oItf, stCfgCodeFormat, oDataObj, bIssueWarning)
% Maps the provided data object onto C-code attributes for the interface object according to configuration settings.
if (nargin < 4)
    bIssueWarning = true;
end


% Find a VariableFormat that can be applied to data object
castConfigs = i_getAllConfigs(stCfgCodeFormat);
for i = 1:numel(castConfigs)
    stCfg = castConfigs{i};
    
    if i_isConfigClassFilterMatching(oItf, stCfg, oDataObj)
        astVarFormat = stCfg.VarFormat;
        
        for k = 1:numel(astVarFormat)
            stVarFormat = astVarFormat(k);

            bIsFilterMatching = i_isFilterMatching(oItf, stVarFormat.Filter, oDataObj);
            if bIsFilterMatching
                oItf = oItf.applyVariableFormat(stVarFormat, oDataObj);
                break;
            end
        end
    end
end

% Analysis notes
if ~oItf.bMappingValid && bIssueWarning
    oItf.casAnalysisNotes{end + 1} = ...
        'Code representation cannot be analyzed: Signal object Class or Storage Class or Storage Class Attribute is not supported.';
end
end


%%
% note: the main configuration can contain nested "extension" configurations
% --> put all found configurations into a cell starting with the extensions
function castConfigs = i_getAllConfigs(stCfgCodeFormat)
if (~isfield(stCfgCodeFormat, 'Ext') || isempty(stCfgCodeFormat.Ext))
    castConfigs = {stCfgCodeFormat};
else
    casExtendedConfig = arrayfun(@(x) x, reshape(stCfgCodeFormat.Ext, 1, []), 'uni', false);
    castConfigs = [casExtendedConfig, {stCfgCodeFormat}];    
end
end


%%
function bIsMatching = i_isConfigClassFilterMatching(oItf, stCfg, oDataObj)
bIsMatching = ismember(oItf.dataClass, cellstr(stCfg.VarObjectClasses));
bIsMatching = bIsMatching && i_evalAdditonalFilterCond(oItf, stCfg, oDataObj);
end


%%
function bIsMatching = i_isFilterMatching(oItf, stFilter, oDataObj)
bIsMatching = ismember(oDataObj.CoderInfo.StorageClass, cellstr(stFilter.StorageClass));
bIsMatching = bIsMatching && ...
    (~strcmp(oDataObj.CoderInfo.StorageClass, 'Custom') || i_isFilterForCustomClassMatching(stFilter, oDataObj));
bIsMatching = bIsMatching && i_evalAdditonalFilterCond(oItf, stFilter, oDataObj);
end


%%
function bIsMatching = i_isFilterForCustomClassMatching(stFilter, oDataObj)
bIsMatching = ismember(oDataObj.CoderInfo.CustomStorageClass, cellstr(stFilter.CustomStorageClass));
if (bIsMatching && isfield(stFilter, 'CustomAttributes'))
    for m = 1:numel(stFilter.CustomAttributes)
        sAttribName = stFilter.CustomAttributes.name;
        if ~isempty(sAttribName)
            if ~ismember(oDataObj.CoderInfo.CustomAttributes.(sAttribName), cellstr(stFilter.CustomAttributes(m).value))
                bIsMatching = false;
                return;
            end
        end
    end
end
end


%%
function bIsCondTrue = i_evalAdditonalFilterCond(oItf, stFilter, oDataObj)
bIsCondTrue = true;

if ~isfield(stFilter, 'AdditionalFilterCond')
    return;
end

xCond = stFilter.AdditionalFilterCond;
if isempty(xCond)
    return;
end

if islogical(xCond)
    % actually, this is a usage error; however, for now accept booleans instead of strings and use their value as the
    % direct outcome of the condition evaluation
    bIsCondTrue = xCond;
    return;
end

if ischar(xCond)
    bIsCondTrue = oItf.replaceAndEvaluateMacros(xCond, oDataObj);
else
    warnning('EP:EC:ILLEGAL_CONDITION', 'Condition could not be evaluated properly. Considering it as failed.');
    bIsCondTrue = false;
end
end
