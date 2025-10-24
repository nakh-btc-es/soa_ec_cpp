function it_ep_arch_pre_analyze_sl_model()
% Tests the ep_arch_analyze_sl_model method.
%
%  it_ep_arch_analyze_sl_model()
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
ep_tu_cleanup();

%% predefined values
sPwd                = pwd;
sTestData           = sltu_model_get('SimpleBurner', 'SL', true);
sDataPath           = sTestData.sTestDataPath;
sTestRoot           = fullfile(sPwd, 'it_ep_arch_pre_analyze_sl_model');
sModelFile          = fullfile(sTestRoot, sTestData.sSlModel);
sInitScriptFile     = fullfile(sTestRoot, sTestData.sSlInitScript);

%% setup env for test
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    copyfile(sDataPath, sTestRoot);
    cd(sTestRoot);
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end


%% test
try
    %% Test Case 1: read information from simple burner. Valid case.
    stResult = ep_arch_pre_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
        'ParameterHandling', 'ExplicitParam');
    
     MU_ASSERT_TRUE(~isempty(find(ismember(stResult.stResultParameter.casName,'fs_max'), 1)), 'fs_max not found');
     MU_ASSERT_TRUE(~isempty(find(ismember(stResult.stResultParameter.casName,'fs_min'), 1)), 'fs_min not found');
     MU_ASSERT_EQUAL(stResult.stSubsystemHierarchy.caSubsystems{1}.caSubsystems{1}.sPath, ...
         'simplebc_sl/burnercontroller', ...
         'Subystems not found');
    
    %% Test Case 2: Cause exception by invalid key-value pair
    try
        ep_arch_pre_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
            'ParameterHandling', 'ExplictParam'); % Induced Exception
        MU_FAIL('Exception expected.');
    catch
        MU_PASS('Exception has been thrown.')
    end
    
    %% Test Case 3: Cause exception and check if model will be closed correctly.
    try
        ep_tu_create_stub_function('ep_arch_get_sl_parameters', 'replace', 'throw(MException(''EP:INTERNAL:ERROR'', ''Message''));');
        rehash();
        ep_arch_pre_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
            'ParameterHandling', 'ExplicitParam');
        MU_FAIL('Exception expected.');
    catch
        % Check if the model has been closed.
        try
            find_system('simplebc_sl')
            MU_FAIL('Model is still open');
        catch 
            MU_PASS('Model has been closed.')
        end
    end  
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end

%% clean
try
    cd(sPwd);
    ep_tu_cleanup();
    if ( exist(sTestRoot, 'file') )
        ep_tu_rmdir(sTestRoot);
    end
catch
end
end