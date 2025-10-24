function MU_pre_hook
% Define suites and tests for unit testing.
%

%%
sTmpDir = sltu_tmp_env;
sltu_coverage_backup('deactivate');

setenv('EP_DEACTIVATE_AA_VERSION_CHECK', 'true');


%% EC is not checked for ML versions lower ML2018b (9.5)
if verLessThan('matlab', '9.5')
    hSuite = MU_add_suite('simple', 0, 0, sTmpDir);
    MU_add_test(hSuite, 'Skipped', @i_issueSkippingMessage);
    return;
end

%%
hSuite = MU_add_suite('TestEnv', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EC AUTOSAR', @i_assertEcAutosar);

% --------------- AA ------------------------------------
% if ~strcmp(getenv('EP_TOGGLE_AA_SUPPORT'), 'true')
%     return;
% end

%%
hSuite = MU_add_suite('AUTOSAR Adaptive', 0, 0, sTmpDir);
MU_add_test(hSuite, 'LaneGuidance',       @ut_aa_component);
MU_add_test(hSuite, 'Pointer_Transition', @ut_aa_component_pt_trans);
MU_add_test(hSuite, 'port_identifier',    @ut_aa_port_identifier);


%%
hSuite = MU_add_suite('AUTOSAR Adaptive wrapper', 0, 0, sTmpDir);
MU_add_test(hSuite, 'event_tiny',                                @ut_aa_event_tiny);
MU_add_test(hSuite, 'client_server_sync',                        @ut_aa_client_server_sync);
MU_add_test(hSuite, 'methods_busses',                            @ut_aa_methods_busses);
MU_add_test(hSuite, 'methods_enums',                             @ut_aa_methods_enums);
MU_add_test(hSuite, 'aa_methods_multi_args',                     @ut_aa_methods_multi_args);
MU_add_test(hSuite, 'aa_stellantis_interior_lights',             @ut_aa_stellantis_interior_lights);
MU_add_test(hSuite, 'aa_stellantis_interior_lights_actuator',    @ut_aa_stellantis_interior_lights_actuator);
MU_add_test(hSuite, 'aa_nested_type_namespace',                  @ut_aa_nested_type_namespace);
MU_add_test(hSuite, 'aa_fields_simple',                          @ut_aa_fields_simple);
MU_add_test(hSuite, 'aa_stellantis_heatedseats',                 @ut_aa_stellantis_heatedseats);
MU_add_test(hSuite, 'aa_stellantis_heatedseats_wrapper',         @ut_aa_stellantis_heatedseats_23b);
MU_add_test(hSuite, 'aa_fields_client',                          @ut_aa_fields_client);
MU_add_test(hSuite, 'aa_fields_client_wrapper',                  @ut_aa_fields_client_23b);


%% main
hSuite = MU_add_suite('simple', 0, 0, sTmpDir);
MU_add_test(hSuite, 'modelcomplete',               @ut_simple_02);
MU_add_test(hSuite, 'modelbuses',                  @ut_simple_03);
MU_add_test(hSuite, 'powerwindow_modelref',        @ut_simple_04);
MU_add_test(hSuite, 'FuncsWithSubNames',           @ut_simple_05);
MU_add_test(hSuite, 'modelReferences_EC',          @ut_simple_06);
MU_add_test(hSuite, 'array_2D',                    @ut_simple_07);
MU_add_test(hSuite, 'ArrayDisp',                   @ut_simple_10);
MU_add_test(hSuite, 'arrayInsideBus',              @ut_simple_15);
MU_add_test(hSuite, 'BusesWithMatlabSystemBlocks', @ut_simple_17);
MU_add_test(hSuite, 'BusPort_EC',                  @ut_simple_18);
MU_add_test(hSuite, 'enums',                       @ut_simple_19);
%MU_add_test(hSuite, 'functioncall_generator',      @ut_simple_22);
MU_add_test(hSuite, 'modelcompletesldd',           @ut_simple_25);
MU_add_test(hSuite, 'ModelReference_withParam',    @ut_simple_26);
MU_add_test(hSuite, 'powerwindow',                 @ut_simple_27);
MU_add_test(hSuite, 'simple_buses',                @ut_simple_29);
MU_add_test(hSuite, 'SBC',                         @ut_simple_30);
MU_add_test(hSuite, 'VariantSubsystem_EC',         @ut_simple_31);
MU_add_test(hSuite, 'PreStepFunction',             @ut_preStepFunction);
MU_add_test(hSuite, 'VariantSource',               @ut_variantSource);
MU_add_test(hSuite, 'ModelRefLocals',              @ut_modelRefLocals);
MU_add_test(hSuite, 'SameParamNamesInSLDDAndInWS', @ut_sameParamNamesInSLDDAndInWS);
MU_add_test(hSuite, 'SubsystemReference',          @ut_subsystemReference);
MU_add_test(hSuite, 'small_sf_aob',                @ut_small_sf_aob);


%%
hSuite = MU_add_suite('bugs EPDEV', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EPDEV-49208', @ut_epdev_49208);
MU_add_test(hSuite, 'EPDEV-46691', @ut_epdev_46691);
MU_add_test(hSuite, 'EPDEV-47391', @ut_epdev_47391);
MU_add_test(hSuite, 'EPDEV-47622', @ut_epdev_47622);
MU_add_test(hSuite, 'EPDEV-60521', @ut_epdev_60521);
MU_add_test(hSuite, 'EPDEV-66758', @ut_epdev_66758);
MU_add_test(hSuite, 'EPDEV-71716', @ut_epdev_71716);


%%
hSuite = MU_add_suite('bugs EP', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EP-1806', @ut_ep_1806);
MU_add_test(hSuite, 'EP-1898', @ut_ep_1898);
MU_add_test(hSuite, 'EP-1912', @ut_ep_1912);
MU_add_test(hSuite, 'EP-1979', @ut_ep_1979);
MU_add_test(hSuite, 'EP-2070', @ut_ep_2070);
MU_add_test(hSuite, 'EP-2082', @ut_ep_2082);
MU_add_test(hSuite, 'EP-2132', @ut_ep_2132);
MU_add_test(hSuite, 'EP-2673', @ut_defined_param);
MU_add_test(hSuite, 'EP-3494', @ut_ep_3494);


%%
hSuite = MU_add_suite('signals', 0, 0, sTmpDir);
MU_add_test(hSuite, 'small_aob_01',       @ut_small_aob_01);
MU_add_test(hSuite, 'small_aob_02',       @ut_small_aob_02);
MU_add_test(hSuite, 'small_aob_03',       @ut_small_aob_03);
MU_add_test(hSuite, 'small_aob_04',       @ut_small_aob_04);
MU_add_test(hSuite, 'small_aob_05',       @ut_small_aob_05);
MU_add_test(hSuite, 'small_aob_07',       @ut_small_aob_07);
MU_add_test(hSuite, 'matrix_mapping_01',  @ut_matrix_mapping_01);
MU_add_test(hSuite, 'rtw_identifier',     @ut_rtw_identifier);


%%
hSuite = MU_add_suite('stubbing', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EPDEV-69288',              @ut_epdev_69288);
MU_add_test(hSuite, 'many_stubs_separate',      @ut_many_stubs_separate);
MU_add_test(hSuite, 'many_stubs_single',        @ut_many_stubs_single);
MU_add_test(hSuite, 'BusSignals',               @ut_many_stubs_bus);
MU_add_test(hSuite, 'BusSignalsPreserveDim',    @ut_many_stubs_bus_preserve_dim);


%%
hSuite = MU_add_suite('ReuseExistingCode', 0, 0, sTmpDir);
MU_add_test(hSuite, 'reuse_code_with_code',               @ut_reuse_code_with_code);
MU_add_test(hSuite, 'reuse_code_without_code',            @ut_reuse_code_without_code);
MU_add_test(hSuite, 'reuse_code_with_incomplete_code',    @ut_reuse_code_with_incomplete_code);
MU_add_test(hSuite, 'reuse_code_userpath',                @ut_reuse_code_userpath);
MU_add_test(hSuite, 'reuse_code_with_code_relocated',     @ut_reuse_code_with_code_relocated);
MU_add_test(hSuite, 'reuse_code_userpath_relocated',      @ut_reuse_code_userpath_relocated);


%%
hSuite = MU_add_suite('no filter', 0, 0, sTmpDir);
MU_add_test(hSuite, 'FuncsWithSubNames',  @ut_funcsWithSubNames_noFilter);


%%
hSuite = MU_add_suite('hierarchy', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EmptyTopRegular_EC',  @ut_emptyTopRegular);
MU_add_test(hSuite, 'MultiTopRegular_EC',  @ut_multiTopRegular);
MU_add_test(hSuite, 'MultiTopDummy_EC',    @ut_multiTopDummy);
MU_add_test(hSuite, 'SingleTopSimple',     @ut_singleTopSimple);
MU_add_test(hSuite, 'SingleTopDummy',      @ut_singleTopDummy);
MU_add_test(hSuite, 'model_ref_01',        @ut_model_ref_01);


%%
hSuite = MU_add_suite('output/update', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ExportFunctionModel',   @ut_export_function_with_update);
MU_add_test(hSuite, 'OutputUpdateFunctions', @ut_output_update_fcts);


%%
hSuite = MU_add_suite('parameters', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ConstraintsLUT',           @ut_constraintsLut);
MU_add_test(hSuite, 'simple_lut_01',            @ut_simple_lut_01);
MU_add_test(hSuite, 'simple_lut_02',            @ut_simple_lut_02);
MU_add_test(hSuite, 'model_ws_params_01',       @ut_model_ws_params_01);
MU_add_test(hSuite, 'small_mwp_01',             @ut_small_mwp_01);
MU_add_test(hSuite, 'small_mwp_02',             @ut_small_mwp_02);
MU_add_test(hSuite, 'param_saturation_relay',   @ut_param_saturation_relay);
MU_add_test(hSuite, 'param_saturation_many',    @ut_param_saturation_many);


%%
hSuite = MU_add_suite('locals', 0, 0, sTmpDir);
MU_add_test(hSuite, 'model_ref_02',  @ut_model_ref_02);


%%
hSuite = MU_add_suite('datastores', 0, 0, sTmpDir);
MU_add_test(hSuite, 'datastore',    @ut_datastore);
MU_add_test(hSuite, 'DataStore_RW', @ut_datastore_rw);
MU_add_test(hSuite, 'ds_bus_01',    @ut_ds_bus_01);
MU_add_test(hSuite, 'ds_bus_02',    @ut_ds_bus_02);


%%
hSuite = MU_add_suite('constants', 0, 0, sTmpDir);
MU_add_test(hSuite, 'Constants',          @ut_constants_ec);
MU_add_test(hSuite, 'CustomConstants',    @ut_custom_constants_ec);
MU_add_test(hSuite, 'AR_CustomConstants', @ut_custom_constants_ar);


%%
hSuite = MU_add_suite('AUTOSAR', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ar_complete_runa_all_explicit',       @ut_simple_08);
MU_add_test(hSuite, 'AR_ConfigReference',                  @ut_simple_11);
MU_add_test(hSuite, 'ar_multiruna_runa2',                  @ut_simple_12);
MU_add_test(hSuite, 'AR_MultipleSubsystemsOnWrapperModel', @ut_simple_13);
MU_add_test(hSuite, 'AR_SenderReceiverPort',               @ut_simple_14);
MU_add_test(hSuite, 'AR_powerwindow_goto',                 @ut_simple_28);
MU_add_test(hSuite, 'wrapper_ar_multiruna',                @ut_simple_32);
MU_add_test(hSuite, 'wrapper_ar_multiruna_customTLC',      @ut_simple_33);
MU_add_test(hSuite, 'wrapper_ar_complete',                 @ut_simple_34);
MU_add_test(hSuite, 'wrapper_ar_multir_spltdln_gtfrm',     @ut_simple_35);
MU_add_test(hSuite, 'wrapper_ar_multiruna_shrdinport',     @ut_simple_36);
MU_add_test(hSuite, 'AR_multi_runnable',                   @ut_ar_multiRunnable);
MU_add_test(hSuite, 'EC_demo_autosar_counter',             @ut_ec_demo_autosar_counter);
MU_add_test(hSuite, 'AR_sum_multiply',                     @ut_ar_sum_multiply);
MU_add_test(hSuite, 'AR_ServerAsSLFunction',               @ut_ar_server_as_sl_function);
MU_add_test(hSuite, 'AR_SwitchMode',                       @ut_ar_switch_mode);
MU_add_test(hSuite, 'AR_checkSupportAR4.4',                @ut_check_support_ar_4_4);
MU_add_test(hSuite, 'AR_paramCheckSupportAR4_4',           @ut_param_check_support_ar_4_4);
MU_add_test(hSuite, 'AR_paramCheckSupportAR21_11',         @ut_param_check_support_ar_21_11);
MU_add_test(hSuite, 'AR_paramCheckSupportAR22_11',         @ut_param_check_support_ar_22_11);
MU_add_test(hSuite, 'EP-2574',                             @ut_ep_2574);
MU_add_test(hSuite, 'MultiInstance',                       @ut_ar_multi_instance);
MU_add_test(hSuite, 'NestedRunnables',                     @ut_ar_nested_runnables);


%%
hSuite = MU_add_suite('AUTOSAR parameters', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ar_param_01',        @ut_ar_param_01);
MU_add_test(hSuite, 'ar_param_02',        @ut_ar_param_02);
MU_add_test(hSuite, 'ar_simple_lut_01',   @ut_ar_simple_lut_01); % Lut/Bp objects are defined in init file
MU_add_test(hSuite, 'ar_simple_lut_02',   @ut_ar_simple_lut_02); % Lut/Bp as AR parameters accesstype: PortParameter
MU_add_test(hSuite, 'ar_simple_lut_03',   @ut_ar_simple_lut_03); % Lut/Bp as AR parameters accesstype: Shared or perInstance)
MU_add_test(hSuite, 'ar_simple_lut_04',   @ut_ar_simple_lut_04); % Lut/Bp as AR parameters accesstype: ConstantMemory
MU_add_test(hSuite, 'ar_simple_lut_05',   @ut_ar_simple_lut_05);
MU_add_test(hSuite, 'ar_mw_params_01',    @ut_ar_mw_params_01);
MU_add_test(hSuite, 'ar_mwp_lut_01',      @ut_ar_mwp_lut_01);
MU_add_test(hSuite, 'EP-3091',            @ut_ep_3091); % potential replacement for 'ar_mw_params_01'


%%
hSuite = MU_add_suite('AUTOSAR stubbing', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ar_small_aob_stubbing_01',  @ut_ar_small_aob_stubbing_01);
MU_add_test(hSuite, 'ar_irv_01',                 @ut_ar_irv_01);
MU_add_test(hSuite, 'ar_irv_02',                 @ut_ar_irv_02);
MU_add_test(hSuite, 'EP-2511',                   @ut_ep_2511);
MU_add_test(hSuite, 'IncompleteInterface',       @ut_ar_incomplete);


%%
hSuite = MU_add_suite('AUTOSAR interfaces', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ar_reduced_model_qsr',  @ut_ar_reduced_model_qsr);
MU_add_test(hSuite, 'ar_model_qsr',          @ut_ar_model_qsr);


%%
hSuite = MU_add_suite('AUTOSAR wrapper', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ClientExample',                    @ut_client_example);
MU_add_test(hSuite, 'ClientServerExample',              @ut_client_server_example);
MU_add_test(hSuite, 'ServerExample',                    @ut_server_example);
MU_add_test(hSuite, 'ServerExample2',                   @ut_server_example2);
MU_add_test(hSuite, 'complete_ar_client',               @ut_complete_ar_client);
MU_add_test(hSuite, 'complete_ar_multiruna_shrdinport', @ut_complete_ar_multiruna_shrdinport);
MU_add_test(hSuite, 'complete_ar_server',               @ut_complete_ar_server);
MU_add_test(hSuite, 'EPDEV-66803',                      @ut_epdev_66803);


%%
hSuite = MU_add_suite('AUTOSAR wrapper create', 0, 0, sTmpDir);
MU_add_test(hSuite, 'AR_multi_runnable',                    @ut_w_ar_multiRunnable);
MU_add_test(hSuite, 'ClientExample',                        @ut_w_client_example);
MU_add_test(hSuite, 'ClientWithoutIO',                      @ut_w_client_without_io);
MU_add_test(hSuite, 'ClientServerExample',                  @ut_w_client_server_example);
MU_add_test(hSuite, 'ServerExample',                        @ut_w_server_example);
MU_add_test(hSuite, 'ServerExample2',                       @ut_w_server_example2);
MU_add_test(hSuite, 'InterfacesClientServer',               @ut_w_interfaces_client_server);
MU_add_test(hSuite, 'AR_enums_clientServer',                @ut_w_enums_clientServer);
MU_add_test(hSuite, 'AR_dynamic_enums',                     @ut_w_dynamic_enums);
MU_add_test(hSuite, 'complete_ar_multiruna_shrdinport',     @ut_w_complete_ar_multiruna_shrdinport);
MU_add_test(hSuite, 'complete_ar_runa_all_explicit',        @ut_w_complete_ar_runa_all_explicit);
MU_add_test(hSuite, 'AR_ArrayOfBuses',                      @ut_w_ar_aob);
MU_add_test(hSuite, 'EP-2945',                              @ut_w_simple_runnable);
MU_add_test(hSuite, 'small_ar_cs_aobs',                     @ut_w_small_ar_cs_aob);
MU_add_test(hSuite, 'small_ar_aobs_client',                 @ut_w_small_ar_client_aob);
MU_add_test(hSuite, 'small_cs_simulink_param_dimensions',   @ut_w_small_cs_simulink_param_dimensions);
MU_add_test(hSuite, 'ar_client_server_fxp',                 @ut_w_ar_client_server_fxp);
MU_add_test(hSuite, 'ar_activated_runnables_01',            @ut_w_activated_runnables_01);
MU_add_test(hSuite, 'ar_activated_runnables_02',            @ut_w_activated_runnables_02);
MU_add_test(hSuite, 'ar_mw_params_01',                      @ut_w_ar_mw_params_01);
MU_add_test(hSuite, 'ar_very_long_name',                    @ut_ar_very_long_name);
MU_add_test(hSuite, 'EP2877_event_name',                    @ut_w_scheduler_event_name);
MU_add_test(hSuite, 'EP-2877',                              @ut_w_ep_2877);
MU_add_test(hSuite, 'InternallyTriggeredRunnables',         @ut_w_int_trig_runnables);
MU_add_test(hSuite, 'BooleanIdentifierSettings',            @ut_w_boolean_settings);
MU_add_test(hSuite, 'EP-3110',                              @ut_w_ep_3110);
MU_add_test(hSuite, 'MultiInstanceClient',                  @ut_w_client_multi_instance);
MU_add_test(hSuite, 'MultiInstance_EPDEV-75159',            @ut_w_multi_instance_epdev_75159);
MU_add_test(hSuite, 'CallerBusIF',                          @ut_w_caller_bus_if);
MU_add_test(hSuite, 'EP-3333',                              @ut_w_ep_3333);
MU_add_test(hSuite, 'CallerArrayInterfaces',                @ut_w_ar_cs_arrays);


%%
hSuite = MU_add_suite('AUTOSAR wrapper reuse code', 0, 0, sTmpDir);
MU_add_test(hSuite, 'complete_ar_client_reusecode',        @ut_w_complete_ar_client_reusecode);
MU_add_test(hSuite, 'complete_ar_server_reusecode',        @ut_w_complete_ar_server_reusecode);


%%
hSuite = MU_add_suite('AUTOSAR rate based', 0, 0, sTmpDir);
MU_add_test(hSuite, 'RateBasedOneRunnableWithClient',   @ut_ar_rate_based_client);
MU_add_test(hSuite, 'RateBasedMultiRunnable',           @ut_ar_rate_based_multi_runnable);
MU_add_test(hSuite, 'RateBasedMultiRunnableWrapper',    @ut_ar_rate_based_multi_runnable_wrapper);


%%
hSuite = MU_add_suite('Limitations', 0, 0, sTmpDir);
MU_add_test(hSuite, 'LimitationInt64',         @ut_data_type_int64_ec);
MU_add_test(hSuite, 'LimitationInt64_R2020a',  @ut_data_type_int64_ec_r2020a);
MU_add_test(hSuite, 'EP-1988',                 @ut_ep_1988);


%%
hSuite = MU_add_suite('SL SIL', 0, 0, sTmpDir);
MU_add_test(hSuite, 'datastore',                @ut_sl_sil_analysis_01);
MU_add_test(hSuite, 'AR_SenderReceiverPort',    @ut_sl_sil_analysis_02);
MU_add_test(hSuite, 'Powerwindow',              @ut_sl_sil_analysis_03);
MU_add_test(hSuite, 'wrapper_exportfunc_slsil', @ut_sl_sil_analysis_04);
MU_add_test(hSuite, 'ModelRefLocals',           @ut_sl_sil_analysis_05);
MU_add_test(hSuite, 'ModelWorkspace',           @ut_sl_sil_analysis_06);


%%
hSuite = MU_add_suite('diagnostics', 0, 0, sTmpDir);
MU_add_test(hSuite, 'datastore',                      @ut_diagnostics_01);
MU_add_test(hSuite, 'ar_complete_runa_all_explicit',  @ut_diagnostics_02);


%%
hSuite = MU_add_suite('hooks', 0, 0, sTmpDir);
MU_add_test(hSuite, 'registry',                  @ut_hooks_registry);
MU_add_test(hSuite, 'merge',                     @ut_settings_merge);
MU_add_test(hSuite, 'simple',                    @ut_hooks_simple);
MU_add_test(hSuite, 'autosar',                   @ut_hooks_autosar);
MU_add_test(hSuite, 'wrapper_autosar',           @ut_hooks_wrapper_autosar);
MU_add_test(hSuite, 'legacy_wrapper_autosar',    @ut_hooks_legacy_wrapper_autosar);
MU_add_test(hSuite, 'SL SIL',                    @ut_hooks_sl_sil);
MU_add_test(hSuite, 'hooks_eval_error',          @ut_hook_eval_error);


%%
hSuite = MU_add_suite('MatchGraphicalInterface', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ds_bus_01_matchGraphItf',              @ut_ds_bus_01_matchGraphItf);
MU_add_test(hSuite, 'pw_matchGraphItf',                     @ut_pw_matchGraphItf);
MU_add_test(hSuite, 'datastore_matchGraphItf',              @ut_datastore_matchGraphItf);
MU_add_test(hSuite, 'model_ref_matchGraphItf',              @ut_model_ref_matchGraphItf);
MU_add_test(hSuite, 'ep_2969_matchGraphItf',                @ut_ep_2969_matchGraphItf);
MU_add_test(hSuite, 'export_function_matchGraphItf',        @ut_export_function_matchGraphItf);

setenv('EP_DEACTIVATE_AA_VERSION_CHECK', 'false');

end


%%
function i_issueSkippingMessage()
MU_MESSAGE('EC functionality not checked for ML-versions lower ML2019a. Intentionally skipping all tests.');
end


%%
function i_assertEcAutosar
bAutosarAvailable = SLTU_ASSUME_EC_AUTOSAR;
MU_ASSERT_TRUE(bAutosarAvailable, 'EC AUTOSAR cannot be tested.')
end
