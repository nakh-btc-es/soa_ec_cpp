function ut_legacy_env_get()
% Tests if the legacy structure is correctly constructed.
%
%  function ut_transform_args()
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

xEnv = EPEnvironment();
stEnvLegacy = ep_core_legacy_env_get(xEnv);
MU_ASSERT_TRUE(isa(stEnvLegacy.hMessenger, 'EPEnvironment'), 'xEnv has not been set.');
MU_ASSERT_TRUE(exist(stEnvLegacy.sOutputDirectory, 'dir'), 'Output dir has not been generated.');
MU_ASSERT_TRUE(exist(stEnvLegacy.sTmpPath, 'dir'), 'Temp dir has not been generated.');
MU_ASSERT_TRUE(exist(stEnvLegacy.sResultPath, 'dir'), 'Result dir has not been generated.');
EPEnvironment.deleteDirectory(stEnvLegacy.sOutputDirectory);
MU_ASSERT_TRUE(~exist(stEnvLegacy.sOutputDirectory, 'dir'), 'Output dir has not been deleted.');
xEnv.clear();