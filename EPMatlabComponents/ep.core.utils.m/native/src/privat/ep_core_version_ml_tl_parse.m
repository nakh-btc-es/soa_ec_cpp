function [bParsed, iVer1, iVer2, iVer3, iPatchLevel] = ep_core_version_ml_tl_parse(sVersion)
% Parse TargetLink and Matlab version string.
%
% function [bParsed, iVer1, iVer2, iVer3, iPatchLevel] = ep_core_version_ml_tl_parse(sVersion)
%
% INPUT         DESCRIPTION
%  - sVersion     (string)  TargetLink Version string, e.g.  '3.1', '2.3.1p7'
%                           Matlab version string, e.g. 7.9.1
% OUTPUT
%  - bParsed      (bool)    Parse success.
%  - iVer1        (int)     Major version number, e.g. 2 for '2.3.1p7', 0 on failure
%  - iVer2        (int)     Minor version number, e.g. 3 for '2.3.1p7', 0 on failure
%  - iVer3        (int)     Less minor version number, e.g. 1 for '2.3.1p7', 0 on failure or if not given like in '3.1'
%  - iPatchLevel  (int)     Patch level, e.g. 7 for '2.3.1p7', 0 on failure or if not given like in '3.1'
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2016

bParsed     = 1;
iVer1       = 0;
iVer2       = 0;
iVer3       = 0;
iPatchLevel = 0;

iState = 0;
for k=1:length(sVersion)
    
    cChar = sVersion(k);
    iChar = double(cChar);
    
    switch iState
        case 0  %  start automaton, parse first number of iVer1
            if iChar >= 48 && iChar <= 57 % number 0..9
                iVer1  = iChar - 48;
                iState = 1;
            else
                iState = -1;
            end
        case 1  %  parse until end of iVer1
            if iChar >= 48 && iChar <= 57 % number 0..9
                iVer1  = iVer1 * 10 + (iChar - 48);
            elseif cChar == '.' % start parsing iVer2
                iState = 2;
            else
                iState = -1;
            end
        case 2  %  parse first number of iVer2
            if iChar >= 48 && iChar <= 57 % number 0..9
                iVer2 = iChar - 48;
                iState = 3;
            else
                iState = -1;
            end
        case 3  %  parse until end of iVer2
            if iChar >= 48 && iChar <= 57 % number 0..9
                iVer2 = iVer2 * 10 + (iChar - 48);
            elseif cChar == '.' % start parsing iVer3
                iState = 4;
            elseif cChar == 'p' % start parsing patch level
                iState = 6;
            else
                iState = -1;
            end
        case 4
            if iChar >= 48 && iChar <= 57 % number 0..9
                iVer3  = iChar - 48;
                iState = 5;
            else
                iState = -1;
            end
        case 5
            if iChar >= 48 && iChar <= 57 % number 0..9
                iVer3 = iVer3 * 10 + (iChar - 48);
            elseif cChar == 'p' % start parsing patch level
                iState = 6;
            else
                iState = -1;
            end
        case 6
            if iChar >= 48 && iChar <= 57 % number 0..9
                iPatchLevel = iPatchLevel * 10 + (iChar - 48);
            else
                iState = -1;
            end
        case -1
            break
    end  
end

%  normalize return values in case of failures
if any(iState == [-1:2, 4])
    bParsed     = 0;
    iVer1       = 0;
    iVer2       = 0;
    iVer3       = 0;
    iPatchLevel = 0;
end
end