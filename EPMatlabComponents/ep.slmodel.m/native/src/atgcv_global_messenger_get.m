function hMessenger = atgcv_global_messenger_get()
% Close the global messenger
%
% function hMessenger = atgcv_global_messenger_get()
%
%   INPUT               DESCRIPTION
%
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%     
%
%   <et_copyright>
%
%

%% 
persistent p_globalEnv;

if isempty(p_globalEnv)
    p_globalEnv = EPEnvironment();
end

hMessenger = p_globalEnv;
end
