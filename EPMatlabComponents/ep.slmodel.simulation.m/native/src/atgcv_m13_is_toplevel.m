function [bIsToplevel] = atgcv_m13_is_toplevel(xSubsystem)
bIsToplevel = false;
try
    sSubsysPath = atgcv_m13_path_get( xSubsystem );
    if any(strcmp(get_param(sSubsysPath,'Type'),{'block'}))
        sTag = get_param(sSubsysPath, 'Tag');
        bIsToplevel = strcmpi(sTag, 'MIL Subsystem');
    end
catch
    bIsToplevel = false;
end
end
%**************************************************************************
% END fucntion                                                          ***
%**************************************************************************end
