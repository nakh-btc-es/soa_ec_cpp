function [sMaFile, sErrFile, oEx] = ut_m01_model_analysis(stEnv, stOpt, bCopyDD)
if (nargin < 3)
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

ut_messenger_reset(stEnv.hMessenger);
sErrFile = fullfile(pwd, 'tmp_error.xml');
if exist(sErrFile, 'file')
    delete(sErrFile);
end

sMaFile = '';
oEx = [];
try
    stRes = atgcv_model_analysis(stEnv, stOpt);
    
catch oEx
    % also for the error case, try to save the Messenger entries
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    if (nargout < 3)
        % if exception is not expected as output, throw it now
        rethrow(oEx);
    else
        % otherwise, just return normally because further steps make no sense
        return;
    end
end

ut_messenger_save(stEnv.hMessenger, sErrFile);
sMaFile = fullfile(stEnv.sResultPath, stRes.sModelAnalysis);
ut_modelana_consistency_check(stEnv, sMaFile);

sAssFile = fullfile(stEnv.sResultPath, stRes.sAssumptions);
i_checkAssumptionsFile(stEnv, sAssFile);
atgcv_m01_assumptions_calmode_add(stEnv, sAssFile, sMaFile);
i_checkAssumptionsFile(stEnv, sAssFile);

if ~ut_m01_is_ep2_context()
    i_checkFunctionListCreation(stEnv, sMaFile);
    i_checkVariableListCreation(stEnv, sMaFile);
end
end



%%
function i_checkAssumptionsFile(stEnv, sAssFile)
sAssDtdFile  = ut_m01_get_ass_dtd();
[nErr, sErr] = atgcv_m_xmllint(stEnv, sAssDtdFile, sAssFile);
MU_ASSERT_TRUE(nErr == 0, ...
    sprintf('Invalid InterfaceAssumptions output:\n%s', sErr));
end


%%
function i_checkFunctionListCreation(stEnv, sMaFile)
try
    stRes = atgcv_m01_create_funclist(stEnv, sMaFile);
    sFuncList = fullfile(stEnv.sResultPath, stRes.sFunctionList);
    MU_ASSERT_TRUE(exist(sFuncList, 'file'), ...
        'Creating function list failed. Output file is missing.');
catch oEx
    MU_FAIL(sprintf('Creating function list failed.\n%s', oEx.message));
end
end


%%
function i_checkVariableListCreation(stEnv, sMaFile)
try
    stRes = atgcv_m01_create_varlist(stEnv, sMaFile);
    sVarList = fullfile(stEnv.sResultPath, stRes.sVarList);
    MU_ASSERT_TRUE(exist(sVarList, 'file'), ...
        'Creating variable list failed. Output file is missing.');
catch oEx
    MU_FAIL(sprintf('Creating variable list failed.\n%s', oEx.message));
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

