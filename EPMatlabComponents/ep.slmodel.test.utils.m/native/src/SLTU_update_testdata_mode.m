function varargout = SLTU_update_testdata_mode(varargin)
% Switching on/off "Update Testdata" mode OR reading out its current value.
%
% function varargout = SLTU_update_testdata_mode(varargin)
%
%   PARAMETER(S)    DESCRIPTION
%
%  ----------------------- (1) read ---------------------------
%      bIsActive = SLTU_update_testdata_mode()    --> returns flag if the "Update Testdata" mode is active
%
%  ----------------------- (2) write ---------------------------
%      SLTU_update_testdata_mode(bIsActive)       --> sets the flag if the "Update Testdata" mode is active
%


%% read
if (nargin < 1)
    varargout{1} = strcmp(getenv('SLTU_UPDATE_TESTDATA_MODE'), '1');
    return;
end

%% write
if ((nargin > 0) && (nargout < 1))
    bIsActive = varargin{1};
    if bIsActive
        setenv('SLTU_UPDATE_TESTDATA_MODE', '1');
    else
        setenv('SLTU_UPDATE_TESTDATA_MODE', '');
    end
    return;
end

%% error
error('SLTU:UPDATE_TESTDATA_MODE:WRONG_USAGE', 'Wrong usage. Plese read the docu.');
end
