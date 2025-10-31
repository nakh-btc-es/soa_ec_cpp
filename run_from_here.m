
addpath(genpath('Y:\Documents\GitHub\soa_ec_cpp\EPMatlabComponents\ep.slmodel.m\native\src'))
addpath(genpath('Y:\Documents\GitHub\soa_ec_cpp\EPMatlabComponents\ep.legacy.core.utils.m\native\src'))
addpath(genpath('Y:\Documents\GitHub\soa_ec_cpp\EPMatlabComponents\ep.slmodel.m\native\src'))
addpath(genpath('Y:\Documents\GitHub\soa_ec_cpp\EPMatlabComponents\ep.core.utils.m\native\src'))
addpath(genpath('Y:\Documents\GitHub\soa_ec_cpp\EPMatlabComponents\ep.slmodel.openclose.m\native\src'))


%ep_ec_aa_provided_methods_get
%ep_ec_aa_required_methods_get


setenv('EP_DEACTIVATE_AA_VERSION_CHECK', 'true')

ep_ec_model_wrapper_create('ModelFile','oClientServer_Model.slx','InitScript','init.m' )