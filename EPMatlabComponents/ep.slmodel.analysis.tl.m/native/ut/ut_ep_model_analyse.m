function [sErrFile, oEx] = ut_ep_model_analyse(stOpt, bCopyDD)
if (nargin < 2)
    if (isfield(stOpt, 'sDdPath') && ~isempty(stOpt.sDdPath)) 
        bCopyDD = true;
    else
        bCopyDD = false;
    end
end

if bCopyDD
    sOrigDD = stOpt.sDdPath;
    stOpt.sDdPath = i_copyDD(stOpt.sDdPath);
    sNewDD = stOpt.sDdPath;
    xOnCleanupRestore = onCleanup(@() i_restoreDD(sNewDD, sOrigDD));
end

sErrFile = fullfile(fileparts(stOpt.sModelAnalysis), 'tmp_error.xml');
if exist(sErrFile, 'file')
    delete(sErrFile);
end

oEx = [];
try
    ep_model_analyse(stOpt);
    
catch oEx
end
copyfile(stOpt.xEnv.getMessengerFilePath(), sErrFile);
if (~isempty(oEx) && (nargout < 2))
    % if we have an exception and it was not explicitly requested as output, rethrow it now
    % before doing that, already enter something meaningful to the UT report
    if isempty(oEx.message)
        sMsg = sprintf('ERROR-ID "%s".', oEx.identifier);
    else
        sMsg = oEx.getReport();
    end
    MU_FAIL(sprintf('Unexpected exception:\n%s', sMsg));
    rethrow(oEx);
end
end



%%
function sNewDD = i_copyDD(sDD)
if ~isempty(regexp(sDD, '\.ddjson', 'once'))
    sNewDD = fullfile(pwd(), 'copy.ddjson');
else
    sNewDD = fullfile(pwd(), 'copy.dd');
end
copyfile(sDD, sNewDD);

% 1) remove info from orig DD but keep it in copy DD
% 2) return copy of orig DD
ahSubs = dsdd('Find', '/Subsystems', 'ObjectKind', 'Subsystem');
MU_ASSERT_FALSE(isempty(ahSubs), 'PreReq failed: SubsysInfo not in orig DD.');

for i = 1:length(ahSubs)
    dsdd('Delete', ahSubs(i));
end

dsdd('Save');
end


%%
function i_restoreDD(sFullDD, sEmptyDD)
copyfile(sFullDD, sEmptyDD, 'f');
dsdd_free();
dsdd('Open', 'File', sEmptyDD);
end

