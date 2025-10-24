function casDefinedTypes = ep_code_file_typedefs_get(sCodeFile)
% Retrieves all types from type definitions found inside the provided (header/source) code file.
%
% function casDefinedTypes = ep_code_file_typedefs_get(sCodeFile)
%
%  INPUT              DESCRIPTION
%    sCodeFile          (string)        Full path to the code file that shall be analyzed
%
%
%  OUTPUT            DESCRIPTION
%    casDefinedTypes    (strings)       Type names that have been defined inside the provided code file.
%

%%
if ~exist(sCodeFile, 'file')
    error('EP:FILE_MISSING', 'Provided code file "%s" is missing.', sCodeFile);
end

sContent = fileread(sCodeFile);
sContent = i_removeBracketedContent(sContent);
casDefinedTypes = i_findOneLineTypedefs(sContent);
end


%%
% remove content between and including brackets { xxxx }; specifically for typedefs of nested sructs --> Example:
% typedef struct {
%    struct {
%          int fieldInner;
%    } fieldOuter;
%  } myNestedStruct;
%    
function sContentNew = i_removeBracketedContent(sContent)
sContentNew = regexprep(sContent, '{[^{}]+}', '');
if (numel(sContentNew) < numel(sContent))
    sContentNew = i_removeBracketedContent(sContentNew);
end
end


%%
function casTypedefs = i_findOneLineTypedefs(sContent)
ccasTypedefs = regexp(sContent, '\<typedef \s*\S+ \s*(\S+)\s*;', 'tokens');
casTypedefs = [ccasTypedefs{:}];
end

