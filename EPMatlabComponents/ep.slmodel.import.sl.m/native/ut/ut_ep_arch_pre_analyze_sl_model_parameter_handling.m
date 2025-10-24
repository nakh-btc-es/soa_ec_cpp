function ut_ep_arch_pre_analyze_sl_model_parameter_handling()
% Tests the ep_arch_analyze_sl_model method.
%
%  ut_ep_arch_pre_analyze_sl_model_parameter_handling()
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
    %% Cause an exception if the method 'ep_arch_get_sl_parameters' is called but the ParameterHandling is set to 'Off'
    ep_tu_create_stub_function('ep_arch_get_sl_parameters', 'replace', 'throw(MException(''EP:INTERNAL:ERROR'', ''Message''));');
    rehash();
    ep_arch_pre_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
        'ParameterHandling', 'Off');
    
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