function [stModel, sErrFile, oEx] = ut_ep_model_info_get(stOpt, bCopyDD)
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

stModel = [];
oEx = [];
try
    stModel = ep_model_info_get(stOpt);
    
catch oEx
end
copyfile(stOpt.xEnv.getMessengerFilePath(), sErrFile);
if (~isempty(oEx) && (nargout < 3))
    % if we have an exception and it was not explicitly requested as output, rethrow it now
    rethrow(oEx);
end
end



%%
function sNewDD = i_copyDD(sDD)
sNewDD = fullfile(pwd(), 'copy.dd');
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

