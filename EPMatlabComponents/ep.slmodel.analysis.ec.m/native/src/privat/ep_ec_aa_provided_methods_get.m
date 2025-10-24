function aoProvidedMethods = ep_ec_aa_provided_methods_get(sAutosarModelName)
% Analyzes the AA model and returns all provided methods.
%
%  function aoProvidedMethods = ep_ec_aa_provided_methods_get(sAutosarModelName)
%
%  INPUT              DESCRIPTION
%    sAutosarModelName           (string)    name of the AUTOSAR model (default = current model)
%
%  OUTPUT            DESCRIPTION
%    aoProvidedMethods           (objects)   array of Eca.ec.wrapper.ProvidedMethod objects
%
%
% ! Requirement: Provided model has to be loaded/open and in "compiled" mode.
%

bNonAutosar = true;

%%
if (nargin < 1)
    sAutosarModelName = bdroot(gcs);
end
aoProvidedMethods = repmat(Eca.aa.wrapper.ProvidedMethod, 1, 0);

casTriggerPorts = ep_find_system(sAutosarModelName, ...
    'BlockType',          'TriggerPort', ...
    'IsSimulinkFunction', 'on', ...
    'FunctionVisibility', 'port');
if isempty(casTriggerPorts)
    return;
end

if ~bNonAutosar
    oArProps = autosar.api.getAUTOSARProperties(sAutosarModelName);
    oArSLMap = autosar.api.getSimulinkMapping(sAutosarModelName);
    sArComponentPath = oArProps.get('XmlOptions', 'ComponentQualifiedName');
end

nTriggers = numel(casTriggerPorts);
aoProvidedMethods = repmat(Eca.aa.wrapper.ProvidedMethod, 1, nTriggers);
abSelect = false(size(aoProvidedMethods));
for k = 1:nTriggers
    sTriggerPort = casTriggerPorts{k};
    sSLFuncBlock = get_param(sTriggerPort, 'Parent');

    sSLFunctionName = get_param(sTriggerPort, 'FunctionName');
    sScopedFunctionName = [get_param(sTriggerPort, 'ScopeName'), '.', sSLFunctionName];
    try
        if(bNonAutosar)
            casParts = strsplit(sScopedFunctionName, '.');
            sArPortName = casParts{1};
            sArMethodOrFieldName = casParts{2};
        else
            [sArPortName, sArMethodOrFieldName] = oArSLMap.getFunction(sScopedFunctionName);
        end
    catch
        continue;
    end

    abSelect(k) = true;

    aoProvidedMethods(k).sSlFunctionBlock = sSLFuncBlock;
    aoProvidedMethods(k).sFunctionName    = sScopedFunctionName;

    [aoInArgs, aoOutArgs] = i_getFunctionArguments(sSLFuncBlock);
    casArgInNames = arrayfun(@(o) o.sName, aoInArgs, 'UniformOutput', false);
    casArgOutNames = arrayfun(@(o) o.sName, aoOutArgs, 'UniformOutput', false);
    
    aoProvidedMethods(k).sFunctionPrototype = i_createPrototype(sScopedFunctionName, casArgInNames, casArgOutNames);
    aoProvidedMethods(k).aoFunctionInArgs = aoInArgs;
    aoProvidedMethods(k).aoFunctionOutArgs = aoOutArgs;

    if(bNonAutosar)
        casArProvPortPath = {};
        sArMethodPath = '';
        sArFieldPath = '';
        sArServiceInterfacePath = 'IF';
    else
        casArProvPortPath = find(oArProps, sArComponentPath, 'ProvidedPort', ...
            'Name',     sArPortName, ...
            'PathType', 'FullyQualified');
        sArServiceInterfacePath = get(oArProps, char(casArProvPortPath), 'Interface', 'PathType', 'FullyQualified');
        [sArMethodPath, sArFieldPath] = i_getMethodOrFieldPath(oArProps, sArServiceInterfacePath, sArMethodOrFieldName);  
        aoProvidedMethods(k).sArComponentName = i_getNameFromPath(sArComponentPath);
    end

    aoProvidedMethods(k).sArInterfaceName = i_getNameFromPath(sArServiceInterfacePath);
    aoProvidedMethods(k).sArPortName      = sArPortName;

    if ~isempty(sArFieldPath)
        aoProvidedMethods(k).sArMethodName = '';
        aoProvidedMethods(k).sArFieldName  = sArMethodOrFieldName;
        aoProvidedMethods(k).aoArMethodArgs = i_getFieldAccessArguments(aoInArgs, aoOutArgs);
        if isempty(aoInArgs)
            sFieldAccessKind = 'get';
        else
            sFieldAccessKind = 'set';
        end
        aoProvidedMethods(k).sFieldAccessKind = sFieldAccessKind;
    else
        aoProvidedMethods(k).sArMethodName    = sArMethodOrFieldName;
        if ~(bNonAutosar)
            aoProvidedMethods(k).aoArMethodArgs   = i_getMethodArguments(oArProps, sArMethodPath);
        end
        aoProvidedMethods(k).sFieldAccessKind = '';
    end
    
end
aoProvidedMethods = aoProvidedMethods(abSelect);
end


%%
function [sArMethodPath, sArFieldPath] = i_getMethodOrFieldPath(oArProps, sArServiceInterfacePath, sArMethodOrFieldName)
sArMethodPath = '';
sArFieldPath = '';

sArMethodOrFieldPath = [sArServiceInterfacePath '/' sArMethodOrFieldName];
casFoundMethodPaths = oArProps.get(sArServiceInterfacePath, 'Methods', 'PathType', 'FullyQualified');
if ~isempty(casFoundMethodPaths) && any(strcmp(sArMethodOrFieldPath, casFoundMethodPaths))
    sArMethodPath = sArMethodOrFieldPath;
end

casFoundFieldPaths = oArProps.get(sArServiceInterfacePath, 'Fields', 'PathType', 'FullyQualified');
if ~isempty(casFoundFieldPaths) && any(strcmp(sArMethodOrFieldPath, casFoundFieldPaths))
    sArFieldPath = sArMethodOrFieldPath;
end
end


%%
function aoFieldAccessArgs = i_getFieldAccessArguments(aoInArgs, aoOutArgs)
aoFieldAccessArgs = [ ...
    arrayfun(@(o) i_translateSlFunctionArgToArMethodArg(o, 'in'), aoInArgs), ...
    arrayfun(@(o) i_translateSlFunctionArgToArMethodArg(o, 'out'), aoOutArgs)];
end


%%
function oArMethodArg = i_translateSlFunctionArgToArMethodArg(oFuncArg, sDirection)
oArMethodArg = Eca.aa.wrapper.MethodArg;
oArMethodArg.sName = oFuncArg.sName;
oArMethodArg.sDirection = sDirection;
end


%%
function aoArgs = i_getMethodArguments(oArProps, sMethodPath)
casArgumentsPaths = get(oArProps, sMethodPath, 'Arguments', 'PathType', 'FullyQualified');
nArgs = numel(casArgumentsPaths);

aoArgs = repmat(Eca.aa.wrapper.MethodArg, 1, nArgs);
for i = 1:nArgs
    sArgPath = casArgumentsPaths{i};

    aoArgs(i).sName = i_getNameFromPath(sArgPath);
    aoArgs(i).sDirection = get(oArProps, sArgPath, 'Direction');
end
end


%%
function [aoInArgs, aoOutArgs] = i_getFunctionArguments(sSlFunctionBlock)
casArgInBlocks = ep_find_system(sSlFunctionBlock, ...
    'SearchDepth', 1, ...
    'BlockType',   'ArgIn');
aoInArgs = cellfun(@i_getFunctionArgFromArgBlock, i_sortArgBlocksAccordingToPortNum(casArgInBlocks));

casArgOutBlocks = ep_find_system(sSlFunctionBlock, ...
    'SearchDepth', 1, ...
    'BlockType',   'ArgOut');
aoOutArgs = cellfun(@i_getFunctionArgFromArgBlock, i_sortArgBlocksAccordingToPortNum(casArgOutBlocks));
end


%%
function casArgBlocks = i_sortArgBlocksAccordingToPortNum(casArgBlocks)
aiPortNums = cellfun(@(x) str2double(x), get_param(casArgBlocks, 'Port'));
[~, aiSortedIdx] = sort(aiPortNums);
casArgBlocks = casArgBlocks(aiSortedIdx);
end


%%
function oFunctionArg = i_getFunctionArgFromArgBlock(sArgBlock)
sOutDataTypeStr = get_param(sArgBlock, 'OutDataTypeStr');

stPortDT = get_param(sArgBlock, 'CompiledPortDataTypes');
stPortDim = get_param(sArgBlock, 'CompiledPortDimensions');

bCompiledMode = ~isempty(stPortDT);

sDataType = '';
aiDim = [];
if bCompiledMode
    sBlockArgType = get_param(sArgBlock, 'BlockType');
    if strcmp(sBlockArgType, 'ArgIn')
        aiDim = stPortDim.Outport;
        sDataType = char(stPortDT.Outport);

    elseif strcmp(sBlockArgType, 'ArgOut')
        aiDim = stPortDim.Inport;
        sDataType = char(stPortDT.Inport);

    else
        warning('DEV:INTERNAL_ERROR', 'Unexpected: Blocktype.');
    end
else
    warning('DEV:INTERNAL_ERROR', 'Model not in compiled mode. Types and dimensions cannot be evaluated.');
end

if ~isempty(sDataType)
    sCodeDataType = ep_ec_sltype_to_ctype(bdroot(sArgBlock), sDataType);
    stTypeInfo = i_getTypeInfo(sDataType, sArgBlock);
else
    sCodeDataType = '';
    stTypeInfo = [];
end

oFunctionArg = Eca.aa.wrapper.FunctionArg;
oFunctionArg.sName = get_param(sArgBlock, 'ArgumentName');
oFunctionArg.sOutDataTypeStr = sOutDataTypeStr;
oFunctionArg.sDataType = sDataType;
oFunctionArg.sCodeDataType = sCodeDataType;
oFunctionArg.aiDim = aiDim;
oFunctionArg.stTypeInfo = stTypeInfo;
end


%%
function stTypeInfo = i_getTypeInfo(sDataType, sModelContext)
hResolverFunc = atgcv_m01_generic_resolver_get(sModelContext);
stTypeInfo = ep_sl_type_info_get(sDataType, hResolverFunc);
end


%%
function sPrototype = i_createPrototype(sFunctionName, casArgInNames, casArgOutNames)
if isempty(casArgOutNames)
    sOutParts = '';
else
    if numel(casArgOutNames) == 1
        sOutParts = [casArgOutNames{1} ' = '];
    else
        sOutParts = sprintf('[%s] = ', strjoin(casArgOutNames, ', '));
    end
end

sInParts = sprintf('(%s)', strjoin(casArgInNames, ', '));
sPrototype = [sOutParts sFunctionName sInParts];
end



%%
function sName = i_getNameFromPath(sPath)
[~, sName] = fileparts(sPath);
end

