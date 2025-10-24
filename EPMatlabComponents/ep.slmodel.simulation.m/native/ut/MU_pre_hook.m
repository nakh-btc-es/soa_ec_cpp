function MU_pre_hook
% Define suites and tests for unit testing.

%%
sTmpDir = sltu_tmp_env;

%%
hSuite = MU_add_suite('Basics', 0, 0, sTmpDir);
%MU_add_test(hSuite, 'BASIC_TEST_001',      @it_ep_pil_configs_get);  TODO: needs to be transferred to TL module
MU_add_test(hSuite, 'BASIC_TEST_002',      @it_slmil_simplebc_sl);
MU_add_test(hSuite, 'BASIC_TEST_003',      @it_slmil_LUTModel);
MU_add_test(hSuite, 'BASIC_TEST_004',      @it_slmil_LUTModel_2d);
MU_add_test(hSuite, 'BASIC_TEST_005',      @it_slmil_SFInheritParam);
MU_add_test(hSuite, 'BASIC_TEST_006',      @it_slmil_SignalInjection);
MU_add_test(hSuite, 'BASIC_TEST_007',      @it_slmil_input_constraints);
MU_add_test(hSuite, 'BASIC_TEST_008',      @it_slmil_invalid_input_constraints);
MU_add_test(hSuite, 'BASIC_TEST_009',      @it_slmil_SameParamNamesInSLDDAndInWS);
MU_add_test(hSuite, 'BASIC_TEST_010',      @it_slmil_MainModelWithoutDD_RefModelWithParamsInDD);
MU_add_test(hSuite, 'BASIC_TEST_013',      @it_slmil_adder);
%MU_add_test(hSuite, 'BASIC_TEST_014',      @it_ep_test_slmdl_error_sil_pil); TODO: needs to be transferred to TL module
MU_add_test(hSuite, 'BASIC_TEST_015',      @it_slmil_sl_dd_param);
MU_add_test(hSuite, 'BASIC_TEST_016',      @it_slmil_enabled_subs);
MU_add_test(hSuite, 'BASIC_TEST_017',      @it_slmil_if_else);
MU_add_test(hSuite, 'BASIC_TEST_018',      @it_slmil_resettable_subs);
MU_add_test(hSuite, 'BASIC_TEST_019',      @it_slmil_triggered_subs);
MU_add_test(hSuite, 'MinMax',              @it_slmil_minmax);
MU_add_test(hSuite, 'PowerWindow_Root',    @it_slmil_pw_root);
MU_add_test(hSuite, 'PowerWindow_PWC',     @it_slmil_pw_pwc);
%MU_add_test(hSuite, 'STRESS_TEST_001',     @it_ep_stress_test_vecs); TODO: needs to be transferred to TL module
%MU_add_test(hSuite, 'PROM_6182',           @it_ep_prom_6182); TODO: needs to be replaced
MU_add_test(hSuite, 'EP-675',              @it_ep_ep_675);
MU_add_test(hSuite, 'EP-720',              @ut_ep_simenv_clear_base);
MU_add_test(hSuite, 'BASIC_TEST_020',      @it_slmil_SL_LUT_BP);
MU_add_test(hSuite, 'SimulinkFunctions',   @it_simulink_functions);


%%
hSuite = MU_add_suite('Matrix', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MatrixComplex1',   @it_slmil_matrix_complex1);
MU_add_test(hSuite, 'MatrixComplex2',   @it_slmil_matrix_complex2);
MU_add_test(hSuite, 'MatrixComplex3',   @it_slmil_matrix_complex3);
MU_add_test(hSuite, 'MatrixComplex4',   @it_slmil_matrix_complex4);
MU_add_test(hSuite, 'MatrixComplex5',   @it_slmil_matrix_complex5);
MU_add_test(hSuite, 'MatrixChart',      @it_slmil_matrix_chart);
MU_add_test(hSuite, 'MatrixChart1',     @it_slmil_matrix_chart1);
MU_add_test(hSuite, 'EP-1176',          @it_slmil_signal_matrix_as_scalar);


%%
hSuite = MU_add_suite('ModelReferences', 0, 0, sTmpDir);
MU_add_test(hSuite, 'TopLevel',           @it_slmil_modelref_toplevel);
MU_add_test(hSuite, 'Reference',          @it_slmil_modelref_reference);
MU_add_test(hSuite, 'SubWithinReference', @it_slmil_modelref_subwithinref);
MU_add_test(hSuite, 'NestedLogging',      @ut_sim_nested_logging);
MU_add_test(hSuite, 'MergeBlocks',        @ut_sim_merge_blocks);
MU_add_test(hSuite, 'BreakLayers',        @ut_modelref_break_layers);


%%
hSuite = MU_add_suite('Bus', 0, 0, sTmpDir);
MU_add_test(hSuite, 'BusPortsChart',                 @it_slmil_busports_chart);
MU_add_test(hSuite, 'NestedBusPortsTop',             @it_slmil_nestedbusports_top);
MU_add_test(hSuite, 'BusPorts_TopLevel',             @it_slmil_busports_toplevel);
MU_add_test(hSuite, 'VirtualBusSLDDModelLevel',      @it_slmil_virtual_bus_model_level);
MU_add_test(hSuite, 'VirtualBusSLDDSubsystem',       @it_slmil_virtual_bus_subsystem);
MU_add_test(hSuite, 'BusAliasTypeSLDDAndWSModLev',   @it_slmil_bus_alias_model_level);
MU_add_test(hSuite, 'BusAliasTypeSLDDAndWSSub',      @it_slmil_bus_alias_subsystem);
MU_add_test(hSuite, 'FxpInBus',                      @ut_slmil_fxp_in_bus);


%%
hSuite = MU_add_suite('DataStores', 0, 0, sTmpDir);
MU_add_test(hSuite, 'DsmModel',         @it_slmil_dsm_model);
MU_add_test(hSuite, 'DsmSimpleInputs',  @it_slmil_dsm_simple_in);
MU_add_test(hSuite, 'DsmSimpleOutputs', @it_slmil_dsm_simple_out);
MU_add_test(hSuite, 'DsmMatrixIn',      @it_slmil_dsm_matrix_in);
MU_add_test(hSuite, 'DsmArrayOut',      @it_slmil_dsm_array_out);
MU_add_test(hSuite, 'DSM_SHADOWING',    @it_slmil_DSMShadowing);
MU_add_test(hSuite, 'DSM_EPDEV37155',   @it_slmil_DSM_EPDEV_37155);
MU_add_test(hSuite, 'DSM_MATRIX',       @it_slmil_DSMMatrix);
MU_add_test(hSuite, 'DSM_MULTI_OUT',    @it_slmil_DSMOuputs);
MU_add_test(hSuite, 'DsmBus01',         @ut_dsm_bus_01);
MU_add_test(hSuite, 'DsmBus02',         @ut_dsm_bus_02);
MU_add_test(hSuite, 'DsmBus03',         @ut_dsm_bus_03);
% MU_add_test(hSuite, 'DSM_IN_OUT',       @it_ep_test_extrmod_dsm_05);%EPDEV-51926


%%
hSuite = MU_add_suite('FixedPoint', 0, 0, sTmpDir);
MU_add_test(hSuite, 'FIXDT_TEST_001',    @it_slmil_fixedpoint);
MU_add_test(hSuite, 'FIXDT_TEST_002',    @it_slmil_fixedpoint1);
MU_add_test(hSuite, 'FIXDT_TEST_003',    @it_slmil_fixedpoint2);
MU_add_test(hSuite, 'FIXDT_TEST_CASTS',  @it_slmil_fixedpoint_casts);
MU_add_test(hSuite, 'FIXDT_OVERRIDE',    @it_slmil_fixedpoint_override);


%%
hSuite = MU_add_suite('SubsystemReferences', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SUBREF_001',      @it_slmil_subref);
MU_add_test(hSuite, 'SUBREF_002',      @it_slmil_subRef1);


%%
hSuite = MU_add_suite('Locals', 0, 0, sTmpDir);
MU_add_test(hSuite, 'LocalsSimple',        @it_slmil_locals_simple);
MU_add_test(hSuite, 'LocalsArrays',        @it_slmil_locals_arrays);
MU_add_test(hSuite, 'LocalsMatrix',        @it_slmil_locals_matrix);
MU_add_test(hSuite, 'LocalsVirtualBuses',  @it_slmil_locals_virtual_bus);
MU_add_test(hSuite, 'LocalsTriggeredSubs', @it_slmil_locals_trig_subs);
MU_add_test(hSuite, 'LocalsStateflow',     @it_slmil_locals_stateflow);
MU_add_test(hSuite, 'LocalsEnum',          @it_slmil_locals_enum);


%%
hSuite = MU_add_suite('Enums', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EnumSLDD',             @it_slmil_enum_sldd_top);
MU_add_test(hSuite, 'EnumSLDDSub',          @it_slmil_enum_sldd_sub);
MU_add_test(hSuite, 'EnumSLDDWS',           @it_slmil_enum_sldd_ws_top);
MU_add_test(hSuite, 'EnumSLDDWSSub',        @it_slmil_enum_sldd_ws_sub);
MU_add_test(hSuite, 'SimpleEnum',           @it_slmil_simple_enum);
MU_add_test(hSuite, 'SimpleEnumParam',      @it_slmil_simple_enum_param);
MU_add_test(hSuite, 'EnumSLDD:Error',       @ut_slmil_error_enum_sldd_top);
MU_add_test(hSuite, 'EnumSLDD:Alias',       @ut_slmil_enums_and_alias_sldd);
MU_add_test(hSuite, 'EnumSLDD:StorageType', @ut_slmil_enum_storage_type);


%%
hSuite = MU_add_suite('Interactive', 0, 0, sTmpDir);
MU_add_test(hSuite, 'IT_SIM_INTERACTIVE_0',     @it_ep_minmax_sl_interactive_simulation);
MU_add_test(hSuite, 'IT_SIM_INTERACTIVE_1',     @it_ep_simplebc_sl_interactive_simulation);
MU_add_test(hSuite, 'IT_SIM_INTERACTIVE_ENUMS', @it_ep_enumsSLDD_sl_interactive_simulation);


%%
hSuite = MU_add_suite('Bugs', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EPDEV-39554', @ut_ep_attr_startIdx_is_valid);
MU_add_test(hSuite, 'EPDEV-44882', @it_epdev_44882);
MU_add_test(hSuite, 'EP-2018',     @it_ep_extraction_multi_rated_runnables);
MU_add_test(hSuite, 'EPDEV-52678', @it_ep_dev_52678);
MU_add_test(hSuite, 'EPDEV-52964', @it_ep_dev_52964);
MU_add_test(hSuite, 'EP-2227',     @ut_ep_2227);
MU_add_test(hSuite, 'EP-2902',     @ut_ep_2902);
MU_add_test(hSuite, 'EP-2979',     @ut_ep_2979);
MU_add_test(hSuite, 'EP-3342',     @ut_ep_3342);
MU_add_test(hSuite, 'EP-3391',     @ut_ep_3391);
MU_add_test(hSuite, 'EP-3434',     @ut_ep_3434);


%%
hSuite = MU_add_suite('Stateflow', 0, 0, sTmpDir);
MU_add_test(hSuite, 'parent_sf_data:parent_sf_data',   @ut_parent_sf_data);
MU_add_test(hSuite, 'parent_sf_data:sub_A',            @ut_parent_sf_data_sub_A);


%%
hSuite = MU_add_suite('ModelWorkspace', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ModelWorkspace:main',             @ut_model_workspace_main);
MU_add_test(hSuite, 'ModelWorkspace:Model',            @ut_model_workspace_Model);
MU_add_test(hSuite, 'ModelWorkspace:sub_K',            @ut_model_workspace_sub_K);
MU_add_test(hSuite, 'ModelWorkspaceSlFunc:lowest_sub', @ut_model_workspace_slfunc_lowest_sub);
MU_add_test(hSuite, 'ModelArgLut',                     @ut_model_arg_lut);


%%
hSuite = MU_add_suite('Variants', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SLMIL_VARIANT_001', @it_slmil_vs_top);
MU_add_test(hSuite, 'SLMIL_VARIANT_002', @it_slmil_vs_variants);
MU_add_test(hSuite, 'SLMIL_VARIANT_003', @it_slmil_vs_controller);
MU_add_test(hSuite, 'EP-1300',           @it_ep_1300);


%%
hSuite = MU_add_suite('SL-SIL', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SL_SIL_01',    @it_ec_slsil_topmodelref);
MU_add_test(hSuite, 'SL_SIL_02',    @it_ec_slsil_simplemodel);
MU_add_test(hSuite, 'SL_SIL_03',    @it_ec_slsil_lowermodelref);
MU_add_test(hSuite, 'SL_SIL_04',    @it_ec_slsil_modelbuses);
MU_add_test(hSuite, 'SL_SIL_05',    @it_ec_slsil_virtualbuses);
MU_add_test(hSuite, 'SL_SIL_Enum',  @it_ec_slsil_enum);


%%
hSuite = MU_add_suite('Derive', 0, 0, sTmpDir);
MU_add_test(hSuite, 'PWC_Derive',                        @it_slmil_derive_pw_pwc);
MU_add_test(hSuite, 'DsmMatrixIn_Derive',                @it_slmil_derive_dsm_matrix);
MU_add_test(hSuite, 'DSMsDrivenByTheSameInput_Derive',   @it_slmil_derive_dsm_same_input);
MU_add_test(hSuite, 'DSMsInNestedSubsystems_Derive',     @it_slmil_derive_dsm_nested_subs);
MU_add_test(hSuite, 'Matrix_Derive',                     @it_slmil_derive_matrix);
MU_add_test(hSuite, 'ModelRef_Derive',                   @it_slmil_derive_model_ref);
MU_add_test(hSuite, 'Bus_Derive',                        @it_slmil_derive_bus);
MU_add_test(hSuite, 'TriggeredSubs_Derive',              @it_slmil_derive_triggered_subs);
MU_add_test(hSuite, 'Stateflow_Derive',                  @it_slmil_derive_stateflow);


%%
hSuite = MU_add_suite('Debug', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SimpleBurner',                              @ut_debug_simple_burner);
MU_add_test(hSuite, 'PowerWindow',                               @ut_debug_power_window);
MU_add_test(hSuite, 'MultiTopRegular',                           @ut_debug_multi_top_regular);
MU_add_test(hSuite, 'SameParamNamesInSLDDAndInWS',               @ut_debug_same_param_name);
MU_add_test(hSuite, 'MainModelWithoutDD_RefModelWithParamsInDD', @ut_debug_main_ref_model_dd);
MU_add_test(hSuite, 'debugModel',                                @ut_debug_debug_model);
MU_add_test(hSuite, 'ModelRef_NotSelfContainedDebug',            @ut_debug_model_ref_nsc_debug);
MU_add_test(hSuite, 'wrapper_ar_multi_rated_runnables',          @ut_debug_wrapper_ar_multi_rated_runnables);
MU_add_test(hSuite, 'nonVirtualBusLabel',                        @ut_debug_nonVirtualBusLabel);
MU_add_test(hSuite, 'ModelWorkspace',                            @ut_debug_model_workspace);
MU_add_test(hSuite, 'sl_funcs_05',                               @ut_sl_funcs_05);


%%
hSuite = MU_add_suite('ArrayOfBuses', 0, 0, sTmpDir);
MU_add_test(hSuite, 'AoB.001', @it_slmil_array_of_buses_top);
MU_add_test(hSuite, 'AoB.002', @it_slmil_array_of_buses_sub);
MU_add_test(hSuite, 'AoB.003', @it_slmil_array_of_buses_selector);
MU_add_test(hSuite, 'AoB.004', @it_slmil_array_of_buses1);
MU_add_test(hSuite, 'AoB.005', @it_slmil_array_of_buses2);


%%
hSuite = MU_add_suite('SL-TOP', 0, 0, sTmpDir);
MU_add_test(hSuite, 'virtual_bus_top',       @ut_virtual_bus_top);
MU_add_test(hSuite, 'enums_bus_top',         @ut_enums_bus_top);
MU_add_test(hSuite, 'enums_bus_top_sldd_ws', @ut_enums_bus_top_sldd_ws);
MU_add_test(hSuite, 'params_ws_top',         @ut_params_ws_top);
MU_add_test(hSuite, 'sl_dd_03',              @ut_sl_dd_03);
MU_add_test(hSuite, 'sl_dd_04',              @ut_sl_dd_04);
MU_add_test(hSuite, 'sl_dd_05',              @ut_sl_dd_05);
MU_add_test(hSuite, 'sl_dd_and_ws',          @ut_sl_dd_and_ws);
MU_add_test(hSuite, 'sl_dd_03_vary',         @ut_sl_dd_03_vary);
MU_add_test(hSuite, 'epdev_79676',           @ut_epdev_79676);


%%
hSuite = MU_add_suite('Message', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MessageSignals',   @ut_message_signals);
MU_add_test(hSuite, 'MessageLocals',    @ut_message_locals);
MU_add_test(hSuite, 'MessageMerge',     @ut_message_merge);
MU_add_test(hSuite, 'MessageVBus',      @ut_message_virtual_bus);
MU_add_test(hSuite, 'MessageFcnCall',   @ut_message_function_call);


%%
hSuite = MU_add_suite('misc', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ep_sim_bus_info_build', @ut_ep_sim_bus_info_build);


%%
hSuite = MU_add_suite('MEX', 0, 0, sTmpDir);
MU_add_test(hSuite, 'mxx_mdf_locals_add', @ut_mex_mdf_locals_add);
end
