function stConfig = ep_ec_ecahook_legacy_code_config_get(xEnv, stUserConfig)
% Called without parameters the function returns the default configurations for
% "ecahook_legacy_code" hook file
%
% Called with parameters the function merges the default configurations for
% "ecahook_legacy_code" hook file with the custom user passes
% configurations and returns the result
%
% stConfig = ep_ec_ecahook_legacy_code_config_get(xEnv, stUserConfig)
%
%  INPUT              DESCRIPTION
%    - xEnv                              EPEnvironment object
%    - stUserConfig                      The user custom configs
%
%  OUTPUT            DESCRIPTION
%
%  - stConfig          The configurations to use
if (nargin == 0)
    stConfig = i_get_default_config();
else
    casKnownIndermediateSettings = {};
    stConfig = ep_ec_settings_merge(xEnv, i_get_default_config(), stUserConfig, casKnownIndermediateSettings);
end
end

%%
function stDefaultConfig = i_get_default_config()
% Return information about additionnal source files to include in the c-code architecture
%
%  astSrcFiles : Array of structures
%     .path    : full path to the c-file
%     .codecov : T/F to activate code coverage for this file
%     .hide    : T/F to treart just as a compilation file (no function
%                selection, not code coverage)
%
%  casInclPaths : Cell array of strings
%
%  astDefines  : Array of structures
%     .name    : name of the pre-processor macro
%     .value   : value of the pre-processor macro (optional)
%
%  sPreStepFunctionName : External preStep function name
% -------------------------------- Examples --------------------------------
% Enter absolute path of c-file
%
% cc = 0; dd= 0;
%
% cc = cc+1;
% astSrcFiles(cc).path    = 'C:/libs/file1.c';
% astSrcFiles(cc).hide    = false;
% astSrcFiles(cc).codecov = false;
% cc = cc+1;
% astSrcFiles(cc).path    = 'C:/libs/file2.c';
% astSrcFiles(cc).hide    = true;
%
%Enter absolute path of include directories
% casInclPaths = {'C:/libs'};
%
%Enter Defines
% dd = dd+1;
% astDefines(dd).name  =  'MACRO_DEFINTION';
% dd = dd+1;
% astDefines(dd).name  =  'MACRO_DEFINITION_WITH_VALUE';
% astDefines(dd).value =  '0';
%--------------------------------------------------------------------------
stDefaultConfig = struct(...
    'astSrcFiles',            [], ...
    'casInclPaths',           {{}}, ...
    'astDefines',             [], ...
    'sPreStepFunctionName',   '');
end



