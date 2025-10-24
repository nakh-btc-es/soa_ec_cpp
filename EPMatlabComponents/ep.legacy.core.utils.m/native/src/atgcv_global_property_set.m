function atgcv_global_property_set(sKey, sValue)
% Stores a key-value pair in a global data structure, which is dependent of a user. 
%
% function atgcv_global_property_set(sKey, sValue)  
%
%   INPUT               DESCRIPTION
%   sKey                (string)   The key which should be stored in a global data structure. 
%               
%   sValue              (string)   The value which belongs to the key.
%
%   Remark: Using the keyword 'SET_GLOBAL_STRUCT' leads to a complete reset of the global settings. In this case 
%           sValue must be a struct which describes the new values for the global settings.
%   sValue              (struct)   Defines the new global data structure (persistent)
%                                  Settings considered by the ET legacy code: 
%                                  'ET_CAL_ignore_LUT_axis'                IGNORE calibration kind
%                                  'ET_CAL_ignore_LUT_1D_values'           IGNORE calibration kind
%                                  'ET_CAL_ignore_LUT_2D_values'           IGNORE calibration kind
%                                  'ET_CAL_ignore_Interpolation_values'    IGNORE calibration kind
%                                  'ET_CAL_ignore_arrays'                  IGNORE calibration kind
%                                  'TL_HOOK_MODE'                          '0',<empty> -> TL HOOK functions 
%                                                                          will be ignored, '1'-> TL HOOK 
%                                                                          functions will be used (simulation,debug env)
%                                  'PREDEFINE_TL_FRAME'                    {'no',<empty>} User Settings if TL_FRAME 
%                                                                          define should be set or not
%                                  'et_encoding'                           Analysis Report Encoding for XML
%                                  'MaxDeviation'                          Maximum of reported deviations for 
%                                                                          test case (vector) in Regression/Test Report
%                                  'use_stdlib_et'                         Use STD LIB default value of global 
%                                                                          property is 'yes' (==> empty == yes)
%                                  'VECTOR_GENERATION_POST'                (et_api_hook_manage)
%                                  'VECTOR_IMPORT_POST'                    (et_api_hook_manage)
%                                  'VECTOR_SIMULATION_POST'                (et_api_hook_manage)
%                                  'VECTOR_REGRESSION_POST'                (et_api_hook_manage)
%                                  'MCR_INIT_XML'                          ModelCoverage Location where the init xml 
%                                                                          mcr file is stored
%                                  'MCR_ORIG_ENC'                          ModelCoverage Location where the original 
%                                                                          encoding of Matlab is stored
%                                  'MCR_WORKING_MDL'                       ModelCoverage Location of working model
%                                  'MCR_GUI_DIR'                           ModelCoverage Location of report directory
%                                  'MSVC_Zm_factor'                        MEX option '/Zm' (atgcv_mex)
%                                  'struct_cal_field'                      atgcv_struct_cal_field() returns the 
%                                                                          name of the field ET is using for 
%                                                                          accessing struct-cal objects 
%
%   OUTPUT              DESCRIPTION
%   -                    -                    
%   REMARK
%   The global data structure is user dependent.
%   A previously defined key with the same name are overwritten with the
%   new value.
%
%  <et_copyright>

%% Internal
%   REFERENCE(S):
%     Design Document:
%
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2009
%
%%

atgcv_global_property_state(sKey, sValue);
end
