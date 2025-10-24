function ep_simenv_base2tv(sTempDir, sTVFile, bTLDS, anExecutionTime, anStackSize, sSimStatus)
% Transform and add the MATLAB workspace variables to a given vector file
%
% function ep_simenv_base2tv(sTempDir, sTVFile, bTLDS, anExecutionTime, anStackSize, sSimStatus)
%
%   INPUT               DESCRIPTION
%   sTempDir             (string)    Temp directory where to store MAT
%                                    files.
%   sTVFile              (string)    Full path to the new test vector file
%                                    (see TestVector.xsd)
%   bTLDS                (boolean)   TLDS should be analysed
%   anExecutionTime   (array double) Execution time of all steps
%                                    in micro seconds.
%   anStackSize       (array double) Stack size of all steps.
%   sSimStatus           (string)    optional: status of the simulation run (default == 'success')
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
if (nargin < 6)
    sSimStatus = 'success';
end


try
    xDocInit = mxx_xmltree('load', sTVFile);
    xStimVec = mxx_xmltree('get_root', xDocInit);    
    
    % add outputs to stimuli vector (append the values)
    hOutputs = mxx_xmltree('get_nodes', xStimVec, 'Outputs/Object');
    
    %  for all outputs in the interface definition
    for iOutput = 1:length(hOutputs)
        hOutput = hOutputs(iOutput);
        
        sIfId = mxx_xmltree('get_attribute', hOutput, 'ifid');
        
        %  TODO: dead code?
        sOutput = ['o_', sIfId];
        sMatName = [sIfId, '.mat'];
        sMatFile = fullfile(sTempDir, sMatName);
        if( evalin('base', ['exist( ''', sOutput, ''',''var'')'] ) )
            wsValue = evalin('base', sOutput);
            adTimes = wsValue.time;
            adValues = wsValue.signals.values;
            ep_simenv_values2mat(sTempDir, sIfId, adTimes, adValues);
        end
        if exist(sMatFile, 'file')
            mxx_xmltree('set_attribute', hOutput, 'matFile', sMatFile);
        end
        
        % With Matlab 2019a and later the logged signal values are only 
        % reported, when their value has changed (and not in each step any 
        % more). This needs to be interpreted differently.
        % The option "zoh" (zero order hold) switches the interpretation
        % into this mode.
        if ep_core_version_compare('ml9.6') >= 0
            mxx_xmltree('set_attribute', hOutput, 'interpolation', 'zoh');
        end
    end
    
   
    
    %  add a simulation status
    xSimStatus = mxx_xmltree('add_node', xStimVec, 'SimStatus');    
    
    mxx_xmltree('set_attribute', xSimStatus, 'status', sSimStatus);      
   
    if( bTLDS )
        if( ~isempty(anExecutionTime) )
            hExecutionTime = mxx_xmltree('add_node', xStimVec, 'ExecutionTime');
            mxx_xmltree('set_attribute', hExecutionTime,'value', num2str(anExecutionTime));
        end
        if( ~isempty(anStackSize) )
            hStackSize = mxx_xmltree('add_node', xStimVec, 'StackSize');
            mxx_xmltree('set_attribute', hStackSize, 'value', num2str(anStackSize));
        end
    end
    
    mxx_xmltree('save', xDocInit, sTVFile);
    
    mxx_xmltree('clear', xDocInit);
    
catch exception
    try mxx_xmltree('clear', xDocInit); catch end
    rethrow(exception);
end
end
