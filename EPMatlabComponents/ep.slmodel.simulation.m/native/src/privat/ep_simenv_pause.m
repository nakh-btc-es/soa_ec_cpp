function ep_simenv_pause()
% Evaluates of a pause of simulation should be done.
%
% function ep_simenv_pause()
%
%   INPUT               DESCRIPTION
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



%%  main internal functionality

dTime = get_param(gcs,'SimulationTime');
bExist = evalin('base', sprintf('exist(''%s'')',ep_simenv_pause_name));
if( bExist )
    dPauseTime = evalin('base', ep_simenv_pause_name);
    if( dTime >= dPauseTime )
        set_param(gcs,'SimulationCommand','pause');
        disp(['### Pause Simulation intended time : ', ...
            num2str(dPauseTime), ' real time : ', num2str(dTime)]);
    end
end

end

