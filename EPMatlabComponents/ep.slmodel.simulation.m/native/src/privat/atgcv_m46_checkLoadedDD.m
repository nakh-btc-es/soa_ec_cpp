function atgcv_m46_checkLoadedDD(stEnv, sOrigPrj)
% Check function if right DD is loaded
%
% function atgcv_m46_checkLoadedDD(stEnv, sOrigPrj)
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sOrigPrj             (string)    Original project
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document:
%        Section : M46
%        Download:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

sLoadedDD = i_getCurrentDd();
if isunix
    if(~strcmp(sLoadedDD, sOrigPrj))
        stError = osc_messenger_add(stEnv, ...
            'ATGCV:MDEBUG_ENV:INVALID_ACTIVE_DD', ...
            'ModelDD', sOrigPrj, ...
            'ActiveDD', sLoadedDD);
        atgcv_throw(stError);
    end
else
    if(~strcmpi(sLoadedDD, sOrigPrj))
        stError = osc_messenger_add(stEnv, ...
            'ATGCV:MDEBUG_ENV:INVALID_ACTIVE_DD', ...
            'ModelDD', sOrigPrj, ...
            'ActiveDD', sLoadedDD);
        atgcv_throw(stError);
    end
end




%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************

%% i_getCurrentDd
function sCurrDd = i_getCurrentDd()
if (atgcv_version_compare('TL3.3') < 0)
    sCurrDd = dsdd('GetEnv', 'ProjectFile');
else
    sCurrDd = dsdd('GetDDAttribute', 0, 'fileName');
end


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************