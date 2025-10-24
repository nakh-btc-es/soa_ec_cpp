function ut_m01_ma_generic_check(sMaFile)
% generic tests in context of ModelAnalysis.xml
%
% note: just a helper function for UnitTests   
%
%

% AUTHOR(S):
%   Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 86015 $ 
%   Last modified: $Date: 2011-04-26 10:06:58 +0200 (Di, 26 Apr 2011) $ 
%   $Author: ahornste $

persistent sMaDtdFile;

if isempty(sMaDtdFile)
    sMaDtdFile = ut_m01_get_ma_dtd();
end


%%
if (nargin ~= 1)
    error('UT:USAGE_ERROR', ...
        'ModelAnalysis file required as argument for checking.');
end
if ~exist(sMaFile, 'file')
    error('UT:FATAL_ERROR', 'ModelAnalysis file "%s" is missing.', sMaFile);
end


%%
try
    sRootDir = fullfile(pwd(), 'generic_check');
    if exist(sRootDir, 'dir')
        rmdir(sRootDir, 's');
    end
    mkdir(sRootDir);
    stEnv = ut_messenger_env_create(sRootDir);
    
catch oEx
    MU_FAIL_FATAL(sprintf('Could not create env for generic test: "%s."', ...
        oEx.message));
end


%%
try
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr == 0, sprintf('Invalid ModelAnalysis file:\n%s', sErr));
    
catch oEx
    MU_FAIL(sprintf('Unexpected exception: "%s".', oEx.message));
end
end
