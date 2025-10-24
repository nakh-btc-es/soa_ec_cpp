function hModel = ep_new_model_create(varargin)
% Creates a new empty model in memory (not in open state!) and returns the handle to it.
%
% function hModel = ep_new_model_create(sModelName)
%
%   INPUT               DESCRIPTION
%     varargin         (array)            input for "new_system()" method
%
%   OUTPUT              DESCRIPTION
%     hModel           (handle)           handle for the new model in memory
%


%%
hModel = new_system(varargin);
Simulink.BlockDiagram.deleteContents(varargin{1});
end