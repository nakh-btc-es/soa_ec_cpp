function it_ep_arch_analyze_sl_model()
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
sDataPath           = ep_core_get_dospath(sTestData.sTestDataPath);
sTestRoot           = ep_core_get_dospath(fullfile(sPwd, 'it_ep_arch_analyze_sl_model'));
sModelFile          = fullfile(sTestRoot, sTestData.sSlModel);
sInitScriptFile     = fullfile(sTestRoot, sTestData.sSlInitScript);
sAddModelInfoFile   = fullfile(sTestRoot, sTestData.sSlAddModelInfo);
sErrorXml           = fullfile(sTestRoot, 'error.xml');
sCompilerFile       = fullfile(sTestRoot, 'compiler.xml');

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
    %% Test Case 1: define result file for a valid import
    sSlResult = fullfile(sTestRoot, 'slResult.xml');
    MU_MESSAGE(['Test Root', sSlResult]);
    % call SUT
    stResult = ep_arch_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
        'TestMode', 'BlackBox', ...
        'ParameterHandling', 'ExplicitParam', ...
        'AddModelInfo', sAddModelInfoFile, ...
        'SlResultFile', sSlResult, ...
        'FixedStepSolver', 'yes', ...
        'CompilerFile', sCompilerFile);
    MU_ASSERT_EQUAL(true, stResult.bFixedStepSolver, ...
        'Model has not a fixed-step solver');
    MU_MESSAGE(['Test Root', sSlResult]);
    % check if the compiler file has been generated
    MU_ASSERT_TRUE(exist(stResult.sCompilerFile, 'file'), 'The compiler file does not exist.');
    % check existence of SL-MA file and that the Simple Burner has been analyzed
    sModelAnalysisXml = fullfile(sSlResult);
    MU_ASSERT_TRUE_FATAL(exist(sModelAnalysisXml, 'file'), 'SL-MA file does not exist.');
    hDoc = mxx_xmltree('load', sSlResult);
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hDoc, '//subsystem[@path="simplebc_sl/burnercontroller"]')), ...
        'SimpleBurner has not been analyzed');
    
    % Test if meta data has been set
    ahModelNode = mxx_xmltree('get_nodes', hDoc, '//model');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahModelNode, 'modelVersion')), ...
        'Model version has not been set.');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahModelNode, 'creationDate')), ...
        'Creation date has not been set.');
    MU_ASSERT_TRUE(~isempty(strfind(mxx_xmltree('get_attribute', ahModelNode, 'modelPath'), 'simplebc_sl.mdl')), ...
        'Model path has not been set.');
    MU_ASSERT_TRUE(~isempty(strfind(mxx_xmltree('get_attribute', ahModelNode, 'initScript'), 'simplebc_mdl.m')), ...
        'Init script has not been set.');
    
    ahArchNode = mxx_xmltree('get_nodes', hDoc, '//sl:SimulinkArchitecture');
    MU_ASSERT_TRUE(~isempty(strfind(mxx_xmltree('get_attribute', ahArchNode, 'infoXML'), 'ModelInfo.xml')), ...
        'Addtional model information has not been set.');
    
    mxx_xmltree('clear',hDoc);
    
    %% Test Case 2: Cause exception by invalid key-value pair
    try
        ep_arch_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
            'TestMode', 'BlackBox', ...
            'ParameterHandling', 'ExplictParam', ... % Induced Exception
            'AddModelInfo', sAddModelInfoFile, ...
            'SlResultFile', sSlResult);
        MU_FAIL('Exception expected.');
    catch
        MU_PASS('Exception has been thrown.')
    end
    
    %% Test Case 3: Cause exception by invalid key-value pair
    try
        ep_arch_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
            'TestMode', 'Any', ... % Induced Exception
            'ParameterHandling', 'ExplicitParam', ...
            'AddModelInfo', sAddModelInfoFile, ...
            'SlResultFile', sSlResult);
        MU_FAIL('Exception expected.');
    catch
        MU_PASS('Exception has been thrown.')
    end
    MU_MESSAGE(['Test Root', sSlResult]);
    %% Test Case 4: Cause exception by invalid sSlResult path.
    try
        ep_arch_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
            'TestMode', 'GreyBox', ...
            'ParameterHandling', 'Off', ...
            'AddModelInfo', sAddModelInfoFile, ...
            'SlResultFile', []); % Induced Exception
        MU_FAIL('Exception expected.');
    catch
        MU_PASS('Exception has been thrown.')
    end
    
    %% Test Case 5: Cause exception by invalid add model info.
    MU_MESSAGE('Deactivated. Resource locator must be fixed. SEE PROM-8868.');
%     try
%         hAddModelInfo = mxx_xmltree('load', sAddModelInfoFile);
%         hRootNode = mxx_xmltree('get_root', hAddModelInfo);
%         mxx_xmltree('add_node',hRootNode, 'invalidNode');
%         mxx_xmltree('save', hAddModelInfo, sAddModelInfoFile);
%         mxx_xmltree('clear', hAddModelInfo);
%         
%     % call SUT
%         ep_arch_analyze_sl_model('SlModelFile', sModelFile, 'SlInitScript', sInitScriptFile, ...
%             'TestMode', 'BlackBox', ...
%             'ParameterHandling', 'ExplicitParam', ...
%             'AddModelInfo', sAddModelInfoFile, ...
%             'SlResultFile', sSlResult,...
%             'MessageFile', sErrorXml);
%             MU_FAIL('Exception expected.');
%     catch exception
%         MU_ASSERT_EQUAL(exception.identifier, 'EP:STD:XML_NOT_VALID', ...
%         ['Wrong exception has been thrown: ' exception.identifier]);
%         hDoc = mxx_xmltree('load', sErrorXml);
%         hErrorId = mxx_xmltree('get_nodes', hDoc, '//Message[@id="EP:STD:XML_NOT_VALID"]');
%         MU_ASSERT_TRUE(~isempty(hErrorId), 'Wrong message has been generated.')
%         mxx_xmltree('clear', hDoc);
%     end
    
catch exception
%    if ~isempty(hAddModelInfo)
%        mxx_xmltree('clear', hAddModelInfo);
%    end
    MU_FAIL(sprintf('Unexpected exception: "%s", "%s".',exception.identifier, exception.message));
    
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