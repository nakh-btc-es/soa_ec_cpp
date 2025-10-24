function ut_ep_signals_04
% Check handling of virtual/non-virtual Bus signals (PROM-13844).
%
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'signals_04');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'nonvirtual_bus_tl');

sTlModel      = 'nonvirtual_bus_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript = fullfile(sTestRoot, 'nonvirtual_bus_init.m');

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));

stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'xEnv',          xEnv);
stOpt = ut_prepare_options(stOpt, sResultDir);


%% execute test and check
ut_ep_model_analyse(stOpt);

try 
    xExp = containers.Map;
    
    xExp('top_A|inport:In1') = struct('type', 'not_bus',     'obj', '');
    xExp('top_A|inport:In2') = struct('type', 'not_bus',     'obj', '');
    xExp('top_A|inport:In3') = struct('type', 'non_virtual', 'obj', 'myBusZ');
    
    xExp('top_A|outport:Out1') = struct('type', 'not_bus',     'obj', '');
    xExp('top_A|outport:Out2') = struct('type', 'not_bus',     'obj', '');
    xExp('top_A|outport:Out3') = struct('type', 'non_virtual', 'obj', 'myBusW');
    
    xExp('sub_B1|inport:In1') = struct('type', 'non_virtual', 'obj', 'myBusC');
    
    xExp('sub_B1|outport:Out1') = struct('type', 'not_bus',     'obj', '');
    xExp('sub_B1|outport:Out2') = struct('type', 'non_virtual', 'obj', 'myBusC');
    
    xExp('sub_B2|inport:In1') = struct('type', 'non_virtual', 'obj', 'myBusW');
    
    xExp('sub_B2|outport:Out1') = struct('type', 'not_bus',     'obj', '');
    xExp('sub_B2|outport:Out2') = struct('type', 'non_virtual', 'obj', 'myBusW');
    
    i_checkBusSignals(stOpt.sTlResultFile, xExp);
catch oEx
    MU_FAIL(i_printException('Check limitation', oEx)); 
end
end



%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_assertSetsEqual(sContext, casExpSet, casFoundSet)
casMissing = setdiff(casExpSet, casFoundSet);
casUnexpected = setdiff(casFoundSet, casExpSet);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('%s:\nExpected object "%s" not found.', sContext, casMissing{i}));
end
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('%s:\nUnexpected object "%s" found.', sContext, casUnexpected{i}));
end
end


%%
function i_checkBusSignals(sArchFile, xExp)
hDoc = mxx_xmltree('load', sArchFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hDoc));

xFoundMIL = containers.Map;
xFoundSIL = containers.Map;
ahPorts = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem/*[self::inport or self::outport]');
for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    sKind = mxx_xmltree('get_name', hPort);
    sName = mxx_xmltree('get_attribute', hPort, 'name');
    
    sKey = [i_getSubNameOfPort(hPort), '|', sKind, ':', sName];
    
    stSignalMIL = i_readBusSignal(mxx_xmltree('get_nodes', hPort, './miltype/bus'));
    xFoundMIL(sKey) = stSignalMIL;
    
    stSignalSIL = i_readBusSignal(mxx_xmltree('get_nodes', hPort, './siltype/bus'));
    xFoundSIL(sKey) = stSignalSIL;
end

i_comparePortSignals('TL MIL', xExp, xFoundMIL);
i_comparePortSignals('TL SIL', xExp, xFoundSIL);
end


%%
function stSignal = i_readBusSignal(hBus)
if isempty(hBus)
    stSignal = struct('type', 'not_bus', 'obj', '');
else
    stSignal = struct('type', 'virtual', 'obj', '');
    
    stRes = mxx_xmltree('get_attributes', hBus, '.', 'busType', 'busObjectName');
    if ~isempty(stRes.busType)
        stSignal.type = stRes.busType;
    end
    if ~isempty(stRes.busObjectName)
        stSignal.obj = stRes.busObjectName;
    end
end
end


%%
function sSubName = i_getSubNameOfPort(hPort)
stRes = mxx_xmltree('get_attributes', hPort, '..', 'name');
sSubName = stRes.name;
end


%%
function i_comparePortSignals(sContext, xExp, xFound)
casExpKeys = xExp.keys;
casFoundKeys = xFound.keys;
i_assertSetsEqual(sContext, casExpKeys, casFoundKeys);

for i = 1:length(casExpKeys)
    sKey = casExpKeys{i};
    
    if xFound.isKey(sKey)
        stExpValues = xExp(sKey);
        stFoundValues = xFound(sKey);
        
        MU_ASSERT_TRUE(isequal(stExpValues, stFoundValues), ...
            i_failMessages([sContext, ' --- ' sKey], stExpValues, stFoundValues));
    end
    
end
end


%%
function sMsg = i_failMessages(sContext, stExpValues, stFoundValues)
sMsg = sprintf('%s:\nExpected busType="%s" and busObj="%s" instead of busType="%s" and busObj="%s".', ...
    sContext, stExpValues.type, stExpValues.obj, stFoundValues.type, stFoundValues.obj);
end


