function exportCodeDescriptorToJSON(sCodegenFolder, filename)

if nargin < 2
    error('Usage: exportCodeDescriptorToJSON(object, filename)');
end


descObj = coder.getCodeDescriptor(sCodegenFolder);

outStruct = struct();

casAllItfTypes = descObj.getAllDataInterfaceTypes();
outStruct.('a') = extract_props(casAllItfTypes);

casFuncItfTypes = descObj.getAllFunctionInterfaceTypes();
outStruct.('b') = extract_props(casFuncItfTypes);

casServiceItfs = descObj.getServices();
outStruct.('Services') = extract_props(casServiceItfs);

casActualDataItfTypes = descObj.getDataInterfaceTypes();
outStruct.('d') = extract_props(casActualDataItfTypes);

casActuatFuncItfTypes = descObj.getFunctionInterfaceTypes();
outStruct.('f') = extract_props(casActuatFuncItfTypes);


% serviceFunctionPrototype = getServiceFunctionPrototype(codeDescObj,serviceFunctionName)

% Data Interface Types
casDataInterfaceTypes = {'Inports','Outports','Parameters','GlobalDataStores','SharedLocalDataStores','ExternalParameterObjects','ModelParameters','InternalData'};
for iType = 1:numel(casDataInterfaceTypes)
    outStruct.(casDataInterfaceTypes{iType})= extract_props(descObj.getDataInterfaces(casDataInterfaceTypes{iType}), casDataInterfaceTypes{iType});
end

casFuncInterfaceTypes = {'Allocation','Initialize','Output','Update','Terminate','ServerCallPoints'};
for iType = 1:numel(casFuncInterfaceTypes)
    outStruct.(casFuncInterfaceTypes{iType})= extract_props(descObj.getFunctionInterfaces(casFuncInterfaceTypes{iType}), casFuncInterfaceTypes{iType});
end

% descObj.getFunctionInterfaceTypes         

%% --- Save to JSON
jsonStr = jsonencode(outStruct, 'PrettyPrint', true);
fid = fopen(filename, 'w');
if fid == -1
    error('Cannot open %s for writing.', filename);
end
fwrite(fid, jsonStr, 'char');
fclose(fid);

fprintf('Object info (with attempted method calls) saved to %s\n', filename);

end


function outStruct = extract_props(obj, sSrcPropName)

casExcludedProps = {'Implementation'};

outStruct = [];
if isempty(obj), return, end

if nargin == 1
    sSrcPropName = inputname(1);
end

% Make result JSON-friendly
if isobject(obj)

    mc = metaclass(obj);
    if ~contains(mc.Name,'coder.descriptor'), return, end

    %% --- Collect readable properties
    propsStruct = struct();
    propsStructTmp = struct();

    neObj = numel(obj);
    caVal = {};
    for o = 1:neObj
        neProp = numel(mc.Properties);
        for p = 1:neProp
            prop = mc.Properties{p};
            if prop.Hidden || strcmp(prop.GetAccess,'private')
                continue;
            end
            sPropName = prop.Name;
            if ismember(sPropName, casExcludedProps)
                continue;
            end
            try
                val = obj(o).(sPropName);
            catch
                val = '<<Unreadable property>>';
            end
            if isobject(val) && ~isnumeric(val) && ~islogical(val) && ~ischar(val)
                  val = extract_props(val, sPropName);
            end
            propsStructTmp.(sPropName) = val;
        end
        caVal{o} = propsStructTmp;
    end
    propsStruct.(sSrcPropName) = caVal;

elseif isstruct(obj)
    neProps = numel(val);
else
    val = obj;
    propsStruct.(sSrcPropName) = val;
end

%% --- Build output structure
outStruct = struct();
outStruct = propsStruct;
% outStruct.MethodResults = methodStruct;
end