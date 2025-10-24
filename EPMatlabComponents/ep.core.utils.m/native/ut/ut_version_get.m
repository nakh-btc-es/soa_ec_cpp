function ut_version_get()
% Tests, if the delgation of ep_core_version_get works.
%
%  function ut_version_get()
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

[sVersion, sPatch] = ep_core_version_get('ML');
stMlVersion = ver('Matlab');
MU_ASSERT_EQUAL(stMlVersion.Version, [sVersion,sPatch], 'Wrong Maltab version extracted');
