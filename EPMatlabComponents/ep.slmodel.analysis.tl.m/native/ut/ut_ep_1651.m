function ut_ep_1651
% Check fix for Bug EP-1651.
%
%  REMARKS
%       Bug: Issues when array signal is only partially mapped to C variables. Especially if the first element is
%            not mapped, the type information is not correctly transferred into the TL arch XML.
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_1651');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'ep_1651');

sTlModel     = 'ep_1651';
sTlModelFile = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile      = fullfile(sTestRoot, [sTlModel, '.dd']);


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = sltu_prepare_local_env(sDataDir, sTestRoot);
sltu_local_model_adapt(sTlModelFile);
xOnCleanupCloseModelTL = sltu_load_models(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
xExp = containers.Map;

xExp('top_A|inport:InPort1') = struct( ...
    'MIL', {{'double', 'double', 'double', 'double', 'double'}}, ...
    'SIL', {{'fixedPoint', 'fixedPoint', 'fixedPoint', 'fixedPoint', 'fixedPoint'}});
xExp('top_A|inport:Index1') = struct( ...
    'MIL', {{'uint8'}}, ...
    'SIL', {{'fixedPoint'}});
xExp('top_A|inport:InPort2') = struct( ...
    'MIL', {{'double', 'double', 'double', 'double', 'double'}}, ...
    'SIL', {{'fixedPoint', 'fixedPoint', 'fixedPoint', 'fixedPoint', 'fixedPoint'}});
xExp('top_A|inport:Index2') = struct( ...
    'MIL', {{'uint8'}}, ...
    'SIL', {{'fixedPoint'}});
xExp('top_A|outport:OutPort1') = struct( ...
    'MIL', {{'double'}}, ...
    'SIL', {{'fixedPoint'}});
xExp('top_A|outport:OutPort2') = struct( ...
    'MIL', {{'double'}}, ...
    'SIL', {{'fixedPoint'}});

xExp('ElementFilter1|inport:Array5') = struct( ...
    'MIL', {{'double', 'double', 'double', 'double', 'double'}}, ...
    'SIL', {{'unsupportedTypeInformation', 'fixedPoint', 'unsupportedTypeInformation', 'fixedPoint', 'unsupportedTypeInformation'}});
xExp('ElementFilter1|inport:Idx') = struct( ...
    'MIL', {{'uint8'}}, ...
    'SIL', {{'fixedPoint'}});
xExp('ElementFilter1|outport:Scalar') = struct( ...
    'MIL', {{'double'}}, ...
    'SIL', {{'fixedPoint'}});

xExp('ElementFilter2|inport:Array5') = struct( ...
    'MIL', {{'double', 'double', 'double', 'double', 'double'}}, ...
    'SIL', {{'fixedPoint', 'unsupportedTypeInformation', 'fixedPoint', 'unsupportedTypeInformation', 'fixedPoint'}});
xExp('ElementFilter2|inport:Idx') = struct( ...
    'MIL', {{'uint8'}}, ...
    'SIL', {{'fixedPoint'}});
xExp('ElementFilter2|outport:Scalar') = struct( ...
    'MIL', {{'double'}}, ...
    'SIL', {{'fixedPoint'}});

i_checkPortSignalTypes(stOpt.sTlResultFile, xExp);
end


%%
function i_checkPortSignalTypes(sArchFile, xExp)
hDoc = mxx_xmltree('load', sArchFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hDoc));

xFound = containers.Map;
ahPorts = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem/*[self::inport or self::outport]');
for i = 1:length(ahPorts)
    hPort = ahPorts(i);
    sKind = mxx_xmltree('get_name', hPort);
    sName = mxx_xmltree('get_attribute', hPort, 'name');
    
    sKey = [i_getSubNameOfPort(hPort), '|', sKind, ':', sName];
    
    casTypesMIL = i_readSignalTypes(mxx_xmltree('get_nodes', hPort, './miltype'));
    casTypesSIL = i_readSignalTypes(mxx_xmltree('get_nodes', hPort, './siltype'));
    xFound(sKey) = struct( ...
        'MIL', {casTypesMIL}, ...
        'SIL', {casTypesSIL});
end

i_comparePortSignals(xExp, xFound);
end


%%
% note: hTypeKind ==> miltype node | siltype node
function casTypes = i_readSignalTypes(hTypeKind)
% note: Type node is either below TypeKind node drectly or deeper nested below one or multiple Signal nodes
ahSigNodes = mxx_xmltree('get_nodes', hTypeKind, './/signal');
if isempty(ahSigNodes)
    casTypes = {i_readTypeInfo(hTypeKind)};
else
    nSigs = numel(ahSigNodes);
    casTypes = cell(1, nSigs);
    for i = 1:nSigs
        casTypes{i} = i_readTypeInfo(ahSigNodes(i));
    end
end
end


%%
function sType = i_readTypeInfo(hParentOfTypeNode)
hTypeNode = mxx_xmltree('get_nodes', hParentOfTypeNode, './*');
if (numel(hTypeNode) == 1)
    sType = mxx_xmltree('get_name', hTypeNode);
else
    error('UT:ERROR', 'Wrong assumption: Exactly one child node representing the type.');
end
end


%%
function sSubName = i_getSubNameOfPort(hPort)
stRes = mxx_xmltree('get_attributes', hPort, '..', 'name');
sSubName = stRes.name;
end


%%
function i_comparePortSignals(xExp, xFound)
casExpKeys = xExp.keys;
casFoundKeys = xFound.keys;
SLTU_ASSERT_STRINGSETS_EQUAL(casExpKeys, casFoundKeys);

for i = 1:length(casExpKeys)
    sKey = casExpKeys{i};
    
    if xFound.isKey(sKey)
        stExpValues = xExp(sKey);
        stFoundValues = xFound(sKey);
        
        MU_ASSERT_TRUE(isequal(stExpValues, stFoundValues), i_failMessages(sKey, stExpValues, stFoundValues));
    end
    
end
end


%%
function sMsg = i_failMessages(sContext, stExpType, stFoundType)
sMsg = sprintf('%s:\nExpected types\n%s instead of\n%s.', ...
    sContext, i_typeStructToString(stExpType), i_typeStructToString(stFoundType));
end


%%
function sString = i_typeStructToString(stType)
sStringMIL = ['MIL -- ', sprintf('%s ', stType.MIL{:})];
sStringSIL = ['SIL -- ', sprintf('%s ', stType.SIL{:})];
sString = sprintf('%s\n%s\n', sStringMIL, sStringSIL);
end

