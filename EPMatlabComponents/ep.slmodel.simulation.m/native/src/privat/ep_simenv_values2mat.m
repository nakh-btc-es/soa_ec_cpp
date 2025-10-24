function sMatFile = ep_simenv_values2mat(sTempDir, sIfId, adTimes, adValues)
% Store the adTimes and adValues to the given MAT file
%
% function sMatFile = ep_simenv_values2mat(sTempDir, sIfId, adTimes, adValues)
%
%   INPUT               DESCRIPTION
%
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
% $$$COPYRIGHT$$$-2015

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%%
if isempty(adTimes)
    sMatFile = '';
else
    sMatName = sprintf('%s.mat', sIfId);
    sMatFile = fullfile(sTempDir, sMatName);
    
    % avoid problems with object data types like "fi"
    % (for example: we have no sprintf() function here)
    % --> try to cast these values before further evalutation    
    if isobject(adValues)
        adValues = cast(adValues, 'double');
    end
        
    xValue(1, :) = adTimes;
    xValue(2, :) = adValues;
    
    assignin('base', sIfId, xValue);
    evalin('base', sprintf('save(''%s'', ''%s'', ''-v6'')', sMatFile, sIfId));
    evalin('base', sprintf('clear ''%s'';',sIfId));
end
end

