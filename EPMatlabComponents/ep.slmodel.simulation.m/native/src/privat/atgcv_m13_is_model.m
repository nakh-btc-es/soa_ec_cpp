function [bIsModel,sModel] = atgcv_m13_is_model(xScope)
sSubsysPath = atgcv_m13_path_get( xScope );
sModel = strtok(sSubsysPath,'/');
bIsModel = any(strcmp(get_param(sSubsysPath,'Type'),{'block_diagram'}));
end
