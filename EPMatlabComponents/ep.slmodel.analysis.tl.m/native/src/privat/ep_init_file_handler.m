function varargout = ep_init_file_handler(sCmd, varargin)

switch lower(sCmd)
    case 'create'
        varargout{1} = i_createInitFileData(varargin{:});
        
    case 'add_include'
        i_addInclude(varargin{:});
        
    case 'add_group_init_func'
        varargout{1} = i_addGroupInitFunction(varargin{:});
        
    otherwise
        error('EP:INIT_FILE_HANDLER:ERROR', 'Unknown command "%s".', sCmd);
end
end


%%
function stInitFileData = i_createInitFileData(sFile)
% assert that we start with a fresh empty file
if exist(sFile, 'file')
    error('EP:INIT_FILE_HANDLER:ERROR', 'File "%s" is already existing.', sFile);
end

stInitFileData = struct( ...
    'sFile',             sFile, ...
    'jKnownIncludeSet',  java.util.HashSet(), ...
    'jKnownInitFuncSet', java.util.HashSet(), ...
    'jGroupInitFuncMap', java.util.HashMap());
end


%%
function sGroupInitFunc = i_addGroupInitFunction(stInitFileData, casInitFuncs)
sKey = i_getGroupInitFuncKey(casInitFuncs);
if (stInitFileData.jGroupInitFuncMap.containsKey(sKey))
    sGroupInitFunc = char(stInitFileData.jGroupInitFuncMap.get(sKey));
else
    casUnknownInitFuncs = ...
        casInitFuncs(~cellfun(@(sFunc) stInitFileData.jKnownInitFuncSet.contains(sFunc), casInitFuncs));
    
    nCurrentNum = stInitFileData.jGroupInitFuncMap.size() + 1;
    sGroupInitFunc = sprintf('btc__init_func_%d', nCurrentNum);
    i_appendGroupFuncToFile(stInitFileData.sFile, sGroupInitFunc, casInitFuncs, casUnknownInitFuncs);
    
    for i = 1:numel(casUnknownInitFuncs)
        stInitFileData.jKnownInitFuncSet.add(casUnknownInitFuncs{i});
    end
    stInitFileData.jGroupInitFuncMap.put(sKey, sGroupInitFunc);
end
end


%%
function i_addInclude(stInitFileData, sIncludeName, casIncludedFuncs)
if ~stInitFileData.jKnownIncludeSet.contains(sIncludeName)
    i_appendIncludeToFile(stInitFileData.sFile, sIncludeName)
    stInitFileData.jKnownIncludeSet.add(sIncludeName);
end
for i = 1:numel(casIncludedFuncs)
    if ~stInitFileData.jKnownInitFuncSet.contains(casIncludedFuncs{i})
        stInitFileData.jKnownInitFuncSet.add(casIncludedFuncs{i});
    end
end
end


%%
function i_appendGroupFuncToFile(sFile, sGroupFuncName, casInitFuncs, casUnknownInitFuncs)
bIsAppend = exist(sFile, 'file');

hFile = fopen(sFile, 'a');
oOnCleanupCloseFile = onCleanup(@() fclose(hFile));

if bIsAppend
    fprintf(hFile, '\n'); % add an empty line if we are appending
end

% make unknown functions known be external declaration
if ~isempty(casUnknownInitFuncs)
    for i = 1:numel(casUnknownInitFuncs)
        fprintf(hFile, 'extern void %s();\n', casUnknownInitFuncs{i});
    end
    fprintf(hFile, '\n');
end

% define the group function that is calling all the init functions
fprintf(hFile, 'void %s() {\n', sGroupFuncName);
for i = 1:numel(casInitFuncs)
    fprintf(hFile, '\t%s();\n', casInitFuncs{i});    
end
fprintf(hFile, '}\n');
end


%%
function i_appendIncludeToFile(sFile, sIncludeName)
bIsAppend = exist(sFile, 'file');

hFile = fopen(sFile, 'a');
oOnCleanupCloseFile = onCleanup(@() fclose(hFile));

if bIsAppend
    fprintf(hFile, '\n'); % add an empty line if we are appending
end

fprintf(hFile, '#include "%s"\n', sIncludeName);
end


%%
function sKey = i_getGroupInitFuncKey(casInitFuncs)
casFuncs = casInitFuncs(~cellfun('isempty', casInitFuncs));
if isempty(casFuncs)
    sKey = '';
else
    sKey = sprintf('%s|', casFuncs{:});
end
end

