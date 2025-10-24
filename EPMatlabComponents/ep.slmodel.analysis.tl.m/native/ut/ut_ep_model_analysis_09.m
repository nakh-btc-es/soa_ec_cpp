function ut_ep_model_analysis_09
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_09
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
sTestRoot = fullfile(sPwd, 'model_ana_09');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'power_window');

sTlModel      = 'powerwindow_tl_v01';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, 'start.m');
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'sTlInitScript',   sTlInitScript, ...
    'bAddEnvironment', true, ...
    'xEnv',            xEnv);

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
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_check_tl_arch(sTlResultFile)
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));

% This test checks if the 'scopeKind' attriute is set correctly

% Expect one model, which is root of the architecture.
ahModelNodes = mxx_xmltree('get_nodes', hTlResultFile, '/tl:TargetLinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');
ahSubsystems = mxx_xmltree('get_nodes', ahModelNodes, './subsystem');

for idx = 1:length(ahSubsystems)
    hSubsystem = ahSubsystems(idx);
    stAttributes = mxx_xmltree('get_attributes',hSubsystem,'.','name','scopeKind');
    if (strcmp(stAttributes.name, 'PowerWindow_ClosedLoop'))
        MU_ASSERT_EQUAL(stAttributes.scopeKind,'VIRTUAL','ClosedLoop_Frame: scopeKind is not ''VIRTUAL''');
    else
        if (strcmp(stAttributes.name, 'power_window_controller'))
            MU_ASSERT_EQUAL(stAttributes.scopeKind,'SUT','power_window_control: scopeKind is not ''SUT''');
        else
            if (strcmp(stAttributes.name, 'detect_obstacle_endstop'))
                MU_ASSERT_EQUAL(stAttributes.scopeKind,'SUT','driver_switch: scopeKind is not ''SUT''');
            else
                if (strcmp(stAttributes.name, 'validate_driver'))
                    MU_ASSERT_EQUAL(stAttributes.scopeKind,'SUT','passenger_switch: scopeKind is not ''SUT''');
                else
                    if (strcmp(stAttributes.name, 'validate_passenger'))
                        MU_ASSERT_EQUAL(stAttributes.scopeKind,'SUT','passenger_switch: scopeKind is not ''SUT''');
                    else
                        if (strcmp(stAttributes.name, 'window_system'))
                            MU_ASSERT_EQUAL(stAttributes.scopeKind,'ENV','window_system: scopeKind is not ''ENV''');
                        else
                            MU_FAIL(['Unexpected subsystem ''',stAttributes.name,''' identified']);
                        end
                    end
                end
            end
        end
    end
end

sTLScopeKindVirtual = 'VIRTUAL';
sTLScopeKindEnvironment = 'ENV';
sTLScopeKindSut = 'SUT';

% Expect virtual and environment node in architecture
ahRootSystemRefNodes = mxx_xmltree('get_nodes', hTlResultFile, '/tl:TargetLinkArchitecture/model/rootSystem');
MU_ASSERT_TRUE(length(ahRootSystemRefNodes) == 1, 'Not exactly one root subsystem found.')
sRootSystemID = mxx_xmltree('get_attribute', ahRootSystemRefNodes(1), 'refSubsysID');
ahRootSystem = mxx_xmltree('get_nodes', hTlResultFile, ['//subsystem[@subsysID','=''', sRootSystemID,''']']);
MU_ASSERT_TRUE(length(ahRootSystem) == 1, 'Subsystem ID could not be resolved');
hRootSubsystem = ahRootSystem(1);
sScopeKind = mxx_xmltree('get_attribute', hRootSubsystem, 'scopeKind');
MU_ASSERT_EQUAL(sScopeKind,sTLScopeKindVirtual,['ScopeKind is not ''', sTLScopeKindVirtual,''' as expected.']);
ahSubsystems = mxx_xmltree('get_nodes', hRootSubsystem, ['./','subsystem']);
MU_ASSERT_EQUAL(length(ahSubsystems),2,'Not all subsystems exported');
for iSubIdx = 1:length(ahSubsystems)
    hSubsystem = ahSubsystems(iSubIdx);
    sRefID = mxx_xmltree('get_attribute', hSubsystem, 'refSubsysID');
    if ~isempty(sRefID)
        hSubsystem = mxx_xmltree('get_nodes', hTlResultFile, ['//subsystem[@subsysID','=''', sRefID,''']']);
    end
    sName = mxx_xmltree('get_attribute', hSubsystem, 'name');
    sKind = mxx_xmltree('get_attribute', hSubsystem, 'kind');
    sScopeKind = mxx_xmltree('get_attribute', hSubsystem, 'scopeKind');
    sPath = mxx_xmltree('get_attribute', hSubsystem, 'path');
    if (strcmp(sName, 'window_system'))
        MU_ASSERT_EQUAL(sKind, 'subsystem', ['Kind ''',sKind, ''' does not match the expected ''subsystem''']);
        MU_ASSERT_EQUAL(sScopeKind, sTLScopeKindEnvironment, ['ScopeKind ''',sScopeKind, ''' does not match', ...
            'the expected ''', sTLScopeKindEnvironment, '''']);
        MU_ASSERT_EQUAL(sPath, 'PowerWindow_ClosedLoop/window_system', ['Path ''',sPath, ...
            ''' does not match the expected ''powerwindow_closed_loop/ClosedLoop_Frame/window_system''']);
    end
    if (strcmp(sName, 'power_window_controller'))
        MU_ASSERT_EQUAL(sKind, 'subsystem', ['Kind ''',sKind, ''' does not match the expected ''subsystem''']);
        MU_ASSERT_EQUAL(sScopeKind, sTLScopeKindSut, ['ScopeKind ''',sScopeKind, ''' does not match', ...
            'the expected ''', sTLScopeKindSut, '''']);
        MU_ASSERT_EQUAL(sPath, ['PowerWindow_ClosedLoop/power_window_controller/', ...
            'Subsystem/power_window_controller'], ['Path ''',sPath, ''' does not match the expected ''',...
            'powerwindow_closed_loop/ClosedLoop_Frame/power_window_control/Subsystem/power_window_control''']);
    end
end
end



%%
function i_check_c_arch(sCResultFile)
hCResultFile = mxx_xmltree('load', sCResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hCResultFile));

% TODO
end


%%
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//ScopeMapping');
MU_ASSERT_EQUAL(4, length(ahValues), 'Dummy subsystem is not excluded from mapping.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ['//ScopeMapping/', ...
    'Path[@path="PowerWindow_ClosedLoop/power_window_controller/', ...
    'Subsystem/power_window_controller"]']);
MU_ASSERT_EQUAL(1, length(ahValues), 'Dummy subsystem is not excluded from mapping.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ['//ScopeMapping/', ...
    'Path[@path="PowerWindow_ClosedLoop/power_window_controller/Subsystem/', ...
    'power_window_controller/detect_obstacle_endstop"]']);
MU_ASSERT_EQUAL(1, length(ahValues), 'Dummy subsystem is not excluded from mapping.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ['//ScopeMapping/', ...
    'Path[@path="PowerWindow_ClosedLoop/power_window_controller/Subsystem/', ...
    'power_window_controller/validate_driver"]']);
MU_ASSERT_EQUAL(1, length(ahValues), 'Dummy subsystem is not excluded from mapping.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ['//ScopeMapping/', ...
    'Path[@path="PowerWindow_ClosedLoop/power_window_controller/Subsystem/', ...
    'power_window_controller/validate_passenger"]']);
MU_ASSERT_EQUAL(1, length(ahValues), 'Dummy subsystem is not excluded from mapping.');
end

