function oProgress = atgcv_progress_create(callback, xObject)
% Creates a progress object.
%
% function oProgress = atgcv_progress_create(callback, xObject)
%
%   INPUT               DESCRIPTION
%     callback            (function) callback function for reporting
%                                    progress.
%
%         The callback function must have the signature:
%
%            function callback(xObject, nCurrent, nTotal, sMsg)
%
%     xObject             (abstract) Arbitrary data, passed to the callback
%                                    function
%
%   OUTPUT              DESCRIPTION
%     oProgress           (object)   The progress object.
%
%   <et_copyright>

oProgress = ep.core.ipc.matlab.server.progress.impl.ProgressImpl();



%**************************************************************************
% END OF FILE
%**************************************************************************