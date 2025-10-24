function [nLength, nIndex] = ep_simenv_statelogger_eval( oLogObject, bEvalTrace, dSampleTime )
% Evaluates the statelogger logging results
%
% function  [nLength, nIndex] = ep_simenv_statelogger_eval( oLogObject, bEvalTrace, dSampleTime )
%
%   REMARKS
%
%
%  REFERENCE(S):
%     Design Document:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%%

anTime = oLogObject.Time;
anData = oLogObject.Data;
nLength = length(anTime);

if(	~isempty(anTime) )
	nIndex = anTime(end);
else
	nIndex = 0;
end

if( ~bEvalTrace)
    return; % NOTHING TO DO HERE
end

% NOTE: the algorithm is only working on special
% subsystems, which have a TriggerPort,
% because after each step, whe memory value of the 
% statelogger is resetted.
dLastValue = 0;
for i = 1:nLength
    dTime = anTime(i);
    dValue = anData(i);
    
    if( i > 1 )
        dOffset = dValue - dLastValue;
        dTimeOffset = dTime - anTime(i-1);
        if( (dOffset ~= 1) || (dTimeOffset == 0))
            % check that between the last value
            % and the current value is only one step
            
            % mismatch : this means a iteration of
            % execution within one sample time step
            % multiple execution steps within e.g.
            % function-call subsystem
            nIndex = round( dTime/dSampleTime );
            nLength = -1;
            break;
        end
    else
        if( dValue > 1 )
            % mismatch : this means a iteration of
            % execution within one sample time step
            % multiple execution steps within e.g.
            % function-call subsystem
            nIndex = round( dTime/dSampleTime );
            nLength = -1;
            break;
        end
    end
    dLastValue = dValue;
end




%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************
                    