function ep_ma_ut_enable
% Executing this function enables the execution of Matlab UTs directly inside the Matlab console.
%
%  function ep_ma_ut_enable
%


%%
casNeededJarNames = { ...
    'ep.ats.models', ...
    'ep.ats.models.simple', ...
    'ep.ats.models.embeddedcoder', ...
    'ep.architecture.spec', ...
    'ep.architecture.spec.test.utils'};
ep_ats_ut_enable(casNeededJarNames);
end




