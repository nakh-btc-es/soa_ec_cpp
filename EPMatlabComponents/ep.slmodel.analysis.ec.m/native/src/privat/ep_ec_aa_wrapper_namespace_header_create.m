function oEca = ep_ec_aa_wrapper_namespace_header_create(oEca)
% Workaround for namespace datatypes in the interface of the wrapper
%
%
%%
if (~oEca.bIsAdaptiveAutosar)
    return;
end

mNamespaceTypeMap = oEca.oAutosarMetaProps.mNamespaceTypeMapping;
if (~mNamespaceTypeMap.isempty())
    sPath = i_getTypedefPath(oEca);
    casNamespaces = mNamespaceTypeMap.keys;
    for i = 1:numel(casNamespaces)
        sNamespace = casNamespaces{i};
        if (isempty(sNamespace))
            continue;
        end
        astTypes = mNamespaceTypeMap(sNamespace);
        for k = 1: numel(astTypes)
            sName = astTypes(k).sType;
            sTypedefHeaderFile = fullfile(sPath, ['impl_type_' lower(sName) '.h']);
            casIncludeHeaders = {[strrep(lower(sNamespace), '::', '/') 'impl_type_' lower(sName) '.h']};
            
            % add sub includes when needed, i.e. for structs
            astSubTypes = i_getSubtypes(astTypes(k));
            if (~isempty(astSubTypes))
                [~, idx] = unique({astSubTypes.sType});
                astSubs = astSubTypes(idx);
                for j = 1:numel(astSubs)
                    if (strcmpi('Boolean', astSubs(j).sCategory))
                        continue;
                    end
                    casIncludeHeaders = [casIncludeHeaders ['impl_type_' lower(astSubs(j).sType) '.h']]; %#ok<AGROW>
                end
            end
            casContent = {['typedef ' lower(sNamespace) sName ' ' sName ';']};
            i_createHeaderFileCPP(sTypedefHeaderFile, casContent, casIncludeHeaders);
        end
    end

    if (exist(sPath, 'dir'))
        oEca.oRootScope.casCodegenIncludePaths = [oEca.oRootScope.casCodegenIncludePaths sPath];
    end
end
end


%%
function astSubTypes = i_getSubtypes(stType)
astSubTypes = stType.astSubTypes;
for i = 1:numel(astSubTypes)
    astSubTypes = [astSubTypes i_getSubtypes(astSubTypes(i))]; %#ok<AGROW>
end
end


%%
function sPath = i_getTypedefPath(oEca)
sPath = oEca.sAutosarWrapperCodegenPath;
if isempty(sPath)
    sPath = oEca.sAutosarCodegenPath;
end
sPath = fullfile(sPath , 'btc_typedefs');
end


%%
function i_createHeaderFileCPP(sFile, casContent, casIncludeFileNames)
[sDir, sFileName] = fileparts(sFile);
if ~exist(sDir, 'dir')
    mkdir(sDir);
end
hFid = fopen(sFile, 'w');
oOnCleanupCloseFile = onCleanup(@() fclose(hFid));

sGuardMacro = sprintf('_%s_EP_H_', upper(sFileName));
fprintf(hFid, '#ifndef %s\n', sGuardMacro);
fprintf(hFid, '#define %s\n', sGuardMacro);
fprintf(hFid, '\n');

casIncludeFileNames = cellstr(casIncludeFileNames);
if ~isempty(char(casIncludeFileNames))
    fprintf(hFid, '#include "%s"\n',  casIncludeFileNames{:});
end

fprintf(hFid, '\n');
fprintf(hFid, '%s\n', casContent{:});
fprintf(hFid, '\n');

fprintf(hFid, '#endif //%s\n', sGuardMacro);
end


