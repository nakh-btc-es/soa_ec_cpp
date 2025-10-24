function astConstants = getConstants(oEca, astParams)
% Filtering out suitable Constants from a list of parameters used by the model.
%

%%
stActiveConfig = oEca.getActiveConfig();
casCustomClassesWhitelist = stActiveConfig.CustomConstantStorageClasses;

stConst = struct( ...
    'sName',  '', ...
    'xValue', '');
astConstants = repmat(stConst, 1, 0);
for i = 1:numel(astParams)
    stParam = astParams(i);
        
    % TODO: The filter criteria (Custom StorageClass with whitelist CustomStorageClasses) are currently fixed but might 
    %       be later exendend by  customizable mechanisms (e.g. hooks).
    stCoderInfo = stParam.stCoderInfo;
    bHasCustomStorageClass = strcmp(stCoderInfo.sStorageClass, 'Custom');
    if ~bHasCustomStorageClass
        continue;
    end
    bIsInWhitelist = ismember(stCoderInfo.sCustomStorageClass, casCustomClassesWhitelist);
    if ~bIsInWhitelist
        continue;
    end
    
    % only scalars accepted
    bIsScalar = prod(stParam.aiWidth) == 1;
    if ~bIsScalar
        continue;
    end
    
    % only non-empty, numerical values accepted
    bIsNonEmptyNumerical = ~isempty(stParam.xValue) && (isnumeric(stParam.xValue) || islogical(stParam.xValue));
    if ~bIsNonEmptyNumerical
        continue;
    end
        
    % accepted as Constant
    stConst.sName  = stParam.sRawName;
    stConst.xValue = stParam.xValue;
    astConstants(end + 1) = stConst; %#ok<AGROW>
end
end

