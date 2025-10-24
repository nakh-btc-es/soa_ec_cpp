function ut_hooks_registry
% Testing the hook/configuration functionality on low level.
%


%% prepare test
sltu_cleanup();


%% configs
stExpConfigs = struct( ...
    'ecacfg_analysis_autosar',   'ep_ec_ecacfg_analysis_autosar_config_get', ...
    'ecacfg_analysis',           'ep_ec_ecacfg_analysis_config_get', ...
    'ecacfg_codeformat_autosar', 'ep_ec_ecacfg_codeformat_autosar_config_get', ...
    'ecacfg_codeformat',         'ep_ec_ecacfg_codeformat_config_get');

stFoundConfigs = ep_ec_registry_configs_get();
i_assertConfigsValid(stExpConfigs, stFoundConfigs);


%% hooks
stExpHooks = struct( ...
    'ecahook_autosar_wrapper_function_info', 'ep_ec_ecahook_autosar_wrapper_function_info_config_get', ...
    'ecahook_simulationtime_get_fun',        'ep_ec_ecahook_simulationtime_get_fun_config_get', ...
    'ecahook_legacy_code',                   'ep_ec_ecahook_legacy_code_config_get', ...
    'ecahook_ignore_code',                   'ep_ec_ecahook_ignore_code_config_get', ...
    'ecahook_param_blacklist',               'ep_ec_ecahook_param_blacklist_config_get', ...
    'ecahook_stub_include_files',            'ep_ec_ecahook_stub_include_files_config_get', ...
    'ecahook_post_wrapper_create',           '', ...
    'ecahook_post_analysis',                 '', ...
    'ecahook_pre_analysis',                  '');

stFoundHooks = ep_ec_registry_hooks_get();
i_assertHooksValid(stExpHooks, stFoundHooks);
end


%%
function i_assertConfigsValid(stExpConfigs, stFoundConfigs)
SLTU_ASSERT_STRINGSET_CONTAINS(fieldnames(stExpConfigs), fieldnames(stFoundConfigs), ...
    'Not all expected configs have been found.')

casFoundConfigNames = fieldnames(stFoundConfigs);
for i = 1:numel(casFoundConfigNames)
    sName = casFoundConfigNames{i};
    
    if isfield(stExpConfigs, sName)
        sExpDefault = stExpConfigs.(sName);
        sFoundDefault = stFoundConfigs.(sName);
        
        if strcmp(sExpDefault, sFoundDefault)
            SLTU_ASSERT_TRUE(exist(sFoundDefault, 'file'), ...
                'Config "%s": Default "%s" not available.', sName, sFoundDefault);
        else
            SLTU_FAIL('Config "%s": Expected "%s" instead of "%s" as default.', ...
                sName, sExpDefault, sFoundDefault);
        end
    else
        SLTU_FAIL('Found unexpected config "%s".', sName);
    end
end
end


%%
function i_assertHooksValid(stExpHooks, stFoundHooks)
SLTU_ASSERT_STRINGSET_CONTAINS(fieldnames(stExpHooks), fieldnames(stFoundHooks), ...
    'Not all expected hooks have been found.')

casFoundConfigNames = fieldnames(stFoundHooks);
for i = 1:numel(casFoundConfigNames)
    sName = casFoundConfigNames{i}; 
    if isfield(stExpHooks, sName)
        sExpDefault = stExpHooks.(sName);
        sFoundDefault = stFoundHooks.(sName);
        
        if strcmp(sExpDefault, sFoundDefault)
            if ~isempty(sFoundDefault)
                SLTU_ASSERT_TRUE(exist(sFoundDefault, 'file'), ...
                    'Hook "%s": Default "%s" not available.', sName, sFoundDefault);
            end
        else
            SLTU_FAIL('Hook "%s": Expected "%s" instead of "%s" as default.', ...
                sName, sExpDefault, sFoundDefault);
        end
    else
        SLTU_FAIL('Found unexpected hook "%s".', sName);
    end
end
end
