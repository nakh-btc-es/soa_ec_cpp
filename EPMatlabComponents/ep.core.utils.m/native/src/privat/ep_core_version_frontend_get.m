function fe_info = ep_core_version_frontend_get
% Retrieve frontend info (Matlab, Simulink, Stateflow, and so on ... ).
%
% function fe_info = ep_core_version_frontend_get
%
% INPUT           DESCRIPTION
%  -               -
%
% OUTPUT
%  - fe_info       (struct) Structure containing all front information.
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2016

persistent frontend_info;

if isempty(frontend_info) || isempty(frontend_info.ds_targetlink_info.name)
    
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
        
        %  get the tool name
        sName = fe_info(i).Name;
        
        if isempty(frontend_info.simulink_info.name) && i_is_simulink(sName)
            %  simulink info
            frontend_info.simulink_info.name            = fe_info(i).Name;
            frontend_info.simulink_info.version         = fe_info(i).Version;
            frontend_info.simulink_info.release         = fe_info(i).Release;
            frontend_info.simulink_info.date            = fe_info(i).Date;
            
        elseif isempty(frontend_info.stateflow_info.name) && i_is_stateflow(sName)
            %  stateflow info
            frontend_info.stateflow_info.name            = fe_info(i).Name;
            frontend_info.stateflow_info.version         = fe_info(i).Version;
            frontend_info.stateflow_info.release         = fe_info(i).Release;
            frontend_info.stateflow_info.date            = fe_info(i).Date;
            
        elseif isempty(frontend_info.ds_targetlink_info.name) && i_is_tl_codegen(sName)
            %  dSpace targetlink info
            frontend_info.ds_targetlink_info.name            = fe_info(i).Name;
            frontend_info.ds_targetlink_info.version         = fe_info(i).Version;
            frontend_info.ds_targetlink_info.release         = fe_info(i).Release;
            frontend_info.ds_targetlink_info.date            = fe_info(i).Date;
            
        elseif isempty(frontend_info.ds_datadictionary_info.name) && i_is_tl_dd(sName)
            %  dSpace data dictionary info
            frontend_info.ds_datadictionary_info.name            = fe_info(i).Name;
            frontend_info.ds_datadictionary_info.version         = fe_info(i).Version;
            frontend_info.ds_datadictionary_info.release         = fe_info(i).Release;
            frontend_info.ds_datadictionary_info.date            = fe_info(i).Date;
        end
    end
end

fe_info = frontend_info;

end
%***********************************************************************************************************************
% INTERNAL FUNCTION DEFINITION(S)
%***********************************************************************************************************************

%***********************************************************************************************************************
% Check for the Simulink version entry.
%
%   PARAMETER(S)    DESCRIPTION
%    - sName         (string)    String to be checked.
%
%   OUTPUT
%    - bMatch        (boolean)   = 1 (match) = 0 (no match)    
%***********************************************************************************************************************
function bMatch = i_is_simulink(sName)

sCompare = 'simulink';
bMatch   = strncmpi(sCompare, sName, length(sCompare));

end

%***********************************************************************************************************************
% Check for the Stateflow version entry.
%
%   PARAMETER(S)    DESCRIPTION
%    - sName         (string)    String to be checked.
%
%   OUTPUT
%    - bMatch        (boolean)   = 1 (match) = 0 (no match)    
%***********************************************************************************************************************
function bMatch = i_is_stateflow(sName)

sCompare = 'stateflow';
bMatch   = strncmpi(sCompare, sName, length(sCompare));

end

%***********************************************************************************************************************
% Check for the TargetLink Code Generator version entry.
%
%   PARAMETER(S)    DESCRIPTION
%    - sName         (string)    String to be checked.
%
%   OUTPUT
%    - bMatch        (boolean)   = 1 (match) = 0 (no match)    
%***********************************************************************************************************************
function bMatch = i_is_tl_codegen(sName)

sCompare = 'dspace targetlink production code generator';

bMatch = strncmpi(sCompare, sName, length(sCompare));

end

%***********************************************************************************************************************
% Check for the TargetLink Data Dictionary version entry.
%
%   PARAMETER(S)    DESCRIPTION
%    - sName         (string)    String to be checked.
%
%   OUTPUT
%    - bMatch        (boolean)   = 1 (match) = 0 (no match)    
%***********************************************************************************************************************
function bMatch = i_is_tl_dd(sName)

%  starting with TL 3.4 the name changed into this:
sCompare = 'dspace targetLink data dictionary';
bMatch = strncmpi(sCompare, sName, length(sCompare));

%  for older versions.
%  note: we cannot call ev_version_is_greater_or_equal('TL3.4') here
%  reason: endless recursion
if ~bMatch
    sCompare = 'dspace data dictionary';
    bMatch = strncmpi(sCompare, sName, length(sCompare));
end
end