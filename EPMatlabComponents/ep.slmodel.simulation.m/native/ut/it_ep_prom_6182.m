function it_ep_prom_6182()
% Tests the ep_sim_* method
%
%  it_ep_prom_6182()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

%% clean up first


dos('xcopy /k /r /i /c /y /s "..\data\prom6182\*.*" "."');


%% Test Case
try
    xEnv = EPEnvironment(); 
    sTempDir = xEnv.getTempDirectory();
    sTestVector = fullfile(pwd,'testVector.xml' );
    val.time = [];
    val.signals.values = [];
    assignin('base','o_if50',val);
    ep_simenv_base2tv(sTempDir, sTestVector, false, [], []);
    
    xDocInit = mxx_xmltree('load', sTestVector );
    xStimVec = mxx_xmltree('get_root', xDocInit);
    
    
    % add outputs to stimuli vector (append the values)
    hOutputs = mxx_xmltree('get_nodes', xStimVec, 'Outputs/Object');
    
    %  for all outputs in the interface definition
    for iOutput=1:length(hOutputs)
        hOutput = hOutputs(iOutput);
        
        sMatFile = mxx_xmltree('get_attribute', hOutput, 'matFile');
        MU_ASSERT_TRUE(isempty(sMatFile));
    end
    
    mxx_xmltree('clear',xDocInit);
    
    evalin('base','sltu_clear_all;');
    
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end
return;

