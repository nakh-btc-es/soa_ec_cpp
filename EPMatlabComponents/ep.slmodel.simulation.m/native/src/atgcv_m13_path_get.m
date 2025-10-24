function sPath = atgcv_m13_path_get(xSubsystem, varargin )
%
% function sPath = atgcv_m13_path_get(xSubsystem)
%

%%
sPath = ep_em_entity_attribute_get(xSubsystem, 'physicalPath');
end
