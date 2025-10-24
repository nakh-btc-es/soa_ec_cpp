function ut_abspath_get()
% Tests, if the ep_core_get_abspath() works.
%
%  function ut_abspath_get()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

%% some general vars
sCurrentDir = pwd;
[sParentDir, sDirName] = fileparts(sCurrentDir);


%% special case: no args
MU_ASSERT_EQUAL(ep_core_get_abspath(), sCurrentDir, ...
    'Empty args should yield current dir.');

%% current dir aliases
sExpectedAbsPath = sCurrentDir;
casCurrentDirAliases = { ...
    '', ...
    '.', ...
    sCurrentDir, ...
    fullfile(sCurrentDir, '..', sDirName), ...
    fullfile('..', sDirName), ...
    fullfile('.', '..', sDirName, '.', '..', sDirName, '.', '.')};
for i = 1:length(casCurrentDirAliases)
    sPath = casCurrentDirAliases{i};
    sAbsPath = ep_core_get_abspath(sPath);
    
    MU_ASSERT_TRUE(strcmp(sAbsPath, sExpectedAbsPath), ...
        sprintf('Expected AbsPath "%s" instead of "%s" for Path "%s".', ...
        sExpectedAbsPath, sAbsPath, sPath));
end
    
%% parent dir aliases
sExpectedAbsPath = sParentDir;
casParentDirAliases = { ...
    '..', ...
    sParentDir, ...
    fullfile(sCurrentDir, '..'), ...
    fullfile('..', sDirName, '..'), ...
    fullfile('.', '..', sDirName, '.', '..', '.', '.')};
for i = 1:length(casParentDirAliases)
    sPath = casParentDirAliases{i};
    sAbsPath = ep_core_get_abspath(sPath);
    
    MU_ASSERT_TRUE(strcmp(sAbsPath, sExpectedAbsPath), ...
        sprintf('Expected AbsPath "%s" instead of "%s" for Path "%s".', ...
        sExpectedAbsPath, sAbsPath, sPath));
end
end

