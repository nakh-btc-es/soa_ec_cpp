function ep_simenv_print_script_header(fid, sInitScriptName, sDescription)
sDate = date();
cl = clock();
sYear = datestr(now,'yyyy');
sTime = sprintf('%02d:%02d:%02d', cl(4), cl(5), fix(cl(6)));

casLines = { ...
    i_line('%%'), ...
    i_line('%% @file  %s ', sInitScriptName), ...
    i_line('%'), ...
    i_line('%% %s', sDescription), ...
    i_line('%% @date  %s %s', sDate, sTime), ...
    i_line('%'), ...
    i_line('%% (c) 2007-%s by BTC Embedded Systems AG, Germany', sYear), ...
    i_line('%%')};
i_fprintfLines(fid, casLines);
end



%%
% Note: just a simple wrapper to make creation of casLines more readable
function sLine = i_line(varargin)
if (nargin < 2)
    sLine = varargin{1};
else
    sLine = sprintf(varargin{:});
end
end


%% just print the lines
function i_fprintfLines(fid, casLines, sStartOfLine)
if (nargin < 3)
    for i = 1:length(casLines)
        fprintf(fid, '%s\n', casLines{i});
    end
else
    for i = 1:length(casLines)
        fprintf(fid, '%s%s\n', sStartOfLine, casLines{i});
    end
end
end
