function ut_modelana_mt01_tlcheck2
% test for TL check
%
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Alexander.Hornstein@osc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 86015 $ 
%   Last modified: $Date: 2011-04-26 10:06:58 +0200 (Di, 26 Apr 2011) $ 
%   $Author: ahornste $



%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd       = pwd();
sRootDir   = fullfile(sPwd, 'mt01_tlcheck2');
sDataDir   = fullfile(ut_local_testdata_dir_get(), 'ma_data_types');
sMaFile    = fullfile(sRootDir, 'ModelAnalysis.xml');
sMaDtdFile = ut_m01_get_ma_dtd();

bDoAcceptOrig = i_getMismatchAccept();



%% FIXTURE
try
    if exist(sRootDir, 'file')
        rmdir(sRootDir, 's');
    end
    ut_m01_copyfile(sDataDir, sRootDir);
    cd(sRootDir);
    
    stEnv = ut_messenger_env_create(pwd);
    ut_messenger_reset(stEnv.hMessenger);
    
catch oEx
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Failed creating TestEnv: %s', oEx.message));
end


%% TEST
try
    i_setMismatchAccept(false);
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr==0, sprintf( ...
        'PreReq failed: Input ModelAnalysis file invalid: %s', sErr));
    
    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    sExpectedID = 'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT';
    try
        atgcv_m01_tlcheck(stEnv, sMaFile);    
        MU_FAIL('Missing expected exception.');
        
    catch oEx
        MU_ASSERT_TRUE(strcmpi(oEx.identifier, sExpectedID), sprintf( ...
            'Expected Exception %s instead of %s.', ...
            sExpectedID, oEx.identifier));
    end
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % expecting 9 warnings with specific Inport numbers
    casExpectedPorts = { ...
        '1', ...
        '2', ...
        '3', ...
        '28', ...
        '29', ...
        '30', ...
        '33', ...
        '36', ...
        '37'};
        
    
    nExpected = length(casExpectedPorts);
    astRes = ut_read_error_file(sErrFile);
    
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'Expected %i but got %i warnings in messenger report.', ...
        nExpected, nFound));
    
    casFound = cell(1, nFound);
    for i = 1:nFound
        MU_ASSERT_TRUE(strcmpi(astRes(i).id, sExpectedID), sprintf( ...
            'Expected ID "%s" instead of "%s".', sExpectedID, ...
            astRes(i).id));
        
        casMatch = regexp(astRes(i).stKeyValues.portsig, '\[#(\d+)\]', 'once', 'tokens');
        if isempty(casMatch)
            MU_FAIL(sprintf( ...
                'Could not determine port number in message: "%s".', ...
                astRes(i).msg));
        else
            casFound(i) = casMatch;
        end
    end
    
    casMissing = setdiff(casExpectedPorts, casFound);
    for i = 1:length(casMissing)
        MU_FAIL(sprintf('Missing port number "%s".', casMissing{i}));
    end
    
    casUnexpected = setdiff(casFound, casExpectedPorts);
    for i = 1:length(casUnexpected)
        MU_FAIL(sprintf('Found unexpected port number "%s".', casUnexpected{i}));
    end
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(['failed TL check: ', stErr.message]);
end



%% CLEANUP
try
    i_setMismatchAccept(bDoAcceptOrig);
    cd(sPwd);
    rmdir(sRootDir, 's');
catch oEx
    cd(sPwd);
    MU_FAIL(sprintf('Unexpected exception CLEANUP: %s', oEx.message));
end
end



%%
function bDoAccept = i_getMismatchAccept()
try
    sFlag = atgcv_global_property_get('accept_inport_type_inconsistent');
catch
    sFlag = 'off';
end
if any(strcmpi(sFlag, {'1', 'on', 'true', 'yes'}))
    bDoAccept = true;
else
    bDoAccept = false;
end
end


%%
function i_setMismatchAccept(bDoAccept)
if bDoAccept
    atgcv_global_property_set('accept_inport_type_inconsistent', 'on');
else
    atgcv_global_property_set('accept_inport_type_inconsistent', 'off');
end
end



