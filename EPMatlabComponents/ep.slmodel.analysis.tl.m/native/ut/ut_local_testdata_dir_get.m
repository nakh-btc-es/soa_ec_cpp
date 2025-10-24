function sLocation = ut_local_testdata_dir_get(varargin)
% Returns the location of the local testdata.
%
% function sDir = ut_local_testdata_dir_get(varargin)
%


%%
stModelPool = ep_ats_model_pool_get();
sLocation = fullfile(stModelPool.sLocation, 'MA');

if ~exist(sLocation, 'dir')
    MU_FAIL_FATAL(sprintf('Expected model location for local testdata "%s" not found.', sLocation));
end
end
