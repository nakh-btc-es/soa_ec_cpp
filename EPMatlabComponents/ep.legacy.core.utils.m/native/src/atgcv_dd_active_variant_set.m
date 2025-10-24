function atgcv_dd_active_variant_set(sVariant)
% Set active variant of current DD to predefined and internally stored value.
%
% function atgcv_dd_active_variant_set(sVariant)
%
%
%   INPUT               DESCRIPTION
%     sVariant            (string)       (optional) name of variant to 
%                                        be activated
%                                        (if omitted, the internally stored
%                                        active variant is used)
%
%
%   OUTPUT              DESCRIPTION
%
%     
%   REMARKS
%     For TL-versions below TL2.2 the active variant is not stored in the DD
%     but has to be activated manually by the user. To facilitate this, OSC
%     stores the last active variant in a user_data field inside the DD.
%     This function acivates the stored variant for the corresponding DD if
%     it is currently loaded.
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

%% main
if (nargin < 1)
    sUserData = '/OscUserData';
    sVariantProperty = 'ActiveVariant';

    if dsdd('Exist', sUserData) && ...
            dsdd('Exist', sUserData, 'Property', sVariantProperty)
        sVariant = dsdd('Get', sUserData, sVariantProperty);
        dsdd('SetEnv', 'ActiveVariant', sVariant);
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
    dsdd('SetEnv', 'ActiveVariant', sVariant);
end

%% end
return;


