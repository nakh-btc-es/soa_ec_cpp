function [stResult, oEx] = ut_ep_model_check(xEnv, sTlModelFile, varargin)

sMessageFile = fullfile(pwd, 'tmp_error.xml');
if exist(sMessageFile, 'file')
    delete(sMessageFile);
end


oEx = [];
try
    stEnvLegacy = ep_core_legacy_env_get(xEnv);
    stResult = atgcv_m01_model_check(stEnvLegacy, sTlModelFile, varargin{:}); 
    
catch oEx
    stResult = struct();
end
copyfile(xEnv.getMessengerFilePath(), sMessageFile);
stResult.sMessageFile = sMessageFile;

if (~isempty(oEx) && (nargout < 2))
    % if we have an exception and it was not explicitly requested as output, rethrow it now
    rethrow(oEx);
end
end


