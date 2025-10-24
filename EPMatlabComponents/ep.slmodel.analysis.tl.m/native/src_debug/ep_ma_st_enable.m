function ep_ma_st_enable()
% Executing this function enables the execution of Matlab STs directly inside the Matlab console.
%
%  function ep_ma_ut_enable(bWithLegacyUT)
%

ep_ats_ut_enable({'ep.ats.models.customer', 'ep.ats.models.featuretest'});
end