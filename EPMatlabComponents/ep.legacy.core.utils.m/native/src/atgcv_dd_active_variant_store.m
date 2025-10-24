function atgcv_dd_active_variant_store(sVariant)
% Store variant name in user_data section of current DD.
%
% function atgcv_dd_active_variant_store(sVariant)
%
%
%   INPUT               DESCRIPTION
%     sVariant            (string)       (optional) name of active variant to 
%                                        be stored
%                                        (if omitted, the current active variant
%                                        is used)
%
%
%   OUTPUT              DESCRIPTION
%
%     
%   REMARKS
%     For TL-versions below TL2.2 the active variant is not stored in the DD
%     but has to be activated manually by the user. To facilitate this, OSC
%     stores the last active variant in a user_data field inside the DD.
%     This function stores the name of the variant.
%     
%   <et_copyright>

%% internal 
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alexander.Hornstein@osc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 48234 $
%   Last modified: $Date: 2009-01-22 11:02:42 +0100 (Do, 22 Jan 2009) $ 
%   $Author: ahornste $
%

%% shortcut for TL2.2 and higher
% AH: For TL2.2 and higher the active variant is stored by the DD itself.
if (atgcv_version_compare('TL2.2') >= 0)
    return;
end

%% input check
if (nargin < 1) 
    sVariant = '';
    hVariant = dsdd('GetCurrentVariantConfig');
    if ~isempty(hVariant)
        sVariant = dsdd('GetAttribute', hVariant, 'Name');
    end    
else
    if ~ischar(sVariant)
        error('ATGCV:MXX:USAGE_ERROR', ...
            'Function argument has to be a string.');
    end
    if ~isempty(sVariant)
        ahConfigs = dsdd('Find', '/Config/VariantConfigs', ...
            'objectKind', 'VariantConfig');
        nConfigs = length(ahConfigs);
        casAllowedVariants = cell(1, nConfigs);
        for i = 1:nConfigs
            casAllowedVariants{i} = dsdd('GetAttribute', ahConfigs(i), 'Name');
        end
        if ~any(strcmp(sVariant, casAllowedVariants))
            error('ATGCV:MXX:UNKNOWN_VARIANT', ...
                'Variant "%s" is not among the list of allowed variants.', sVariant);
        end
    end
end

%% main
sUserData = 'OscUserData';
sVariantProperty = 'ActiveVariant';

[bExist, hUserData] = dsdd('Exist', sUserData);
if ~bExist
    hUserData = dsdd('AddUserData', '/', sUserData);
end    
dsdd('Set', hUserData, sVariantProperty, sVariant);

%% end
return;

