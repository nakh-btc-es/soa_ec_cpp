function sAutosarVersion = ep_ec_model_autosar_version_get(sModelName)
% Returns the AUTOSAR version of the provided (current) model. Returns an empty string for non-AUTOSAR models.
%

%%
if (nargin < 1)
    sModelName = bdroot;
end

try
    sAutosarVersion = get_param(sModelName, 'AutosarSchemaVersion');
catch
    sAutosarVersion = '';
end

% special handling for Adaptive AUTOSAR in ML2022a
if verLessThan('matlab', '9.13')
    switch sAutosarVersion
        case '00048'
            sAutosarVersion = 'R19-11';
    end
end
end

