function MU_pre_hook
% Define suites and tests for unit testing that do NOT depend on TargetLink.
%
sTmpDir = sltu_tmp_env;


%%
hSuite = MU_add_suite('Base', 0, 0, sTmpDir);
MU_add_test(hSuite, 'VariantSubsystems',      @ut_variant_subsystems);
MU_add_test(hSuite, 'MultiTopRegular',        @ut_multi_top_regular);
MU_add_test(hSuite, 'MultiTopDummy',          @ut_multi_top_dummy);
MU_add_test(hSuite, 'EmptyTopRegular',        @ut_empty_top_regular);
MU_add_test(hSuite, 'MinMax',                 @ut_minmax);
MU_add_test(hSuite, 'InputModelConstraints',  @ut_input_model_constraints);
MU_add_test(hSuite, 'SingleTopDummy_EC',      @ut_single_top_dummy_ec);
MU_add_test(hSuite, 'prom_14253',             @ut_prom_14253);
MU_add_test(hSuite, 'test_point_ev_disp',     @ut_test_point_ev_disp);
MU_add_test(hSuite, 'SimulinkFunctions',      @ut_test_sl_functions);


%%
hSuite = MU_add_suite('Signals', 0, 0, sTmpDir);
MU_add_test(hSuite, 'min_max',            @ut_min_max);
MU_add_test(hSuite, 'nonvirtual_bus',     @ut_nonvirtual_bus);
MU_add_test(hSuite, 'nonvirtual_bus_02',  @ut_nonvirtual_bus_02);
MU_add_test(hSuite, 'many_bus',           @ut_many_bus);
MU_add_test(hSuite, 'array_of_buses_01',  @ut_array_of_buses_01);
MU_add_test(hSuite, 'array_of_buses_02',  @ut_array_of_buses_02);
MU_add_test(hSuite, 'ultimate_bus',       @ut_ultimate_bus);
MU_add_test(hSuite, 'messages_01',        @ut_messages_01);
MU_add_test(hSuite, 'messages_02',        @ut_messages_02);
MU_add_test(hSuite, 'messages_03',        @ut_messages_03);
MU_add_test(hSuite, 'messages_04',        @ut_messages_04);
MU_add_test(hSuite, 'messages_05',        @ut_messages_05);


%%
hSuite = MU_add_suite('Params', 0, 0, sTmpDir);
MU_add_test(hSuite, 'simple_lut_01',   @ut_simple_lut_01);


%%
hSuite = MU_add_suite('Stateflow', 0, 0, sTmpDir);
MU_add_test(hSuite, 'sf_locals_01',      @ut_sf_locals_01);
MU_add_test(hSuite, 'sf_locals_02',      @ut_sf_locals_02);
MU_add_test(hSuite, 'sf_array_of_buses', @ut_sf_array_of_buses);


%%
hSuite = MU_add_suite('MinMax', 0, 0, sTmpDir);
MU_add_test(hSuite, 'min_max_00',      @ut_min_max_00);
MU_add_test(hSuite, 'min_max_01',      @ut_min_max_01);
MU_add_test(hSuite, 'min_max_02',      @ut_min_max_02);
MU_add_test(hSuite, 'min_max_03',      @ut_min_max_03);
MU_add_test(hSuite, 'min_max_04',      @ut_min_max_04);
MU_add_test(hSuite, 'min_max_05',      @ut_min_max_05);


%%
hSuite = MU_add_suite('MinMaxNew', 0, 0, sTmpDir);
MU_add_test(hSuite, 'min_max_new_01',      @ut_min_max_new_01);
MU_add_test(hSuite, 'min_max_new_02',      @ut_min_max_new_02);
MU_add_test(hSuite, 'min_max_new_03',      @ut_min_max_new_03);


%%
hSuite = MU_add_suite('Matrix', 0, 0, sTmpDir);
MU_add_test(hSuite, 'matrix_sig_01',   @ut_matrix_sig_01);
MU_add_test(hSuite, 'matrix_sig_02',   @ut_matrix_sig_02);
MU_add_test(hSuite, 'matrix_sig_03',   @ut_matrix_sig_03);
MU_add_test(hSuite, 'matrix_sig_04',   @ut_matrix_sig_04);
MU_add_test(hSuite, 'matrix_sig_05',   @ut_matrix_sig_05);
MU_add_test(hSuite, 'matrix_sig_06',   @ut_matrix_sig_06);
MU_add_test(hSuite, 'matrix_sig_07',   @ut_matrix_sig_07);
MU_add_test(hSuite, 'matrix_sig_08',   @ut_matrix_sig_08);
MU_add_test(hSuite, 'matrix_sig_09',   @ut_matrix_sig_09);
MU_add_test(hSuite, 'matrix_sig_10',   @ut_matrix_sig_10);
MU_add_test(hSuite, 'matrix_sig_11',   @ut_matrix_sig_11);


%%
hSuite = MU_add_suite('DataStores', 0, 0, sTmpDir);
MU_add_test(hSuite, 'DataStoreMemory',  @ut_data_store_memory);
MU_add_test(hSuite, 'DataStores01',     @ut_data_stores_01);
MU_add_test(hSuite, 'DataStores02',     @ut_data_stores_02);
MU_add_test(hSuite, 'DataStores03',     @ut_data_stores_03);
MU_add_test(hSuite, 'DataStores04',     @ut_data_stores_04);
MU_add_test(hSuite, 'DataStores05',     @ut_data_stores_05);
MU_add_test(hSuite, 'DataStores06',     @ut_data_stores_06);
MU_add_test(hSuite, 'DataStores07',     @ut_data_stores_07);
MU_add_test(hSuite, 'DataStores08',     @ut_data_stores_08);
MU_add_test(hSuite, 'DataStores09',     @ut_data_stores_09);
MU_add_test(hSuite, 'DataStoresRW01',   @ut_data_stores_ReadWrite_01);
MU_add_test(hSuite, 'DataStoresRW02',   @ut_data_stores_ReadWrite_02);
MU_add_test(hSuite, 'DataStoresBus01',  @ut_data_stores_bus_01);
MU_add_test(hSuite, 'DataStoresBus02',  @ut_data_stores_bus_02);
MU_add_test(hSuite, 'DataStoresInvBus', @ut_data_stores_bus_inv);
MU_add_test(hSuite, 'DataStoresArrBus', @ut_data_stores_bus_03);


%%
hSuite = MU_add_suite('SLFunctions', 0, 0, sTmpDir);
MU_add_test(hSuite, 'sl_funcs_01',       @ut_sl_funcs_01);
MU_add_test(hSuite, 'sl_funcs_04',       @ut_sl_funcs_04);


%%
hSuite = MU_add_suite('SampleTime', 0, 0, sTmpDir);
MU_add_test(hSuite, 'sample_time_01', @ut_sample_time_01);
MU_add_test(hSuite, 'sample_time_02', @ut_sample_time_02);


%%
hSuite = MU_add_suite('FixedPoint', 0, 0, sTmpDir);
MU_add_test(hSuite, 'fixed_point_01', @ut_fixed_point_01);
MU_add_test(hSuite, 'fixed_point_02', @ut_fixed_point_02);
MU_add_test(hSuite, 'EM-781',         @ut_em_781);
MU_add_test(hSuite, 'EM-782',         @ut_em_782);


%%
hSuite = MU_add_suite('EP', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EP-828',   @ut_ep_828);
MU_add_test(hSuite, 'EP-1045',  @ut_ep_1045);
MU_add_test(hSuite, 'EP-1117',  @ut_sl_array_of_buses);
MU_add_test(hSuite, 'EP-1206',  @ut_user_types);
MU_add_test(hSuite, 'EP-1810',  @ut_ep_1810);
MU_add_test(hSuite, 'EP-1949',  @ut_ep_1949);
MU_add_test(hSuite, 'EP-2596_data_store_filtering', @ut_ep_2596_data_store_filtering);


%%
hSuite = MU_add_suite('EPDEV', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EPDEV-35707',        @ut_bus_typed_param);
MU_add_test(hSuite, 'EPDEV-36347',        @ut_model_ref_variant);
MU_add_test(hSuite, 'EPDEV-57678',        @ut_epdev_57678);


%%
hSuite = MU_add_suite('Limitations', 0, 0, sTmpDir);
MU_add_test(hSuite, 'DataTypeInt64',         @ut_data_type_int64);
MU_add_test(hSuite, 'DataTypeInt64_R2020',   @ut_data_type_int64_r2020);
MU_add_test(hSuite, 'DataStoreBus',          @ut_data_store_bus);
MU_add_test(hSuite, 'EP-2553',               @ut_params_01);
MU_add_test(hSuite, 'DataTypeFxp64',         @ut_data_type_fxp64);


%%
hSuite = MU_add_suite('BTS', 0, 0, sTmpDir);
MU_add_test(hSuite, 'BTS/35327', @ut_bts_35327);
MU_add_test(hSuite, 'BTS/36381', @ut_bts_36381);
MU_add_test(hSuite, 'BTS/36382', @ut_bts_36382);
MU_add_test(hSuite, 'BTS/36577', @ut_bts_36577);


%%
hSuite = MU_add_suite('Enum', 0, 0, sTmpDir);
MU_add_test(hSuite, 'enum_01',       @ut_enum_01);
MU_add_test(hSuite, 'enum_01_sldd',  @ut_enum_01_sldd);
MU_add_test(hSuite, 'enum_02',       @ut_enum_02);
MU_add_test(hSuite, 'enum_02_sldd',  @ut_enum_02_sldd);


%%
hSuite = MU_add_suite('SLDD', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SLDD_01',                      @ut_sl_dd_01);
MU_add_test(hSuite, 'SLDD_02',                      @ut_sl_dd_02);
MU_add_test(hSuite, 'SameParamNamesInSLDDAndInWS',  @ut_same_param_names_sldd_ws);


%%
hSuite = MU_add_suite('ModelWorkspaceParams', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MWP_01',                 @ut_model_workspace_params_01);
MU_add_test(hSuite, 'MWP_02',                 @ut_model_workspace_params_02);
MU_add_test(hSuite, 'MWP_03',                 @ut_model_workspace_params_03);
MU_add_test(hSuite, 'LookupTablesArg',        @ut_model_arg_lut);


%%
% spcecial suite for pre-analysis workflows
hSuite = MU_add_suite('PreAnalysisWorkflows', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ParamSLDD',              @ut_pre_ana_param_sldd);
MU_add_test(hSuite, 'MultiTopRegular',        @ut_pre_ana_multi_top_regular);
MU_add_test(hSuite, 'MultiTopDummy',          @ut_pre_ana_multi_top_dummy);
MU_add_test(hSuite, 'EmptyTopRegular',        @ut_pre_ana_empty_top_regular);
MU_add_test(hSuite, 'MinMax',                 @ut_pre_ana_minmax);
MU_add_test(hSuite, 'InputModelConstraints',  @ut_pre_ana_input_model_constraints);
MU_add_test(hSuite, 'SingleTopDummy_EC',      @ut_pre_ana_single_top_dummy_ec);
MU_add_test(hSuite, 'TruthTable',             @ut_pre_ana_truth_table);
end