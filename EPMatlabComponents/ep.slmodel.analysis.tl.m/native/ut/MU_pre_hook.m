function MU_pre_hook
% Define suites and tests for unit testing.
%
% function MU_pre_hook
%


%%
sTmpDir = sltu_tmp_env;
sltu_coverage_backup('deactivate');


%% 
% early return if TL not available
if ~i_isTlAvailable()
    i_MU_pre_hook_dummy_tl();
    return;
end

% Note: stubs "tlds_init", "tlds_start", "tlds_stop" to make the tests faster!
sStubDir = fullfile(pwd, 'stubs');
if exist(sStubDir, 'dir')
    addpath(sStubDir);
end

%% ========================= GOOD STYLE ==========================================================
% Use these UTs as blueprint for your own UTs!!
%

%%
hSuite = MU_add_suite('simple', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EP-2216',         @ut_ep_2216);
MU_add_test(hSuite, 'simple_slfunc',   @ut_simple_slfunc);
MU_add_test(hSuite, 'extended_slfunc', @ut_extended_slfunc);
MU_add_test(hSuite, 'EP-2661',         @ut_ep_2661);
MU_add_test(hSuite, 'aob_model_01',    @ut_ep_aob_model_01);


%%
hSuite = MU_add_suite('ModelAna0', [], [], sTmpDir);
MU_add_test(hSuite, 'fuelsys_cal',          @ut_fuelsys_cal);
MU_add_test(hSuite, 'cal_in_2_modules',     @ut_cal_in_2_modules);
MU_add_test(hSuite, 'simple_interface',     @ut_simple_interface);
MU_add_test(hSuite, 'calibration_support',  @ut_calibration_support);
MU_add_test(hSuite, 'struct_interface',     @ut_struct_interface);
MU_add_test(hSuite, 'vcfp',                 @ut_vcfp);


%%
hSuite = MU_add_suite('ModelAna1', [], [], sTmpDir);
MU_add_test(hSuite, 'variable_signal_width',    @ut_variable_signal_width);
MU_add_test(hSuite, 'bug_6410',                 @ut_bug_6410);
MU_add_test(hSuite, 'bug_6435',                 @ut_bug_6435);
MU_add_test(hSuite, 'bug_6441',                 @ut_bug_6441);
MU_add_test(hSuite, 'bug_6444',                 @ut_bug_6444);
MU_add_test(hSuite, 'bug_6580',                 @ut_bug_6580);
MU_add_test(hSuite, 'bug_7719',                 @ut_bug_7719);
MU_add_test(hSuite, 'denso_sample',           	@ut_denso_sample);
MU_add_test(hSuite, 'mux_busports',             @ut_mux_busports);


%%
hSuite = MU_add_suite('ModelAna2', [], [], sTmpDir);
MU_add_test(hSuite, 'disp_model_01',        @ut_disp_model_01);
MU_add_test(hSuite, 'muxed_model',          @ut_muxed_model);
MU_add_test(hSuite, 'mergeable_disp',       @ut_mergeable_disp);
MU_add_test(hSuite, 'denso_bigsample',      @ut_denso_bigsample);
MU_add_test(hSuite, 'ext_cal_model',        @ut_ext_cal_model);
MU_add_test(hSuite, 'paramcal_model',       @ut_paramcal_model);
MU_add_test(hSuite, 'simple_variant_01',    @ut_simple_variant_01);
MU_add_test(hSuite, 'simple_variant_02',    @ut_simple_variant_02);
MU_add_test(hSuite, 'simple_variant_03',    @ut_simple_variant_03);
MU_add_test(hSuite, 'data_variant',         @ut_data_variant);
MU_add_test(hSuite, 'data_variant_renamed', @ut_data_variant_renamed);
MU_add_test(hSuite, 'subsystem_hierarchy',  @ut_subsystem_hierarchy);
MU_add_test(hSuite, 'param_interface',      @ut_param_interface);
MU_add_test(hSuite, 'struct_cal',           @ut_struct_cal);
MU_add_test(hSuite, 'port_read',            @ut_port_read);
MU_add_test(hSuite, 'shared_muxed',         @ut_shared_muxed);
MU_add_test(hSuite, 'signal_data_type',     @ut_signal_data_type);
MU_add_test(hSuite, 'explicit_param_dd',    @ut_explicit_param_dd);
MU_add_test(hSuite, 'dd_path_model',        @ut_dd_path_model);
MU_add_test(hSuite, 'dv_dd_path',           @ut_dv_dd_path);
MU_add_test(hSuite, 'simple_mcal',          @ut_simple_mcal);
MU_add_test(hSuite, 'simulink_parameter',   @ut_simulink_parameter);
MU_add_test(hSuite, 'const_sf_cal',         @ut_const_sf_cal);
MU_add_test(hSuite, 'extern_function',      @ut_extern_function);


%%
hSuite = MU_add_suite('ModelAna3', [], [], sTmpDir);
MU_add_test(hSuite, 'opt_interface',      @ut_opt_interface);
MU_add_test(hSuite, 'extern_macro',       @ut_extern_macro);
MU_add_test(hSuite, 'signal_injection',   @ut_signal_injection);
MU_add_test(hSuite, 'paramcal_model_02',  @ut_paramcal_model_02);
MU_add_test(hSuite, 'extended_explicit',  @ut_extended_explicit);
MU_add_test(hSuite, 'multi_var_ports_01', @ut_multi_var_ports_01);
MU_add_test(hSuite, 'multi_var_ports_02', @ut_multi_var_ports_02);

%%
hSuite = MU_add_suite('Checks_new', [], [], sTmpDir);
MU_add_test(hSuite, 'two_tl_subsystems', @ut_check_two_tl_subsystems);
MU_add_test(hSuite, 'rtos_multirate',    @ut_check_rtos_multirate);
MU_add_test(hSuite, 'model_ref',         @ut_check_model_ref);
MU_add_test(hSuite, 'lib_model',         @ut_check_lib_model);


%%
hSuite = MU_add_suite('AUTOSAR_LEGACY', [], [], sTmpDir);
MU_add_test(hSuite, 'ar_fuelsys',        @ut_ar_fuelsys);
MU_add_test(hSuite, 'ar_poscontrol',     @ut_ar_poscontrol);
MU_add_test(hSuite, 'ar_dcmc',           @ut_ar_dcmc);
MU_add_test(hSuite, 'ar_rename_fuelsys', @ut_ar_rename_fuelsys);
MU_add_test(hSuite, 'ar_b28554',         @ut_ar_b28554);
MU_add_test(hSuite, 'ar_calibrations',   @ut_ar_calibrations);
MU_add_test(hSuite, 'ar_vcfp',           @ut_ar_vcfp);
MU_add_test(hSuite, 'ar_bus_sig_inj',    @ut_ar_bus_sig_inj);


%%
hSuite = MU_add_suite('LimitationsLegacy', [], [], sTmpDir);
MU_add_test(hSuite, 'limitation_lut',      @ut_limitation_lut);
MU_add_test(hSuite, 'sf_events',           @ut_sf_events);
MU_add_test(hSuite, 'toplevel_trigger_if', @ut_toplevel_trigger_if);
MU_add_test(hSuite, 'integrator_model',    @ut_integrator_model);
MU_add_test(hSuite, 'bitfield_cal',        @ut_bitfield_cal);


%%
hSuite = MU_add_suite('Bugs0', 0, 0, sTmpDir);
MU_add_test(hSuite, 'Bug_8748',          @ut_bug_8748);
MU_add_test(hSuite, 'Bug_8897',          @ut_bug_8897);
MU_add_test(hSuite, 'Bug_9373',          @ut_bug_9373);
MU_add_test(hSuite, 'Bug_9375',          @ut_bug_9375);
MU_add_test(hSuite, 'Bug_9499',          @ut_bug_9499);
MU_add_test(hSuite, 'Bug_9661',          @ut_bug_9661);
MU_add_test(hSuite, 'Bug_9883',          @ut_bug_9883);
MU_add_test(hSuite, 'Interface_all',     @ut_interface_all);
MU_add_test(hSuite, 'Bug_10537',         @ut_bug_10537);
MU_add_test(hSuite, 'Bug_10630',         @ut_bug_10630);
MU_add_test(hSuite, 'Bug_10852',         @ut_bug_10852);
MU_add_test(hSuite, 'Bug_11492',         @ut_bug_11492);
MU_add_test(hSuite, 'Bug_11507',         @ut_bug_11507);
MU_add_test(hSuite, 'Bug_11607',         @ut_bug_11607);
MU_add_test(hSuite, 'Bug_11643',         @ut_bug_11643);
MU_add_test(hSuite, 'Bug_12249',         @ut_bug_12249);
MU_add_test(hSuite, 'Bug_15199',         @ut_bug_15199);
MU_add_test(hSuite, 'Bug_16083',         @ut_bug_16083);
MU_add_test(hSuite, 'Bug_16624',         @ut_bug_16624);
MU_add_test(hSuite, 'Bug_17301',         @ut_bug_17301);
MU_add_test(hSuite, 'Bug_17435_1',       @ut_bug_17435_1);
MU_add_test(hSuite, 'Bug_17435_2',       @ut_bug_17435_2);


%%
hSuite = MU_add_suite('Bugs1', [], [], sTmpDir);
MU_add_test(hSuite, 'Bug_21176',          @ut_bug_21176);
MU_add_test(hSuite, 'Bug_21136',          @ut_bug_21136);
MU_add_test(hSuite, 'Bug_22235',          @ut_bug_22235);
MU_add_test(hSuite, 'Bug_22615',          @ut_bug_22615);
MU_add_test(hSuite, 'Bug_22753',          @ut_bug_22753);
MU_add_test(hSuite, 'Bug_22779',          @ut_bug_22779);
MU_add_test(hSuite, 'Bug_25046',          @ut_bug_25046);
MU_add_test(hSuite, 'Bug_25249',          @ut_bug_25249);
MU_add_test(hSuite, 'Bug_25848',          @ut_bug_25848);
MU_add_test(hSuite, 'Bug_25987',          @ut_bug_25987);
MU_add_test(hSuite, 'Bug_26898',          @ut_bug_26898);
MU_add_test(hSuite, 'Bug_27530',          @ut_bug_27530);
MU_add_test(hSuite, 'Bug_32581',          @ut_bug_32581);
MU_add_test(hSuite, 'Bug_32939',          @ut_bug_32939);
MU_add_test(hSuite, 'Bug_33980',          @ut_bug_33980);
MU_add_test(hSuite, 'Bug_34573',          @ut_bug_34573);
MU_add_test(hSuite, 'Bug_32712',          @ut_bug_32712);
MU_add_test(hSuite, 'Bug_34765',          @ut_bug_34765);


%%
hSuite = MU_add_suite('Bugs2', [], [], sTmpDir);
MU_add_test(hSuite, 'Bug_33760', @ut_bug_33760);
MU_add_test(hSuite, 'Bug_34089', @ut_bug_34089);
MU_add_test(hSuite, 'Bug_34932', @ut_bug_34932);
MU_add_test(hSuite, 'Bug_34956', @ut_bug_34956);
MU_add_test(hSuite, 'Bug_35322', @ut_bug_35322);
MU_add_test(hSuite, 'Bug_35910', @ut_bug_35910);
MU_add_test(hSuite, 'Bug_35907', @ut_bug_35907);
MU_add_test(hSuite, 'Bug_36050', @ut_bug_36050);
MU_add_test(hSuite, 'Bug_36097', @ut_bug_36097);


%%
hSuite = MU_add_suite('Bugs3', [], [], sTmpDir);
MU_add_test(hSuite, 'Bug_35120',  @ut_bug_35120);
MU_add_test(hSuite, 'Bug_35120a', @ut_bug_35120a);
MU_add_test(hSuite, 'Bug_36505',  @ut_bug_36505);
MU_add_test(hSuite, 'Bug_36533',  @ut_bug_36533);
MU_add_test(hSuite, 'Bug_36725',  @ut_bug_36725);
MU_add_test(hSuite, 'Bug_36728',  @ut_bug_36728);
MU_add_test(hSuite, 'Bug_36728a', @ut_bug_36728a);
MU_add_test(hSuite, 'Bug_36826',  @ut_bug_36826);
MU_add_test(hSuite, 'Bug_36876',  @ut_bug_36876);


%%
hSuite = MU_add_suite('Assumptions', [], [], sTmpDir);
MU_add_test(hSuite, 'assump_01',  @ut_assump_01);


%%
hSuite = MU_add_suite('ClosedLoop', [], [], sTmpDir);
MU_add_test(hSuite, 'closed_loop_01',   @ut_closed_loop_01);
MU_add_test(hSuite, 'closed_loop_02',   @ut_closed_loop_02);
MU_add_test(hSuite, 'closed_loop_03',   @ut_closed_loop_03);
MU_add_test(hSuite, 'closed_loop_04',   @ut_closed_loop_04);
MU_add_test(hSuite, 'closed_loop_05',   @ut_closed_loop_05);
MU_add_test(hSuite, 'vcfp_closed_loop', @ut_vcfp_closed_loop);


%%
hSuite = MU_add_suite('SimulinkTypes', [], [], sTmpDir);
MU_add_test(hSuite, 'simulink_numtype',         @ut_simulink_numtype);
MU_add_test(hSuite, 'simulink_numtype_no_fpb',  @ut_simulink_numtype_no_fpb);
MU_add_test(hSuite, 'MagnaFixedPointTypes',     @ut_fix_datatypes);


%%
hSuite = MU_add_suite('TargetLinkTypes', [], [], sTmpDir);
MU_add_test(hSuite, 'scaling_enums',  @ut_scaling_enums);


%%
hSuite = MU_add_suite('EM', [], [], sTmpDir);
MU_add_test(hSuite, 'em_968',  @ut_em_968);
MU_add_test(hSuite, 'em_1047', @ut_em_1047);


%%
hSuite = MU_add_suite('Matrix', [], [], sTmpDir);
MU_add_test(hSuite, 'Matrix01',     @ut_matrix_01);
MU_add_test(hSuite, 'Matrix02',     @ut_matrix_02);
MU_add_test(hSuite, 'Matrix03',     @ut_matrix_03);
MU_add_test(hSuite, 'Matrix04',     @ut_matrix_04);
MU_add_test(hSuite, 'Matrix05',     @ut_matrix_05);
MU_add_test(hSuite, 'Matrix06',     @ut_matrix_06);
MU_add_test(hSuite, 'Matrix07',     @ut_matrix_07);
MU_add_test(hSuite, 'Matrix08',     @ut_matrix_08);
MU_add_test(hSuite, 'Matrix09',     @ut_matrix_09);


%%
hSuite = MU_add_suite('MatrixMap', [], [], sTmpDir);
MU_add_test(hSuite, 'MatrixMap01', @ut_matrix_map_01);
MU_add_test(hSuite, 'MatrixMap02', @ut_matrix_map_02);
MU_add_test(hSuite, 'MatrixMap03', @ut_matrix_map_03);
MU_add_test(hSuite, 'MatrixMap04', @ut_matrix_map_04);


%%
hSuite = MU_add_suite('MatrixSupport', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MatrixSupport01',  @ut_matrix_support_01);
MU_add_test(hSuite, 'MatrixSupport02',  @ut_matrix_support_02);
MU_add_test(hSuite, 'MatrixSupport03',  @ut_matrix_support_03);
MU_add_test(hSuite, 'MatrixSupport04',  @ut_matrix_support_04);
MU_add_test(hSuite, 'MatrixSupport05',  @ut_matrix_support_05);
MU_add_test(hSuite, 'MatrixSupport06',  @ut_matrix_support_06);
MU_add_test(hSuite, 'MatrixSupport07',  @ut_matrix_support_07);
MU_add_test(hSuite, 'MatrixSupport08',  @ut_matrix_support_08);
MU_add_test(hSuite, 'MatrixSupport09',  @ut_matrix_support_09);
MU_add_test(hSuite, 'MatrixSupport12',  @ut_matrix_support_12);
MU_add_test(hSuite, 'MatrixSupport13',  @ut_matrix_support_13);
MU_add_test(hSuite, 'MatrixSupport15',  @ut_matrix_support_15);
MU_add_test(hSuite, 'MatrixSupport16',  @ut_matrix_support_16);
MU_add_test(hSuite, 'MatrixSupport17',  @ut_matrix_support_17);
MU_add_test(hSuite, 'MatrixSupport18',  @ut_matrix_support_18);
MU_add_test(hSuite, 'MatrixSupport20',  @ut_matrix_support_20);
MU_add_test(hSuite, 'MatrixSupport21',  @ut_matrix_support_21);


%%
hSuite = MU_add_suite('ModelRef', [], [], sTmpDir);
MU_add_test(hSuite, 'ModelRef01', @ut_modelref_01);
MU_add_test(hSuite, 'ModelRef02', @ut_modelref_02);
MU_add_test(hSuite, 'ModelRef05', @ut_modelref_05);
MU_add_test(hSuite, 'ModelRef06', @ut_modelref_06);


%%
hSuite = MU_add_suite('TLFeatures', [], [], sTmpDir);
MU_add_test(hSuite, 'TL34',       @ut_tl_34);
MU_add_test(hSuite, 'TL40_01',    @ut_tl_40_01);
MU_add_test(hSuite, 'TL40_02',    @ut_tl_40_02);
MU_add_test(hSuite, 'TL41_01',    @ut_tl_41_01);
MU_add_test(hSuite, 'TL41_02',    @ut_tl_41_02);


%%
hSuite = MU_add_suite('Bus', [], [], sTmpDir);
MU_add_test(hSuite, 'Bus02',    @ut_bus_02);
MU_add_test(hSuite, 'Bus03',    @ut_bus_03);
MU_add_test(hSuite, 'Bus04',    @ut_bus_04);


%%
hSuite = MU_add_suite('BugsBus', [], [], sTmpDir);
MU_add_test(hSuite, 'Bug_11509', @ut_bug_11509);
MU_add_test(hSuite, 'Bug_11890', @ut_bug_11890);
MU_add_test(hSuite, 'Bug_27973', @ut_bug_27973);
MU_add_test(hSuite, 'Bug_36564a',@ut_bug_36564a);
MU_add_test(hSuite, 'Bug_36564b',@ut_bug_36564b);


%%
hSuite = MU_add_suite('Disp', [], [], sTmpDir);
MU_add_test(hSuite, 'Disp01', @ut_disp_01);
MU_add_test(hSuite, 'Disp03', @ut_disp_03);
MU_add_test(hSuite, 'Disp04', @ut_disp_04);
MU_add_test(hSuite, 'Disp05', @ut_disp_05);
MU_add_test(hSuite, 'Disp06', @ut_disp_06);
MU_add_test(hSuite, 'Disp07', @ut_disp_07);
MU_add_test(hSuite, 'Disp08', @ut_disp_08);
MU_add_test(hSuite, 'Disp09', @ut_disp_09);
MU_add_test(hSuite, 'Disp10', @ut_disp_10);
MU_add_test(hSuite, 'Disp11', @ut_disp_11);


%%
hSuite = MU_add_suite('FcnCall', [], [], sTmpDir);
MU_add_test(hSuite, 'FcnCall01', @ut_fcn_call_01);
MU_add_test(hSuite, 'FcnCall02', @ut_fcn_call_02);
MU_add_test(hSuite, 'FcnCall03', @ut_fcn_call_03);


%%
hSuite = MU_add_suite('EPLegacy', [], [], sTmpDir);
MU_add_test(hSuite, 'EP-558',  @ut_ep_558);
MU_add_test(hSuite, 'EP-970',  @ut_ep_970);
MU_add_test(hSuite, 'EP-1004', @ut_ep_1004);
MU_add_test(hSuite, 'EP-1223', @ut_ep_1223);
MU_add_test(hSuite, 'EP-1225', @ut_ep_1225);
MU_add_test(hSuite, 'EP-1465', @ut_ep_1465);


%%
hSuite = MU_add_suite('ExplicitParam', [], [], sTmpDir);
MU_add_test(hSuite, 'ExplicitParam01', @ut_explicit_param_01);
MU_add_test(hSuite, 'ExplicitParam02', @ut_explicit_param_02);
MU_add_test(hSuite, 'ExplicitParam03', @ut_explicit_param_03);


%%
hSuite = MU_add_suite('FixedPoint', [], [], sTmpDir);
MU_add_test(hSuite, 'FixedPoint01', @ut_fixed_point_01);


%%
hSuite = MU_add_suite('PromLegacy', [], [], sTmpDir);
MU_add_test(hSuite, 'PROM-13496', @ut_prom_13496);
MU_add_test(hSuite, 'PROM-15246', @ut_prom_15246);
MU_add_test(hSuite, 'PROM-15248', @ut_prom_15248);


%%
hSuite = MU_add_suite('Interface', [], [], sTmpDir);
MU_add_test(hSuite, 'UnreadableInterface',       @ut_unreadable_interface);
MU_add_test(hSuite, 'DummyInportSF',             @ut_dummy_inport_sf);
MU_add_test(hSuite, 'EnumSL',                    @ut_enum_sl);
MU_add_test(hSuite, 'SignalInjection1',          @ut_signal_injection1);
MU_add_test(hSuite, 'SignalInjection2',          @ut_signal_injection2);
MU_add_test(hSuite, 'SignalInjectionSL',         @ut_signal_injection_sl);
MU_add_test(hSuite, 'aob_injection',             @ut_aob_injection);
MU_add_test(hSuite, 'SignalInjectionSLMdlRef',   @ut_signal_injection_sl_mdl_ref);
MU_add_test(hSuite, 'SimpleReturn',              @ut_simple_return);
MU_add_test(hSuite, 'MuxMix',                    @ut_mux_mix);


%%
hSuite = MU_add_suite('SystemTimeLegacy', [], [], sTmpDir);
MU_add_test(hSuite, 'SystemTime01', @ut_system_time_01);
MU_add_test(hSuite, 'SystemTime02', @ut_system_time_02);
MU_add_test(hSuite, 'SystemTime03', @ut_system_time_03);
MU_add_test(hSuite, 'SystemTime04', @ut_system_time_04);


%%
hSuite = MU_add_suite('CalSettings', [], [], sTmpDir);
MU_add_test(hSuite, 'CalSettings01', @ut_cal_settings_01);
MU_add_test(hSuite, 'CalSettings02', @ut_cal_settings_02);


%%
hSuite = MU_add_suite('AdaptiveAutosar', [], [], sTmpDir);
MU_add_test(hSuite, 'TLAA_Model_Check',             @ut_adaptive_autosar_tl_model_check);
MU_add_test(hSuite, 'aar_communication_with_64bit', @ut_aar_communication_with_64bit);













%% ========================= OLD STYLE ===========================================================
% Do NOT use the following UTs as a blueprint for your UT!!! Use the UTs above instead

%% Basic
hSuite = MU_add_suite('Basic', 0, 0, sTmpDir);
MU_add_test(hSuite, 'PowerWindow',         @ut_ep_model_analysis_01);
MU_add_test(hSuite, 'ExplicitParam',       @ut_ep_model_analysis_03);
MU_add_test(hSuite, 'SimpleBurner',        @ut_ep_model_analysis_04);
MU_add_test(hSuite, 'SimpleBurnerLimited', @ut_ep_model_analysis_05);
MU_add_test(hSuite, 'ModelReferences',     @ut_ep_model_analysis_06);
MU_add_test(hSuite, 'ArrayDisp',           @ut_ep_model_analysis_07);
MU_add_test(hSuite, 'BusPorts',            @ut_ep_model_analysis_08);
MU_add_test(hSuite, 'PowerWindowCL',       @ut_ep_model_analysis_09);
MU_add_test(hSuite, 'MatrixDisp',          @ut_ep_model_analysis_10);
MU_add_test(hSuite, 'BitfieldCal',         @ut_ep_model_analysis_11);


%% SystemTime
hSuite = MU_add_suite('SystemTime', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SystemTime',        @ut_ep_ccode_system_time_0);
MU_add_test(hSuite, 'SystemTimeFloat',   @ut_ep_ccode_system_time_1);
MU_add_test(hSuite, 'SystemTimeRef',     @ut_ep_ccode_system_time_2);


%% Legacy
% extra checks for Legacy converter --> throw away when replacing somewhen
hSuite = MU_add_suite('Legacy', 0, 0, sTmpDir);
MU_add_test(hSuite, 'Bitfield',            @ut_ep_legacy_converter_01);
MU_add_test(hSuite, 'FloatsWithLimits',    @ut_ep_legacy_converter_02);
MU_add_test(hSuite, 'PROM-9398',           @ut_ep_legacy_converter_03);
MU_add_test(hSuite, 'SignalInjection',     @ut_ep_legacy_converter_04);
MU_add_test(hSuite, 'SignalInjection2',    @ut_ep_legacy_converter_05);
MU_add_test(hSuite, 'PseudoBus',           @ut_ep_legacy_converter_06);
MU_add_test(hSuite, 'BTS_25740',           @ut_ep_legacy_converter_07);
MU_add_test(hSuite, 'Displays',            @ut_ep_legacy_converter_08);


%% Signals
hSuite = MU_add_suite('SignalsTL', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MinMaxTL',        @ut_ep_signals_02);
MU_add_test(hSuite, 'NonVirtualBusTL', @ut_ep_signals_04);
MU_add_test(hSuite, 'VirtualBusTL',    @ut_ep_signals_05);
MU_add_test(hSuite, 'OneElemArrays',   @ut_ep_signals_06);


%% EnumTL
hSuite = MU_add_suite('EnumTL', 0, 0, sTmpDir);
MU_add_test(hSuite, 'Enum01', @ut_tl_enum_01);


%% Subsystems
hSuite = MU_add_suite('Subsystems', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ReusableIncremental', @ut_tl_reusable_incremental_01);
MU_add_test(hSuite, 'ReusableModelRef_01', @ut_tl_reusable_modelref_01);
MU_add_test(hSuite, 'ReusableModelRef_02', @ut_tl_reusable_modelref_02);
MU_add_test(hSuite, 'AtomicSubsystems',    @ut_ep_atomic_subs);


%% Params
hSuite = MU_add_suite('Params', 0, 0, sTmpDir);
MU_add_test(hSuite, 'VariantCals',                 @ut_data_variant_cals);
MU_add_test(hSuite, 'VariantArrayCals',            @ut_data_variant_array_cals);
MU_add_test(hSuite, 'BypassGlobals',               @ut_bypass_globals);


%% Locals
hSuite = MU_add_suite('Locals', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MultiLocalInBlocks', @ut_ep_locals_01);
MU_add_test(hSuite, 'StructLocals',       @ut_struct_locals);


%% Code
hSuite = MU_add_suite('Code', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SameNameVarsStatic',   @ut_ep_code_01);
MU_add_test(hSuite, 'ReplaceableDataItems', @ut_ep_code_02);
MU_add_test(hSuite, 'SameNameVarsGlobal',   @ut_ep_code_03);


%% ModelReduce
hSuite = MU_add_suite('ModelReduce', 0, 0, sTmpDir);
MU_add_test(hSuite, 'HierarchyWithCal', @ut_ep_reduce_01);


%% BugsPROM
hSuite = MU_add_suite('PROM', 0, 0, sTmpDir);
MU_add_test(hSuite, 'PROM-13117', @ut_ep_prom_13117);
MU_add_test(hSuite, 'PROM-13361', @ut_ep_prom_13361);
MU_add_test(hSuite, 'PROM-13652', @ut_ep_prom_13652);
MU_add_test(hSuite, 'PROM-14229', @ut_ep_prom_14229);
MU_add_test(hSuite, 'PROM-14771', @ut_ep_prom_14771);
MU_add_test(hSuite, 'PROM-17057', @ut_ep_prom_17057);


%% BugsEP
hSuite = MU_add_suite('EP', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EP-540',  @ut_ep_ep_540);
MU_add_test(hSuite, 'EP-588',  @ut_ep_ep_588);
MU_add_test(hSuite, 'EP-638',  @ut_ep_ep_638);
MU_add_test(hSuite, 'EP-970',  @ut_ep_ep_970);
MU_add_test(hSuite, 'EP-1602', @ut_ep_ep_1602);
MU_add_test(hSuite, 'EP-1651', @ut_ep_1651);
MU_add_test(hSuite, 'EP-1675', @ut_ep_1675);
MU_add_test(hSuite, 'EP-1991', @ut_missing_tl_dialog);
MU_add_test(hSuite, 'EP-2096', @ut_ep_2096);
MU_add_test(hSuite, 'EP-2325', @ut_ep_2325);


%% BugsEPDEV
hSuite = MU_add_suite('EPDEV', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EPDEV-35686', @ut_epdev_35686);
MU_add_test(hSuite, 'EPDEV-40759', @ut_ep_epdev_40759);


%% TL4.4
hSuite = MU_add_suite('TL4.4', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ArrayOfStructs',  @ut_array_of_structs_01);


%% ML-Code
hSuite = MU_add_suite('ML-Code', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ML-CodeParameters',  @ut_mlcode_parameters_01);


%% ArchitectureConstraints
hSuite = MU_add_suite('ArchitectureConstraints', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ArchitectureConstraints01',  @ut_ep_architecture_constraints_01);

%% SF-Parameter
hSuite = MU_add_suite('SF-Parameter', 0, 0, sTmpDir);
MU_add_test(hSuite, 'SF-Parameter01', @ut_sf_state_param_01);


%% AUTOSAR
hSuite = MU_add_suite('AUTOSAR', 0, 0, sTmpDir);
MU_add_test(hSuite, 'AUTOSAR_01',  @ut_autosar_01);


%% Limitations
hSuite = MU_add_suite('Limitations', 0, 0, sTmpDir);
MU_add_test(hSuite, 'DataTypeInt64TL',  @ut_data_type_int64_tl);




%% ================== LEGACY STUFF ========================================
%
% -- short cut for Dev if legacy stuff is not affected --
if ~isempty(getenv('UT_IGNORE_LEGACY_MA'))
    return;
end

%%
sUtPath = fileparts(mfilename('fullpath'));
sUtLegacyPath = fullfile(sUtPath, 'legacy_ut');
addpath(sUtLegacyPath);


%% Checks
% Note: suite is currently based on *legacy* format ModelAnalysis.xml
%       --> at the moment we cannot replace it with low effort
%       --> task remains open until we get rid of ModelAnalsis.xml as intermediate format
%       --> then we can replace the UTs with ones that test the newly established check mechanism
hSuite = MU_add_suite('Checks', [], [], sTmpDir);
MU_add_test(hSuite, 'SLCHECK',       @ut_modelana_mt01_slcheck);
MU_add_test(hSuite, 'SLCHECK2',      @ut_modelana_mt01_slcheck2);
MU_add_test(hSuite, 'SLCHECK3',      @ut_modelana_mt01_slcheck3);
MU_add_test(hSuite, 'SLCHECK4',      @ut_modelana_mt01_slcheck4);
MU_add_test(hSuite, 'TLCHECK',       @ut_modelana_mt01_tlcheck);
MU_add_test(hSuite, 'TLCHECK2',      @ut_modelana_mt01_tlcheck2);
MU_add_test(hSuite, 'TLCHECK3',      @ut_modelana_mt01_tlcheck3);
MU_add_test(hSuite, 'TLCHECK4',      @ut_modelana_mt01_tlcheck4);
MU_add_test(hSuite, 'TLCHECK5',      @ut_modelana_mt01_tlcheck5);
end




%%
function i_MU_pre_hook_dummy_tl
hSuite = MU_add_suite('TL DUMMY', [], [], '');
MU_add_test(hSuite, 'Skipped', @i_issueSkippingMessage);
end


%%
function i_issueSkippingMessage()
MU_MESSAGE('TL is not installed. Intentionally skipping all tests that depend on TargetLink features.');
end


%%
function bIsAvailable = i_isTlAvailable()
bIsAvailable = exist('dsdd', 'file') ~= 0;
end
