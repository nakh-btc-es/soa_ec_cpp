function stConfig = ep_variant_config_get()
% Get info about the currently active variant config.
%
%  function stConfig = ep_variant_config_get()
%
%   INPUT           DESCRIPTION
%
%   OUTPUT          DESCRIPTION
%     stConfig           (struct)        info structure
%
%       .astCodeVariants  (array)         array with following structs
%        stCodeVariant     (struct)   
%           .name                  (string)     name of CodeVariant item
%           .variant               (integer)    ID of CodeVariant item
%
%       .astDataVariants         (array)     array with following structs
%        stDataVariant           (struct)
%           .dataVariantName        (string)     name of DataVariant 
%           .currentID              (integer)    currently active DataVariant ID
%           .variantItemNames       (cell)       strings with the names of the
%                                                DataVariant items
%           .variants               (array)      integers with the IDs of the
%                                                DataVariant items
%           .dataVariantCodingStyle (string)     CodingStyle of DataVariant
%       ...
%


%% 
% default output
stConfig = struct();

% shortcut if no variant active
hActiveVariant = dsdd('GetCurrentVariantConfig');
if isempty(hActiveVariant)
    return;
end

% read out code variants
astCodeVariants = dsdd('GetCodeVariants');
if ~isempty(astCodeVariants)
    stConfig.astCodeVariants = astCodeVariants;
end

% read out data variants
astDataVariants = dsdd('GetDataVariants');
if ~isempty(astDataVariants)
    nVariants = length(astDataVariants);
    for i = 1:nVariants
        hDataVariant = dsdd('Find', hActiveVariant, ...
            'objectKind', 'DataVariant', ...
            'name', astDataVariants(i).dataVariantName);
        astDataVariants(i).dataVariantCodingStyle = dsdd('GetVariantCodingStyle', hDataVariant);
    end
    stConfig.astDataVariants = astDataVariants;
end
end

