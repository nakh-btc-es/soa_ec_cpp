function ut_ep_model_analysis_06
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_06
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'model_ana_06');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'model_ref2_tl30');

sTlModel      = 'model_ref';
sTlModelFile  = fullfile(sTestRoot, 'tl_version', [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, 'tl_version', [sTlModel, '.dd']);

sSlModel      = 'model_ref_sl';
sSlModelFile  = fullfile(sTestRoot, 'sl_version', [sSlModel, '.mdl']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, {sSlModelFile, '', false}, {sTlModelFile});

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sSlModel',      sSlModel, ...
    'bCalSupport',   true, ...
    'bParamSupport', false, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_tl_arch(stOpt.sTlResultFile);
    ut_tl_arch_consistency_check(stOpt.sTlResultFile);
catch oEx
    MU_FAIL(i_printException('TL Architecture', oEx)); 
end

try 
    i_check_c_arch(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C Architecture', oEx)); 
end

try 
    i_check_sl_arch(stOpt.sSlResultFile);
catch oEx
    MU_FAIL(i_printException('SL Architecture', oEx)); 
end

try 
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx)); 
end

% EP-828 -- hierachy of SL model is not fully displayed for model references
try
    astSubs = ep_model_subsystems_get('ModelContext', sSlModel);
    
    nExp = 13;
    nFound = length(astSubs);
    MU_ASSERT_TRUE(nFound == nExp, sprintf('Expecting %d subsytems instead of %d.', nExp, nFound));
catch
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%***********************************************************************************************************************
% TL check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sTlResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_tl_arch(sTlResultFile)
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));


% Expected values
casModels = {'model001', 'model002', 'model003', 'model004' };
casModelAttributes = {'modelVersion', 'modelPath', 'creationDate'};
stModelMap = struct;
for nk=1:length(casModels)
    hModel = mxx_xmltree('get_nodes', hTlResultFile, ['//model[@modelID="', casModels{nk}, '"]']);
    MU_ASSERT_TRUE(~isempty(hModel), ['Model ''' , casModels{nk}, ''' not found.']);
    
    for nl=1:length(casModelAttributes)
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hModel, casModelAttributes{nl})), ...
            ['Attribute ''', casModelAttributes{nl} ''' of model ''' , casModels{nk}, ''' not found.']);
    end
    
    % Retrieve information for the following assertions
    [~,modelName] = fileparts(mxx_xmltree('get_attribute', hModel, 'modelPath'));
    stModelMap.(modelName) = casModels{nk};
end

% Check if model references are correctly set.
% ss3
hSubsystem = mxx_xmltree('get_nodes', hTlResultFile, ...
    '//subsystem[@subsysID="ss3" and @physicalPath="sub1"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss3 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub1'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./inport[@physicalPath="sub1/In1" and @modelRef="model002"', ...
    ' and @path="top_A/Subsystem/top_A/sub1/In1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Input "top_A/Subsystem/top_A/sub1/In1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hTlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub1');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./calibration[@physicalPath="sub1/sub_X/sub_B1/Const1" and @modelRef="model002"', ...
    ' and @path="top_A/Subsystem/top_A/sub1/sub_X/sub_B1/Const1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Calibration "top_A/Subsystem/top_A/sub1/sub_X/sub_B1/Const1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hTlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub1');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./calibration/usageContext[@physicalPath="sub1/sub_X/sub_B1/Const1" and @modelRef="model002"', ...
    ' and @path="top_A/Subsystem/top_A/sub1/sub_X/sub_B1/Const1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'ModelContext "top_A/Subsystem/top_A/sub1/sub_X/sub_B1/Const1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hTlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub1');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./outport[@physicalPath="sub1/Out1" and @modelRef="model002"', ...
    ' and @path="top_A/Subsystem/top_A/sub1/Out1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Output "top_A/Subsystem/top_A/sub1/Out1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hTlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub1');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./display[@physicalPath="sub1/sub_X/sub_B1/Sum1" and @modelRef="model002"', ...
    ' and @path="top_A/Subsystem/top_A/sub1/sub_X/sub_B1/Sum1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Display "top_A/Subsystem/top_A/sub1/sub_X/sub_B1/Sum1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hTlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub1');


% ss4
hSubsystem = mxx_xmltree('get_nodes', hTlResultFile, ...
    '//subsystem[@subsysID="ss4" and @physicalPath="sub1/sub_X/sub_B1"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss4 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub1'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);

% ss5
hSubsystem = mxx_xmltree('get_nodes', hTlResultFile, ...
    '//subsystem[@subsysID="ss5" and @physicalPath="sub2"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss5 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub2'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);

%ss6
hSubsystem = mxx_xmltree('get_nodes', hTlResultFile, ...
    '//subsystem[@subsysID="ss6" and @physicalPath="sub4"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss6 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub4'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);

end

%***********************************************************************************************************************
% Sl check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sSlResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));

% Expected values
casModels = {'model001', 'model002', 'model003', 'model004' };
casModelAttributes = {'modelVersion', 'modelPath', 'creationDate'};
stModelMap = struct;
for nk=1:length(casModels)
    hModel = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', casModels{nk}, '"]']);
    MU_ASSERT_TRUE(~isempty(hModel), ['Model ''' , casModels{nk}, ''' not found.']);
    
    for nl=1:length(casModelAttributes)
        MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hModel, casModelAttributes{nl})), ...
            ['Attribute ''', casModelAttributes{nl} ''' of model ''' , casModels{nk}, ''' not found.']);
    end
    
    % Retrieve information for the following assertions
    [~,modelName] = fileparts(mxx_xmltree('get_attribute', hModel, 'modelPath'));
    stModelMap.(modelName) = casModels{nk};
end

% Check if model references are correctly set.
% ss5
hSubsystem = mxx_xmltree('get_nodes', hSlResultFile, ...
    '//subsystem[@subsysID="ss5" and @physicalPath="sub2_sl"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss5 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub2_sl'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);


hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./inport[@physicalPath="sub2_sl/In1"', ...
    ' and @path="top_A/sub_x2/In1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Input "top_A/sub_x2/In1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub2_sl');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./inport[@physicalPath="sub2_sl/In2"', ...
    ' and @path="top_A/sub_x2/In2"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Input "top_A/sub_x2/In2" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub2_sl');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./parameter[@physicalPath="sub4_sl/Gain1"', ...
    ' and @path="top_A/sub_x2/sub_X/sub_Y/Model4/Gain1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Paramter "top_A/sub_x2/sub_X/sub_Y/Model4/Gain1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub4_sl');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./parameter/usageContext[@physicalPath="sub4_sl/Gain1"', ...
    ' and @path="top_A/sub_x2/sub_X/sub_Y/Model4/Gain1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Calibration "top_A/sub_x2/sub_X/sub_Y/Model4/Gain" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub4_sl');

hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./outport[@physicalPath="sub2_sl/Out1"', ...
    ' and @path="top_A/sub_x2/Out1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Output "top_A/sub_x2/Out1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub2_sl');


hIo = mxx_xmltree('get_nodes', hSubsystem, ...
    ['./display[@physicalPath="sub4_sl/Gain1"', ...
    ' and @path="top_A/sub_x2/sub_X/sub_Y/Model4/Gain1"]']);
MU_ASSERT_TRUE(~isempty(hIo), ...
    'Display "top_A/sub_x2/sub_X/sub_Y/Model4/Gain1" cannot be found.');
sModelRef = mxx_xmltree('get_attribute', hIo, 'modelRef');
hModelRef = mxx_xmltree('get_nodes', hSlResultFile, ['//model[@modelID="', sModelRef ,'"]']);
[~,name] = fileparts(mxx_xmltree('get_attribute', hModelRef, 'modelPath'));
MU_ASSERT_EQUAL(name, 'sub4_sl');

% ss6
hSubsystem = mxx_xmltree('get_nodes', hSlResultFile, ...
    '//subsystem[@subsysID="ss6" and @physicalPath="sub4_sl"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss6 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub4_sl'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);

% ss7
hSubsystem = mxx_xmltree('get_nodes', hSlResultFile, ...
    '//subsystem[@subsysID="ss7" and @physicalPath="sub3_sl"]');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hSubsystem, 'physicalPath')), ...
    'Subsystem ss7 has not a physical path set.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hSubsystem, 'modelRef'), stModelMap.('sub3_sl'), ...
    ['Wrong model reference for subsystem ''', mxx_xmltree('get_attribute', hSubsystem, 'path'), '''.']);

end

%***********************************************************************************************************************
% C-Code check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sCResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_c_arch(sCResultFile)
% TODO add tests
end

%***********************************************************************************************************************
% Mapping check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sMappingResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));
end
