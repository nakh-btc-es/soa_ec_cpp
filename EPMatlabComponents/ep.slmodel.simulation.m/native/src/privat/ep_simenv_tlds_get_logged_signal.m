function [signallogdata, sErrorMsg] = ep_simenv_tlds_get_logged_signal(simlabel, sBlock, sSignalName)
% Return the values that have been logged by TL during simulation for specified block and signal name.
%
% function signallogdata = ep_simenv_tlds_get_logged_signal(simlabel, sBlock, sSignalName)
%
%   INPUT               DESCRIPTION
%     simlabel           (handle)    the TLDS simulation label (if empty, the latest simulation result is used)
%     sBlock             (string)    the full model block path (if empty, all logged blocks are considered)
%     sSignalName        (string)    the signal name           (if empty, all signal names are considered)
%
%   OUTPUT              DESCRIPTION
%     signallogdata      (struct)    the info structure as returned by "tl_access_logdata"
%     sErrorMsg          (string)    error message in case of problems
%


%%
casArgs = {};
if ((nargin > 0) && ~isempty(simlabel))
    casArgs(end+1:end+2) = {'simlabel', simlabel};
end
if ((nargin > 1) && ~isempty(sBlock))
    casArgs(end+1:end+2) = {'block', sBlock};
end

% Note: special treatment for signal name because this attribute is sometimes ambiguously defined
if ((nargin > 2) && ~isempty(sSignalName))
    signallogdata = i_getLogdataWithSignalName(casArgs, sSignalName);
else
    [signallogdata, sErrorMsg] = i_accessLogdata(casArgs{:});
end
end



%%
% Note: special treatment for signal name because this attribute is sometimes ambiguously 
%       defined for the root signal component
function [signallogdata, sErrorMsg] = i_getLogdataWithSignalName(casArgs, sSignalName)
[signallogdata, sErrorMsg] = i_accessLogdata(casArgs{:}, 'signalname', sSignalName);
if isempty(signallogdata)
    % if the result is empty, it might be that the signal name is ambigous --> try to filter out via normalization
    [signallogdata, sErrorMsg] = i_accessLogdata(casArgs{:});
    
    % check if we have a unique signal information; if not, try to filter out the right signal
    % Note: this is sometimes possible because the root signal name might be
    %  a) empty <--> signal name is starting with a dot --> example: ".x.y.z"
    %  b) not matching the TL root signal name
    if (numel(signallogdata) > 1)
        sNormSigName = i_normalizeSigName(sSignalName);
        for i = 1:numel(signallogdata)
            signallogdataTry = signallogdata(i);
            sTryName = i_normalizeSigName(signallogdataTry.signalname);
            if strcmp(sTryName, sNormSigName)
                signallogdata = signallogdataTry;
                return;
            end
        end
        % if the signal name was provided but we did not find it,
        % we need to return an empty result to indicate the failure
        signallogdata = [];
    end
end
end


%%
function sSigName = i_normalizeSigName(sSigName)
if ~isempty(sSigName)
    sSigName = regexprep(sSigName, '^[^.]+', '');
end
end


%%
function [signallogdata, sErrorMsg] = i_accessLogdata(varargin)
signallogdata = [];
sErrorMsg = '';
try
    [signallogdata, stMsgStruct] = tl_access_logdata('GetLoggedSignal', varargin{:});
    if ~isempty(stMsgStruct)
        sErrorMsg = stMsgStruct.msg;
    end
catch oEx
    sErrorMsg = oEx.message;
end
end
