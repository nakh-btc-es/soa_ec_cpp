function [bSuccess, sError] = sltu_assert_compilable(sCodeModel, bIsLegacyCodegen)
bSuccess = false;
sError = '';

if (nargin < 2)
    bIsLegacyCodegen = false;
end

[astIncludes, astDefines, astFiles] = i_readOutInfo(sCodeModel, bIsLegacyCodegen);

casMexIncludes = cell(1, numel(astIncludes));
for i = 1:numel(astIncludes)
    casMexIncludes{i} = sprintf('-I"%s"', astIncludes(i).path);
end

casMexDefines = cell(1, numel(astDefines));
for i = 1:numel(astDefines)
    if isempty(astDefines(i).value)
        casMexDefines{i} = sprintf('-D%s', astDefines(i).name);
    else
        casMexDefines{i} = sprintf('-D%s=%s', astDefines(i).name, astDefines(i).value);
    end
end

oOnCleanupReturn = i_switchToTempDir(); %#ok<NASGU> onCleanup object

sCompileMode = 'c';
casFiles = cell(1, numel(astFiles));
for i = 1:numel(astFiles)
    stFile = astFiles(i);
    
    casFiles{i} = sprintf('"%s"', fullfile(stFile.path, stFile.name));
    if (endsWith(stFile.name, 'cpp'))
        sCompileMode = 'cpp';
    end
end

sFakeMexFile = sprintf('"%s"', i_createFakeMexFile(sCompileMode));

try
    sOutFile = 'my_compile_check';
    mex('-output', sOutFile, casMexIncludes{:}, casMexDefines{:}, casFiles{:}, sFakeMexFile);
    bSuccess = (exist(sOutFile, 'file') ~= 0);
    if ~bSuccess
        sError = 'Code result file is missing.';
    end
catch oEx
    sError = oEx.getReport('basic', 'hyperlinks', 'off');
    warning('SLTU:MEX:FAILED', '%s', sError);
end
end


%%
function [astIncludes, astDefines, astFiles] = i_readOutInfo(sCodeModel, bIsLegacyCodegen)
[hRoot, oOnCleanupCloseDoc] = i_openXml(sCodeModel); %#ok<ASGLU> onCleanup object
if ~bIsLegacyCodegen
    astIncludes = i_readAllIncludePaths(hRoot);
    astDefines  = i_readAllDefines(hRoot);
    astFiles    = i_readAllFiles(hRoot);
else
    astIncludes = i_readCodegenAllIncludePaths(hRoot);
    astDefines  = i_readCodegenAllDefines(hRoot);
    astFiles    = i_readCodegenAllFiles(hRoot);
end
end


%%
function oOnCleanupReturn = i_switchToTempDir()
sPwd = pwd;

sTempdir = tempname();
mkdir(sTempdir)
cd(sTempdir);

oOnCleanupReturn = onCleanup(@() i_returnAndRemoveDir(sPwd, sTempdir));
end


%%
function i_returnAndRemoveDir(sDirToReturnTo, sDirToBeRemoved)
cd(sDirToReturnTo);
rmdir(sDirToBeRemoved, 's');
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end

%%
function astFiles = i_readAllFiles(hRoot)
astFiles = mxx_xmltree('get_attributes', hRoot, '/CodeModel/Files/File', ...
    'name', ...
    'path', ...
    'kind', ...
    'annotate');
end


%%
function astIncludes = i_readAllIncludePaths(hRoot)
astIncludes = mxx_xmltree('get_attributes', hRoot, '/CodeModel/IncludePaths/IncludePath', 'path');
end


%%
function astDefines = i_readAllDefines(hRoot)
astDefines = mxx_xmltree('get_attributes', hRoot, '/CodeModel/Defines/Define', 'name', 'value');
end


%%
function astFiles = i_readCodegenAllFiles(hRoot)
astFiles = mxx_xmltree('get_attributes', hRoot, '/cg:CodeGeneration/cg:FileList/cg:File', ...
    'name', ...
    'path');
end


%%
function astIncludes = i_readCodegenAllIncludePaths(hRoot)
astIncludes = mxx_xmltree('get_attributes', hRoot, '/cg:CodeGeneration/cg:IncludePaths/cg:IncludePath', 'path');
end


%%
function astDefines = i_readCodegenAllDefines(hRoot)
astDefines = mxx_xmltree('get_attributes', hRoot, '/cg:CodeGeneration/cg:Defines/cg:Define', 'name', 'value');
end


%%
function sFakeMexFile = i_createFakeMexFile(sCompileMode)
sFakeMexFile = [tempname(pwd), '.', sCompileMode];

hFid = fopen(sFakeMexFile, 'w');
fprintf(hFid, '%s\n', i_fakeMexContent());
fclose(hFid);
end


%%
function sContent = i_fakeMexContent()
sContent = sprintf('%s\n\n', '#include "mex.h"');
sContent = [sContent, ...
    sprintf('%s\n\n', 'void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {}')];

end
