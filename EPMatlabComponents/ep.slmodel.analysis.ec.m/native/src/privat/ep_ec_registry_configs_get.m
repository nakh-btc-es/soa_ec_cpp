function stReg = ep_ec_registry_configs_get()
% Returns all known configurations and the corresponding default value function.
%
% stReg = ep_ec_registry_configs_get()
%
%  OUTPUT            DESCRIPTION
%
%  - stReg          The known configurations with their default value function
%

%%
stReg = struct( ...
    'ecacfg_analysis_autosar',   'ep_ec_ecacfg_analysis_autosar_config_get', ...
    'ecacfg_analysis',           'ep_ec_ecacfg_analysis_config_get', ...
    'ecacfg_codeformat_autosar', 'ep_ec_ecacfg_codeformat_autosar_config_get', ...
    'ecacfg_codeformat',         'ep_ec_ecacfg_codeformat_config_get');
end