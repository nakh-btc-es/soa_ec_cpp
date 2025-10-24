function sRetValue = atgcv_global_property_state( sKey, sValue)
% Stores and reads key-value pairs in/from a global data structure.
%
% function sRetValue = atgcv_global_property_state( sKey, sValue)
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
%   sRetValue            (String) If the parameter 'sKey' is used without a value, the global state of the 
%                                 key will be returned.
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


% Struct is set by integration or component layer. Legacy layer does not use the GlobalSettgins.xml anymore.
persistent stSettingsPer;
%% Settings considered by the ET legacy code. 
% 'ET_CAL_ignore_LUT_axis'                     | false        | IGNORE calibration kind
% 'ET_CAL_ignore_LUT_1D_values'                | false        | IGNORE calibration kind
% 'ET_CAL_ignore_LUT_2D_values'                | false        | IGNORE calibration kind
% 'ET_CAL_ignore_Interpolation_values'        | false        | IGNORE calibration kind
% 'ET_CAL_ignore_arrays'                      | false        | IGNORE calibration kind
% 'TL_HOOK_MODE'                              | -            | '0',<empty> -> TL HOOK functions will be ignored, '1'-> TL HOOK functions will be used (simulation,debug env)
% 'PREDEFINE_TL_FRAME'                        | -            | {'no',<empty>} User Settings if TL_FRAME define should be set or not
% 'et_encoding'                               | 'ISO-8859-1' | Analysis Report Encoding for XML
% 'MaxDeviation'                              | -            | Maximum of reported deviations for test case (vector) in Regression/Test Report
% 'use_stdlib_et'                             | yes <empty>  | Use STD LIB default value of global property is 'yes' (==> empty == yes)
% 'VECTOR_GENERATION_POST'                    | ?            | ??? (et_api_hook_manage)
% 'VECTOR_IMPORT_POST'                        | ?            | ??? (et_api_hook_manage)
% 'VECTOR_SIMULATION_POST'                    | ?            | ??? (et_api_hook_manage)
% 'VECTOR_REGRESSION_POST'                    | ?            | ??? (et_api_hook_manage)
% 'MCR_INIT_XML'                              |              | ModelCoverage Location where the init xml mcr file is stored
% 'MCR_ORIG_ENC'                              |              | ModelCoverage Location where the original encoding of Matlab is stored
% 'MCR_WORKING_MDL'                           |              | ModelCoverage Location of working model
% 'MCR_GUI_DIR'                               |              | ModelCoverage Location of report directory
% 'MSVC_Zm_factor'                            | -            | MEX option '/Zm' (atgcv_mex)
% 'struct_cal_field'                          | 'VALUE'      | atgcv_struct_cal_field() returns the name of the field ET is using for accessing struct-cal objects 


%% initialize
sRetValue = [];
if (isempty(stSettingsPer))
    stSettingsPer = struct();
end

if( ~isa( sKey , 'char' ) )
    error('ATGCV:STD:WRONG_PARAM_TYPE', 'Key parameter is not a char.');
end

% Sets the whole settings struct at once. Key for this is 'SET_GLOBAL_STRUCT'
if (strcmp('SET_GLOBAL_STRUCT', sKey))
    stSettingsPer = sValue;
    return;
end

% Used by 'atgcv_global_property_get'
if nargin == 1
    %% get the value from the persistent struct
    try
        if isfield(stSettingsPer, sKey)
            sRetValue = stSettingsPer.(sKey);
        else
            error('ATGCV:API:MISSING_PROPERTY', 'Property "%s" is not defined in the global data structure.', sKey );
        end
        return;
    catch
        rethrow( lasterror );
    end
end

% Used by 'atgcv_global_property_set'
if nargin == 2
    %% check parameters
    if( ~isa( sValue , 'char' ) )
        error('ATGCV:STD:WRONG_PARAM_TYPE', 'Value parameter is not a char.');
    end
    stSettingsPer.(sKey) = sValue;
end
end