function jDeclaredRteParams = ep_code_rte_params_get(casRteStubFiles)
jDeclaredRteParams = java.util.HashSet();

for i = 1:numel(casRteStubFiles)
    sStubFile = casRteStubFiles{i};

    i_fillSetWithParamsStubFile(jDeclaredRteParams, sStubFile);
end
end


%%
function i_fillSetWithParamsStubFile(jDeclaredRteParams, sStubFile)
try
    sContent = fileread(sStubFile);
catch oEx %#ok<NASGU>
    return;
end

if i_isHeaderFile(sStubFile)
    i_fillSetFromHeaderContent(jDeclaredRteParams, sContent);
else
    i_fillSetFromSourceContent(jDeclaredRteParams, sContent);
end
end


%%
function bIsHeader = i_isHeaderFile(sFile)
[~, ~, sExt] = fileparts(sFile);
bIsHeader = strcmpi(sExt, '.h');
end


%%
function i_fillSetFromHeaderContent(jDeclaredRteParams, sContent)
ccasExternVars = regexp(sContent, '\<extern\s+\S+\s+(\S+_data)[\[\]0-9]*\s*;', 'tokens');
if ~isempty(ccasExternVars)
    casExternVars = [ccasExternVars{:}];

    for i = 1:numel(casExternVars)
        jDeclaredRteParams.add(casExternVars{i});
    end
end
end


%%
function i_fillSetFromSourceContent(jDeclaredRteParams, sContent)
ccasExternVars = regexp(sContent, '\<\S+\s+(\S+_data)[\[\]0-9]*\s*[;=]', 'tokens');
if ~isempty(ccasExternVars)
    casExternVars = [ccasExternVars{:}];

    for i = 1:numel(casExternVars)
        jDeclaredRteParams.add(casExternVars{i});
    end
end
end
