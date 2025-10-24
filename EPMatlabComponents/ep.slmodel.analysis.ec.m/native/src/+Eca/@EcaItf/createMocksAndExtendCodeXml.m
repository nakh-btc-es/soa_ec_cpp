function createMocksAndExtendCodeXml(oEca)

if ~oEca.bIsAdaptiveAutosar
    error('EP:INTERNAL:ERROR', 'Adaptive Autosar Mocks can only be created for AA models.');
end

jStubCode = java.io.File(oEca.sAdaptiveStubcodeXmlFile);
jCodeModel = java.io.File(oEca.sCodeXmlFile);

jMockGenerator = ep.arch.embeddedcoder.wrappercpp.MockGenerator();
jMockCodeResult = jMockGenerator.generate(jStubCode);
jMockGenerator.extendCodeModelXML(jCodeModel, jMockCodeResult);

% repair SUT code if needed
if i_bRequiresProxyFieldRepair(oEca)
    if oEca.bReuseExistingCode
        return;
    end
    if ~(strcmp(matlabRelease.Release,'R2023b') && matlabRelease.Update == 6)
        return;
    end

    i_repairCodeGenError(oEca);
end
end


%%
function bRequiresProxyFieldRepair = i_bRequiresProxyFieldRepair(oEca)
bRequiresProxyFieldRepair = false;
astRequiredPorts = oEca.oAutosarMetaProps.astRequiredPorts;
if ~isempty(astRequiredPorts)
    for i = 1:numel(astRequiredPorts)
        stInterface = astRequiredPorts(i).stInterface;
        astFields = stInterface.astFields;
        if ~isempty(astFields)
            for k = 1:numel(astFields)
                bRequiresProxyFieldRepair = (astFields(k).bHasGetter || astFields(k).bHasSetter);
                if bRequiresProxyFieldRepair
                    return;
                end
            end
        end
    end
end
end


%%
function  i_repairCodeGenError(oEca)
sMainCodeFile = fullfile(oEca.sAutosarCodegenPath, [oEca.sAutosarModelName, '.cpp']);
fileData = fileread(sMainCodeFile);

sMarkerString = ['//This file was modified by BTC Embedded Platform due codegen issues ', ...
    'when using get/set calls on required fields'];
if contains(fileData, sMarkerString)
    return;
end

% use flattened string data without linebreaks for extractBetween() method
fileDataFlat = strjoin(cellfun(@strip, splitlines(fileData), 'UniformOutput', false),'');

astRequiredPorts = oEca.oAutosarMetaProps.astRequiredPorts;
stRequiredMethods = ep_core_feval('ep_ec_aa_required_methods_get', oEca.sAutosarModelName);
adEditedLines = [];
for i = 1:numel(stRequiredMethods)
    stMethod = stRequiredMethods(i);
    if isempty(stMethod.sArFieldName)
        continue;
    end
    sPort = stMethod.sArPortName;
    stReqPort = astRequiredPorts(arrayfun(@(x) strcmp(sPort, x.sPortName), astRequiredPorts));
    sNamespace = i_getNamespaceFromPort(stReqPort.stInterface);
    sCodeFieldName = i_capitalizeFirstString(stMethod.sArFieldName);

    sVariableDeclarationUp = [sNamespace ,'proxy::fields::', sCodeFieldName, '::FieldType'];
    sVariableDeclarationLow = [sNamespace ,'proxy::fields::', stMethod.sArFieldName, '::FieldType'];

    casCodeVariables = cat(1, extractBetween(fileDataFlat, sVariableDeclarationUp, ';'), ...
        extractBetween(fileDataFlat, sVariableDeclarationLow, ';'));

    casSplitData = splitlines(fileData);
    for k = 1:numel(casCodeVariables)
        sCodeVar = strip(casCodeVariables{k});
        if ~contains(sCodeVar, 'callOutput')
            continue;
        end
        casFunctionParts = strsplit(stMethod.sFunctionPrototype, '=');
        sFunctionOutput = strip(casFunctionParts{1});
        sCodegenError = [sCodeVar, '.', sFunctionOutput];
        sCodegenFix = sCodeVar;

        adStartingLines = find(~cellfun(@isempty, strfind(casSplitData, ['(', stMethod.sArFieldName, 'ResultPtr->HasValue())']))); %#ok
        dEditableLines = 25;
        for j = 1:numel(adStartingLines)
            %skip replacement if already edited
            if ismember(adStartingLines(j), adEditedLines)
                continue;
            end
            adIntervall = adStartingLines(j):(adStartingLines(j) + dEditableLines);
            %skip replacement if error is not inside code intervall
            if ~any(contains(casSplitData(adIntervall), sCodegenError))
                continue;
            end
            casSplitData(adIntervall) = strrep(casSplitData(adIntervall), sCodegenError, sCodegenFix);
            adEditedLines(end+1) = adStartingLines(j); %#ok
        end
    end
    fileData = strjoin(casSplitData, newline);
end

if ~isempty(adEditedLines)
    fileData = [fileData, newline, newline, sMarkerString];

    % Overwrite the SUT code with the updated filecontent;
    fid = fopen(sMainCodeFile, 'w');
    if fid == -1
        warning('Cannot open file: %s', sMainCodeFile);
    end
    fprintf(fid, '%s', fileData);
    fclose(fid);
end
end


%%
function sNamespace = i_getNamespaceFromPort(stInferface)
sNamespace = '';
for i = 1:numel(stInferface.casNamespaces)
    sNamespace = [sNamespace, lower(stInferface.casNamespaces{i}), '::']; %#ok
end
end


%%
function sString = i_capitalizeFirstString(sString)
asTmp = sString';
asTmp(1) = upper(asTmp(1));
sString = asTmp';
end


