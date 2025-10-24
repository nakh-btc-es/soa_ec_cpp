function ut_ep_signals_02
% Check handling of Min/Max for signals (PROM-13845).
%
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'signals_02');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'min_max_model');

sTlModel      = 'min_max_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript = fullfile(sTestRoot, 'min_max_init.m');

sSlModel      = 'min_max_sl';
sSlModelFile  = fullfile(sTestRoot, [sSlModel, '.mdl']);
sSlInitScript = sTlInitScript;

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, {sSlModelFile, sSlInitScript, false}, {sTlModelFile, sTlInitScript});

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));

stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sSlModel',      sSlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'sSlInitScript', sSlInitScript, ...
    'xEnv',          xEnv);
stOpt = ut_prepare_options(stOpt, sResultDir);


%% execute test and check
ut_ep_model_analyse(stOpt);

try
    xExp = containers.Map;
    
    % Note: behavior change for ML2011b and higher
    bIsLowML = (atgcv_version_p_compare('ML7.13') < 0);
    % Note: additional behavior change for ML2022a and higher
    bisHighML = (atgcv_version_p_compare('ML9.11') > 0);

    if bIsLowML
        xExp('inport:In1') = struct('min',    [], 'max',   []);
        xExp('inport:In2') = struct('min', -66.3, 'max', 78.2);
        xExp('inport:In3') = struct('min',  -2.3, 'max',   []);
        
        xExp('parameter:myCal1') = struct('min', -66.223, 'max', 456.98);
        xExp('parameter:myCal2') = struct('min',  -6.223, 'max',  -0.98);
        xExp('parameter:myCal3') = struct('min',   6.223, 'max',  27.8);
        xExp('parameter:myCal4') = struct('min',   0.223, 'max',   2.1);
        
        xExp('outport:Out1') = struct('min',  [],  'max',    []);
        xExp('outport:Out2') = struct('min', -15,  'max', 19.23);
        xExp('outport:Out3') = struct('min',  [],  'max', 77.99);
        
        xExp('display:Add')  = struct('min',   -578,     'max', 767.66);
        xExp('display:Gain') = struct('min', -68023.233, 'max', 7777.88);
        xExp('display:In2')  = struct('min',    -66.3,   'max', 78.2);
        xExp('display:Unit Delay') = struct('min', [], 'max', []);
    elseif bisHighML
        xExp('inport:In1') = struct('min',    [], 'max',   []);
        xExp('inport:In2') = struct('min', -66.3, 'max', 78.2);
        xExp('inport:In3') = struct('min',  -2.3, 'max', []);

        xExp('parameter:myCal1') = struct('min', -66.223, 'max', 456.98);
        xExp('parameter:myCal2') = struct('min',  -6.223, 'max',  -0.98);
        xExp('parameter:myCal3') = struct('min',   6.223, 'max',  27.8);
        xExp('parameter:myCal4') = struct('min',   0.223, 'max',   2.1);

        xExp('outport:Out1') = struct('min', -68023.233, 'max', 7777.88);
        xExp('outport:Out2') = struct('min',    -15,     'max',   19.23);
        xExp('outport:Out3') = struct('min',     -2.3,   'max',   []);

        xExp('display:Add')  = struct('min',    -15,     'max',   19.23);
        xExp('display:Gain') = struct('min', -68023.233, 'max', 7777.88);
        xExp('display:In2')  = struct('min',    -66.3,   'max',   78.2);
        xExp('display:Unit Delay') = struct('min', [],  'max', []);
    else
        xExp('inport:In1') = struct('min',    [], 'max',   []);
        xExp('inport:In2') = struct('min', -66.3, 'max', 78.2);
        xExp('inport:In3') = struct('min',  -2.3, 'max', 77.99);

        xExp('parameter:myCal1') = struct('min', -66.223, 'max', 456.98);
        xExp('parameter:myCal2') = struct('min',  -6.223, 'max',  -0.98);
        xExp('parameter:myCal3') = struct('min',   6.223, 'max',  27.8);
        xExp('parameter:myCal4') = struct('min',   0.223, 'max',   2.1);

        xExp('outport:Out1') = struct('min', -68023.233, 'max', 7777.88);
        xExp('outport:Out2') = struct('min',    -15,     'max',   19.23);
        xExp('outport:Out3') = struct('min',     -2.3,   'max',   77.99);

        xExp('display:Add')  = struct('min',    -15,     'max',   19.23);
        xExp('display:Gain') = struct('min', -68023.233, 'max', 7777.88);
        xExp('display:In2')  = struct('min',    -66.3,   'max',   78.2);
        xExp('display:Unit Delay') = struct('min', [],  'max', []);
    end
    
    i_checkRangesSL(stOpt.sSlResultFile, xExp);
    
    xExpSIL = i_deepCopy(xExp);
    xExpSIL('inport:In2') = struct('min', -65.3, 'max', 77.2);
    xExpSIL('inport:In3') = struct('min', -2.3, 'max', realmax('single')); % NOTE: using explicit single value!!
    
    xExpSIL('parameter:myCal1') = struct('min', [],  'max', []);
    xExpSIL('parameter:myCal2') = struct('min',  -7.2, 'max', 1.7976931348623157e+308);
    xExpSIL('parameter:myCal3') = struct('min', -1.7976931348623157e+308, 'max', 32.9);
    xExpSIL('parameter:myCal4') = struct('min',  -11.2, 'max', 10);
    
    xExpSIL('outport:Out1') = struct('min',  [],  'max',    []);
    xExpSIL('outport:Out3') = struct('min', -realmax('single'), 'max', 77.99);  % NOTE: using explicit single value!!
    
    xExpSIL('display:Add') = struct('min', -578,    'max', 767.66);
    xExpSIL('display:In2') = struct('min',  -65.3,  'max', 77.2);
    
    i_checkRangesTL(stOpt.sTlResultFile, xExp, xExpSIL);
    
catch oEx
    MU_FAIL(i_printException('Check limitation', oEx)); 
end
end



%%
function xCopy = i_deepCopy(xMap)
xCopy = containers.Map;
casKeys = xMap.keys;
for i = 1:length(casKeys)
    sKey = casKeys{i};
    xCopy(sKey) = xMap(sKey);
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
function i_checkRangesSL(sArchFile, xExp)
hDoc = mxx_xmltree('load', sArchFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hDoc));

xFound = containers.Map;
ahInterfaces = mxx_xmltree('get_nodes', hDoc, '/sl:SimulinkArchitecture/model/subsystem/*');
for i = 1:length(ahInterfaces)
    hIf = ahInterfaces(i);
    
    sKind = mxx_xmltree('get_name', hIf);
    sName = mxx_xmltree('get_attribute', hIf, 'name');
    sKey = [sKind, ':', sName];
    
    xFound(sKey) = i_getMinMax(hIf, './double|./single');
end

i_compareMinMax('SL MIL', xExp, xFound);
end


%%
function i_checkRangesTL(sArchFile, xExp, xExpSIL)
hDoc = mxx_xmltree('load', sArchFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hDoc));

xFound = containers.Map;
xFoundSIL = containers.Map;
ahInterfaces = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem/*');
for i = 1:length(ahInterfaces)
    hIf = ahInterfaces(i);
    
    sKind = mxx_xmltree('get_name', hIf);
    if strcmp(sKind, 'calibration')
        sKind = 'parameter';
    end
    sName = mxx_xmltree('get_attribute', hIf, 'name');
    sKey = [sKind, ':', sName];
    
    xFound(sKey) = i_getMinMax(hIf, './miltype/*');
    xFoundSIL(sKey) = i_getMinMax(hIf, './siltype/*');
end

i_compareMinMax('TL MIL', xExp, xFound);
i_compareMinMax('TL SIL', xExpSIL, xFoundSIL);
end


%%
function stValues = i_getMinMax(hNode, sXpath)
stValues = struct( ...
    'min', [], ...
    'max', []);

stRes = mxx_xmltree('get_attributes', hNode, sXpath, 'min', 'max');
if ~isempty(stRes.min)
    stValues.min = str2double(stRes.min);
end
if ~isempty(stRes.max)
    stValues.max = str2double(stRes.max);
end
end


%%
function i_compareMinMax(sContext, xExp, xFound)
casExpKeys = xExp.keys;
casFoundKeys = xFound.keys;
i_assertSetsEqual(sContext, casExpKeys, casFoundKeys);

for i = 1:length(casExpKeys)
    sKey = casExpKeys{i};
    
    if xFound.isKey(sKey)
        stExpValues = xExp(sKey);
        stFoundValues = xFound(sKey);
        
        MU_ASSERT_TRUE(i_valuesEqual(stExpValues.min, stFoundValues.min), ...
            i_failMessages([sContext, ' --- MIN --- ' sKey], stExpValues.min, stFoundValues.min));
        MU_ASSERT_TRUE(i_valuesEqual(stExpValues.max, stFoundValues.max), ...
            i_failMessages([sContext, ' --- MAX --- ' sKey], stExpValues.max, stFoundValues.max));
    end
    
end
end


%%
function bIsEqual = i_valuesEqual(dValue1, dValue2)
% special case one of the values is single --> in this case cast both values to single and compare
if any(cellfun(@(x) isa(x, 'single'), {dValue1, dValue2}))
    bIsEqual = isequal(single(dValue1), single(dValue2));
else
    bIsEqual = isequal(dValue1, dValue2);
end
end


%%
function sMsg = i_failMessages(sContext, dExpValue, dFoundValue)
sExpValue = i_convertToString(dExpValue);
sFoundValue = i_convertToString(dFoundValue);

sMsg = sprintf('%s:\nExpected value "%s" instead of "%s".', sContext, sExpValue, sFoundValue);
end


%%
function sString = i_convertToString(dDouble)
sString = 'empty';
if ~isempty(dDouble)
    sString = sprintf('%.17g', dDouble);
end
end


