function it_version_compare()
% Tests the version compare method
%
%  function it_version_compare()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

MU_ASSERT_EQUAL(ep_core_version_compare('ML1.0'), 1);
MU_ASSERT_EQUAL(ep_core_version_compare('TL1.0'), 1);
end