function stConfig = atgcv_m01_variant_config_get(stEnv)
% get info about the currently active variant config
%
%  stConfig = atgcv_m01_variant_config_get(stEnv)
%   INPUT           DESCRIPTION
%     stEnv             (struct)       environment structure
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
%   REMARKS
%
%   (c) 2008 by OSC Embedded Systems AG, Germany

%% internal
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 193915 $
%   Last modified: $Date: 2015-02-13 14:17:33 +0100 (Fr, 13 Feb 2015) $
%   $Author: frederikb $
%

%% default:
stConfig = struct();

%% shortcut if no variant active
hActiveVariant = atgcv_mxx_dsdd(stEnv, 'GetCurrentVariantConfig');
if isempty(hActiveVariant)
    return;
end

%% read out code variants
astCodeVariants = dsdd('GetCodeVariants');
if ~isempty(astCodeVariants)
    stConfig.astCodeVariants = astCodeVariants;
end

%% read out data variants
astDataVariants = dsdd('GetDataVariants');
if ~isempty(astDataVariants)
    nVariants = length(astDataVariants);
    for i = 1:nVariants
        hDataVariant = atgcv_mxx_dsdd(stEnv, 'Find', hActiveVariant, ...
            'objectKind', 'DataVariant', ...
            'name', astDataVariants(i).dataVariantName);
        astDataVariants(i).dataVariantCodingStyle = atgcv_mxx_dsdd(stEnv, ...
            'GetVariantCodingStyle', hDataVariant);
    end
    stConfig.astDataVariants = astDataVariants;
end
end

