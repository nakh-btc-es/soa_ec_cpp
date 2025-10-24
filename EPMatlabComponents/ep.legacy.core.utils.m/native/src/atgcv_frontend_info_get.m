function fe_info = atgcv_frontend_info_get
% Retrieve frontend info (Matlab, Simulink, Stateflow, and so on ... ).
%
% function fe_info = osc_frontend_info_get
%   PARAMETER(S)    DESCRIPTION
%   -
%
%   OUTPUT
%   - fe_info       Structure containing all front information.
%
% AUTHOR(S):
%   Tom.Bienmueller@osc-es.de
% $$$COPYRIGHT$$$-2003
%
% $Revision: 48234 $ Last modified: $Date: 2009-01-22 11:02:42 +0100 (Do, 22 Jan 2009) $ $Author: lochman $ 

persistent frontend_info;

if isempty(frontend_info)

    matlab_info = ver('matlab');
    frontend_info.matlab_info.name    = matlab_info.Name;
    frontend_info.matlab_info.version = matlab_info.Version;
    frontend_info.matlab_info.release = matlab_info.Release;
    frontend_info.matlab_info.date    = matlab_info.Date;
    
    frontend_info.simulink_info.name    = '';
    frontend_info.simulink_info.version = '';
    frontend_info.simulink_info.release = '';
    frontend_info.simulink_info.date    = '';
    
    frontend_info.stateflow_info.name    = '';
    frontend_info.stateflow_info.version = '';
    frontend_info.stateflow_info.release = '';
    frontend_info.stateflow_info.date    = '';
    
    frontend_info.ds_targetlink_info.name    = '';
    frontend_info.ds_targetlink_info.version = '';
    frontend_info.ds_targetlink_info.release = '';
    frontend_info.ds_targetlink_info.date    = '';
    
    frontend_info.ds_datadictionary_info.name    = '';
    frontend_info.ds_datadictionary_info.version = '';
    frontend_info.ds_datadictionary_info.release = '';
    frontend_info.ds_datadictionary_info.date    = '';
    
    fe_info = ver;
        
    for i=1:length(fe_info)
        if isempty(frontend_info.simulink_info.name) && ...
                strncmpi('simulink', fe_info(i).Name, length('simulink'))
            %  simulink info
            frontend_info.simulink_info.name            = fe_info(i).Name;
            frontend_info.simulink_info.version         = fe_info(i).Version;
            frontend_info.simulink_info.release         = fe_info(i).Release;
            frontend_info.simulink_info.date            = fe_info(i).Date;
            
        elseif isempty(frontend_info.stateflow_info.name) && ...
                strncmpi('stateflow', fe_info(i).Name, length('stateflow'))
            %  stateflow info
            frontend_info.stateflow_info.name            = fe_info(i).Name;
            frontend_info.stateflow_info.version         = fe_info(i).Version;
            frontend_info.stateflow_info.release         = fe_info(i).Release;
            frontend_info.stateflow_info.date            = fe_info(i).Date;
            
        elseif isempty(frontend_info.ds_targetlink_info.name) && ...
                strncmpi('dspace targetlink', fe_info(i).Name, length('dspace targetlink'))
            %  dSpace targetlink info
            frontend_info.ds_targetlink_info.name            = fe_info(i).Name;
            frontend_info.ds_targetlink_info.version         = fe_info(i).Version;
            frontend_info.ds_targetlink_info.release         = fe_info(i).Release;
            frontend_info.ds_targetlink_info.date            = fe_info(i).Date;
        elseif isempty(frontend_info.ds_datadictionary_info.name) && ...
                strncmpi('dspace data dictionary', fe_info(i).Name, length('dspace data dictionary'))
            %  dSpace data dictionary info
            frontend_info.ds_datadictionary_info.name            = fe_info(i).Name;
            frontend_info.ds_datadictionary_info.version         = fe_info(i).Version;
            frontend_info.ds_datadictionary_info.release         = fe_info(i).Release;
            frontend_info.ds_datadictionary_info.date            = fe_info(i).Date;
        end
    end
end

fe_info = frontend_info;

return
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
