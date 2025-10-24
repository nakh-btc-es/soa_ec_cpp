function ahActiveVars = ep_active_dv_vars_get(hSubsys)
% Get all active variable instances of the currently active data variants.
%
% function ahActiveVars = ep_active_dv_vars_get(hSubsys)
%
%   INPUT           DESCRIPTION
%     hSubsys           (handle)       DD handle to a current subsystem (DD->Subsystems->"TopLevelName")
%
%   OUTPUT          DESCRIPTION
%     ahActiveVars      (array)        list of ahVars that includes all DV active variables
%


%% 

% init empty list
ahActiveVars = [];

% shortcut if no DataVariant is active
stConfig = ep_variant_config_get();
if ~isfield(stConfig, 'astDataVariants')
    return;
end

% check if resulting DataVariantStruct have been renamed by Template Rules
hTemplateSep = dsdd('Find', '/Pool/Templates', ...
    'name', 'Filter', ...
    'Property', {'name', 'StructSpec', 'value', 'VariantCodingSeparateStructs'});
bIsSepRenamed = ~isempty(hTemplateSep);

hTemplateArray = dsdd('Find', '/Pool/Templates', ...
    'name', 'Filter', ...
    'Property', {'name', 'StructSpec', 'value', 'VariantCodingArrayOfStructs'});
bIsArrayRenamed = ~isempty(hTemplateArray);


nDataVariants = length(stConfig.astDataVariants);
for i = 1:nDataVariants
    stDataVariant = stConfig.astDataVariants(i);

    % look for all variables belonging to DataVariant
    ahDvVars = dsdd('Find', hSubsys, ...
        'objectKind', 'Variable', ...
        'Property',   {'name', 'DataVariantName', 'value', stDataVariant.dataVariantName});
    
    % if no vars were found for this DV, we have nothing to do; so go to next DV
    if isempty(ahDvVars)
        continue;
    end
        
    % if DataVariant has only one DataVariantItem (possible for TL2.2.1 and  higher), 
    % all vars are active, since only one version of variable exists
    if (length(stDataVariant.variants) < 2)
        ahActiveVars = [ahActiveVars, ahDvVars]; %#ok<*AGROW>
        continue;
    end

    % four different strategies for the two CodingStyles and two bool values for renaming
    if strcmpi(stDataVariant.dataVariantCodingStyle, 'SEPARATE_STRUCTS')
        if bIsSepRenamed
            ahActiveVars = [ahActiveVars, i_getActiveSeparateStructsRenamed(stDataVariant, ahDvVars)];
        else
            ahActiveVars = [ahActiveVars, i_getActiveSeparateStructs(stDataVariant, ahDvVars)];
        end
        
    elseif strcmpi(stDataVariant.dataVariantCodingStyle, 'ARRAY_OF_STRUCTS')
        if bIsArrayRenamed
            ahActiveVars = [ahActiveVars, i_getActiveArrayStructsRenamed(stDataVariant, ahDvVars)];
        else
            ahActiveVars = [ahActiveVars, i_getActiveArrayStructs(stDataVariant, ahDvVars)];
        end
        
    else
        error('EP:MODEL_ANA:INTERNAL_ERROR', ...
            'Unknown variant coding style: "%s".', stDataVariant.dataVariantCodingStyle);
    end
end
end


%%
function ahMatchingVars = i_findMatchingPathVars(sRegExp, ahVars)
abIsMatching = false(size(ahVars));
nVars = length(ahVars);
for i = 1:nVars
    hVar = ahVars(i);

    sPath = dsdd('GetAttribute', hVar, 'Path');
    sPath = fileparts(sPath);
    if ~isempty(regexp(sPath, sRegExp, 'once'))
        % check that there is a PoolVar (BTS/35907) --> e.g. not true for auxiliary Map-Variables of LUTs
        hPoolVar = i_getPoolVar(hVar);
        if ~isempty(hPoolVar)
            % just to make sure: a value cross-check
            dActualValue = i_normalizeArrays(dsdd('GetValue', hVar));
            dExpectedValue = i_normalizeArrays(ddv(hPoolVar));
            if isequal(dActualValue, dExpectedValue)
                abIsMatching(i) = true;
            end
        end
    end
end
ahMatchingVars = ahVars(abIsMatching);
end


%%
% transform col-vectors into row-vectors to make them comparable
function adArray = i_normalizeArrays(adArray)
if (~isempty(adArray) && (numel(adArray) > 1) && iscolumn(adArray))
    adArray = reshape(adArray, 1, []);
end
end


%% 
function ahActiveVars = i_getActiveSeparateStructs(stDataVariant, ahCheckVars)
iVariantIdx = i_getActiveVariantIndex(stDataVariant);
sVariantItemName = stDataVariant.variantItemNames{iVariantIdx};

sRegExp = sprintf('%s_%s/Components$', stDataVariant.dataVariantName, sVariantItemName);
ahActiveVars = i_findMatchingPathVars(sRegExp, ahCheckVars);
end


%%
function ahActiveVars = i_getActiveSeparateStructsRenamed(stDataVariant, ahCheckVars)

% sort and revert order because the handles in the DD are "upside down"
ahCheckVars = sort(ahCheckVars);
ahCheckVars = ahCheckVars(end:-1:1);
ahPoolVars  = zeros(size(ahCheckVars));
nCheckVars  = length(ahCheckVars);
for i = 1:nCheckVars
    ahPoolVars(i) = i_getPoolVar(ahCheckVars(i));
end

ahUniquePoolVars = unique(ahPoolVars);
nPool = length(ahUniquePoolVars);

ahActiveVars = [];
if (nPool < 1)
    return;
end

iVariantIdx = i_getActiveVariantIndex(stDataVariant);
for i = 1:nPool
    hPoolVar = ahUniquePoolVars(i);
    
    % get the group of variable that refer to the same pool var; select the one that matches the variant index
    ahVarGroup = ahCheckVars(ahPoolVars == hPoolVar);
    if (length(ahVarGroup) < 2)
        ahActiveVars = [ahActiveVars, ahVarGroup];
    else
        ahActiveVars = [ahActiveVars, ahVarGroup(iVariantIdx)];
    end
end
end


%%
function ahActiveVars = i_getActiveArrayStructs(stDataVariant, ahCheckVars)
iVariantIdx = i_getActiveVariantIndex(stDataVariant);
if (iVariantIdx == 1)
    sRegExp = sprintf('%s/Components$', stDataVariant.dataVariantName);
else
    sRegExp = sprintf('%s/Components\\(#%d\\)$', stDataVariant.dataVariantName, iVariantIdx);
end
ahActiveVars = i_findMatchingPathVars(sRegExp, ahCheckVars);
end


%%
function ahActiveVars = i_getActiveArrayStructsRenamed(stDataVariant, ahCheckVars)
iVariantIdx = i_getActiveVariantIndex(stDataVariant);
if (iVariantIdx == 1)
    sRegExp = 'Components$';
else
    sRegExp = sprintf('Components\\(#%d\\)$', iVariantIdx);
end
ahActiveVars = i_findMatchingPathVars(sRegExp, ahCheckVars);
end


%%
function iVariantIdx = i_getActiveVariantIndex(stDataVariant)
abIsActive = (stDataVariant.currentID == stDataVariant.variants);
if ~any(abIsActive)
    % it can happen that no variant item is the active one (e.g. value of switch variable = 0 but item IDs > 0)
    % --> in this case use the first found variant as active one
    abIsActive(1) = true;
end
iVariantIdx = find(abIsActive);
end


%%
function hPoolVar = i_getPoolVar(hVar)
hPoolVar = [];
if dsdd('Exist', hVar, 'Property', {'Name', 'PoolRef'}) 
    hPoolVar = dsdd('GetPoolRefTarget', hVar);
end
end



    
