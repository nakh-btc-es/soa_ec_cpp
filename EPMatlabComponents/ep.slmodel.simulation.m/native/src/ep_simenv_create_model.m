function hModel = ep_simenv_create_model(sModel)
% Creates a new model based on the given input string
%
% functionhModel = ep_simenv_create_model(sModel)
%
%   INPUT           DESCRIPTION
%     sModel                  (string)  Name of the model
%
%   OUTPUT          DESCRIPTION
%     hModel                  (handle)  Handle of the newly created model


%%
% close any previous created models
casLoadedModels = find_system('type', 'block_diagram');
bIsLoaded = any(strcmp(sModel, casLoadedModels));
if bIsLoaded
    close_system(sModel, 1);
end
hModel = ep_new_model_create(sModel);
end


