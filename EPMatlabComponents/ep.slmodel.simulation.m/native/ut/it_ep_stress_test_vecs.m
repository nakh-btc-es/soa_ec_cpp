function it_ep_stress_test_vecs()
% Tests the ep_sim_* method
%
%  it_ep_stress_test_vecs()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

%% clean up first


dos('xcopy /k /r /i /c /y /s "..\data\stuff\*.*" "."');


%% Test Case 
try
    
    
    xEnv = EPEnvironment();
    sSkeleton = fullfile(pwd,'init_skeleton.xml' );
    sInitFile = fullfile(pwd,'init.xml');
    dTime = 0.1;
    dValue = 1;
    nLength = 10000;
    util_bl_create_init_file(sSkeleton,sInitFile,nLength,dTime,dValue);
    sMatFile = fullfile(pwd,'vector.mat');
    ep_simenv_ports2mat_init(xEnv, sInitFile, pwd);
    ep_simenv_cals2ws_init(sInitFile);
    ep_simenv_cals2mat_init(xEnv, sInitFile, sMatFile);
    
    stRes = load(sMatFile);
    anValues = stRes.i_if27;
    MU_ASSERT_TRUE( isequal(anValues(1,1),0) );
    MU_ASSERT_TRUE( isequal(anValues(1,2),9999) );
    anValues = stRes.i_if28;
    MU_ASSERT_TRUE( isequal(anValues(1,1),0) );
    MU_ASSERT_TRUE( isequal(anValues(1,2),9999) );
    anValues = stRes.i_if29;
    MU_ASSERT_TRUE( isequal(anValues(1,1),0) );
    MU_ASSERT_TRUE( isequal(anValues(1,2),9999) );
    anValues = stRes.i_if30;
    MU_ASSERT_TRUE( isequal(anValues(1,1),0) );
    MU_ASSERT_TRUE( isequal(anValues(1,2),9999) );
    
    nLength = 1000;
    sSkeleton = fullfile( pwd, 'skeleton.xml' );
    sSVFile = fullfile( pwd, 'input.xml' );
    xDocInit = mxx_xmltree('load',sSkeleton);
    ahTestVectors = mxx_xmltree('get_nodes', xDocInit, '/TestVector');
    mxx_xmltree('set_attribute', ahTestVectors(1), ...
        'length', num2str(nLength));
    
    mxx_xmltree('save', xDocInit, sSVFile);
    
    
    tic;
    nCmpLength = ep_simenv_vec2mat(xEnv, sSVFile, pwd);
    MU_ASSERT_TRUE( nCmpLength == nLength);
    toc;
    
    
   
    sTempDir = xEnv.getTempDirectory();
    bTLDS = true;
    
    anExecutionTime = [1 2 3];
    anStackSize = [1 2 3];
    tic;
    ep_simenv_base2tv(sTempDir, sSVFile, ...
        bTLDS, anExecutionTime, anStackSize);
    toc;
    MU_ASSERT_TRUE( exist(sSVFile,'file' ) );
     
    
   
    bTLDS = true;
   
    anExecutionTime = [1 2 3];
    anStackSize = [1 2 3];
    tic;
    ep_simenv_base2tv(sTempDir, sSVFile, ...
         bTLDS, anExecutionTime, anStackSize);
    toc;
    MU_ASSERT_TRUE( exist(sSVFile,'file' ) );
    try
        ep_simenv_base2tv(sTempDir, fullfile(pwd,'zzdzdz1.xml'), ...
        bTLDS, anExecutionTime, anStackSize);
    catch exception
        MU_ASSERT_EQUAL(exception.identifier,'MXX:XML_TREE:FILE_NOT_FOUND');
    end
    
catch exception
     MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end
return;

