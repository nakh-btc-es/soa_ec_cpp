function [bAdaptSuccess, casErrors] = tu_test_model_adapt(varargin)
% LEGACY: only a workaround wrapper for the ATS adapt function (preferably use that one directly)
[bAdaptSuccess, casErrors] = ep_ats_test_model_adapt(varargin{:});
end
