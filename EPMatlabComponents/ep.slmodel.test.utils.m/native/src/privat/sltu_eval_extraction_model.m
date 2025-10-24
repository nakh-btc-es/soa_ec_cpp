function stModel = sltu_eval_extraction_model(sExtractionModelXml, sHarnessModelIn, sHarnessModelOut)
% Utility function to gather all relevant infos from the extraction XML.
%

%%
if (nargin < 2)
    sHarnessModelIn = '';
    sHarnessModelOut = '';
end


%%
stModel = struct( ...
    'dSampleTime', [], ...
    'sPath',       '', ...
    'astInports',  [], ...
    'astDSReads',  [], ...
    'astCals',     [], ...
    'astOutports', [], ...
    'astDSWrites', [], ...
    'astDisplays', []);

%%
if ~exist(sExtractionModelXml, 'file')
    MU_FAIL(sprintf('Testdata incomplete. Extraction model "%s" not found.', sExtractionModelXml));
    return;
end

%%
hDoc = mxx_xmltree('load', sExtractionModelXml);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

hScope = mxx_xmltree('get_nodes', hDoc, '/ExtractionModel/Scope[1]');
stModel.dSampleTime = str2double(mxx_xmltree('get_attribute', hScope, 'sampleTime'));
stModel.sPath = mxx_xmltree('get_attribute', hScope, 'path');

stModel.astInports      = i_getInterfaceInfo(hScope, 'InPort', sHarnessModelIn);
stModel.astDSReads      = i_getInterfaceInfo(hScope, 'DataStoreRead', sHarnessModelIn);
stModel.astCals         = i_getInterfaceInfo(hScope, 'Calibration');
stModel.astOutports     = i_getInterfaceInfo(hScope, 'OutPort', sHarnessModelOut);
stModel.astDSWrites     = i_getInterfaceInfo(hScope, 'DataStoreWrite', sHarnessModelOut);
stModel.astDisplays     = i_getInterfaceInfo(hScope, 'Display', sHarnessModelOut);
end


%%
function astRes = i_getInterfaceInfo(hScope, sKind, sHarnessModel)
astRes = [];

sXPath = sprintf('./%s/Variable/ifName', sKind);
ahIfNodes = mxx_xmltree('get_nodes', hScope, sXPath);

for i = 1:length(ahIfNodes)
    stRes = mxx_xmltree('get_attributes', ahIfNodes(i), '.', 'ifid', 'identifier');
    hVarNode = mxx_xmltree('get_nodes', ahIfNodes(i), '..');
    
    sSignalType = mxx_xmltree('get_attribute', hVarNode, 'signalType');
    
    if (nargin > 2)
        if isempty(sSignalType)
            sSignalType = i_getSignalTypeForBusSignals(sHarnessModel, sKind, stRes.identifier);
        end
    end
    
    stTypeInfo = ep_sl_type_info_get(sSignalType);
    stRes.signalType = sSignalType;
    if stTypeInfo.bIsFxp
        stRes.baseType = stTypeInfo.sEvalType;
    else
        stRes.baseType = stTypeInfo.sBaseType;
    end
    
    switch sKind
        case {'InPort', 'DataStoreRead'}
            stRes.kind = 'Input';
            
        case {'OutPort', 'DataStoreWrite'}
            stRes.kind = 'Output';
            
        case 'Display'
            stRes.kind = 'Local';
            
        case 'Calibration'
            stRes.kind = 'Parameter';
    end
        
    if strcmp(sKind, 'InPort') || strcmp(sKind, 'DataStoreRead')
        stRes.kind = 'Input';
    end
    if strcmp(sKind, 'OutPort') || strcmp(sKind, 'DataStoreWrite')
        stRes.kind = 'Output';
    end
    if strcmp(sKind, 'Display')
        stRes.kind = 'Local';
    end
    astRes = [astRes, stRes]; %#ok
end
end


%%
function sType = i_getSignalTypeForBusSignals(sHarnessModel, sKind, sIdentifier)
if isempty(sHarnessModel)
    sType = '';
    return;
end

hDoc = mxx_xmltree('load', sHarnessModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));
if strcmp(sKind, 'InPort')
    hScalarRef = mxx_xmltree('get_nodes', hDoc, ['/SFunction/Outports/Outport/ScalarRefs/ScalarRef[text() = ''', ...
        sIdentifier, ''']']);
elseif strcmp(sKind, 'OutPort')
    hScalarRef = mxx_xmltree('get_nodes', hDoc, ['/SFunction/Inports/Inport/ScalarRefs/ScalarRef[text() = ''', ...
        sIdentifier, ''']']);
end
hScalarRefs = mxx_xmltree('get_nodes', hScalarRef, '..');
hOuport = mxx_xmltree('get_nodes', hScalarRefs, '..');
sBusType = mxx_xmltree('get_attribute', hOuport, 'type');
sType = i_getSignalType(hDoc, sBusType, sIdentifier);
end


%%
function sType = i_getSignalType(hDoc, sBusType, sIdentifier)
casBuiltinTypes = i_getBuiltinTypes();

sType = '';
hBusNode = mxx_xmltree('get_nodes', hDoc, ['/SFunction/Types/BusType[@name = ''', sBusType, ''']']);
casSignals = strsplit(sIdentifier, '.');
for i = numel(casSignals):-1:1
    [sSigName, ~] = strtok(casSignals{i}, '(');
    hSig = mxx_xmltree('get_nodes', hBusNode, ['/SFunction/Types/BusType[@name = ''', sBusType, ''']', ...
        '/Comp[@name = ''', sSigName, ''']']);
    if ~isempty(hSig)
        sType = mxx_xmltree('get_attribute', hSig, 'type');
        bIsBusType = ~any(strcmp(sType, casBuiltinTypes)) && ~strncmp(sType, 'fixdt', 5);
        if bIsBusType
            sBusType = sType;
            sType = i_getSignalType(hDoc, sBusType, sIdentifier);
        end
        break;        
    end
end
end


%%
function casBuiltinTypes = i_getBuiltinTypes()
casBuiltinTypes = { ...
    'single', ...
    'double', ...
    'boolean', ...
    'int8', ...
    'int16', ...
    'int32', ...
    'int64', ...
    'uint8', ...
    'uint16', ...
    'uint32', ...
    'uint64'};
end
