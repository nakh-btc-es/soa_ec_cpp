function ut_mxx_005
% Suite: 
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Remmer Wilts
% $$$COPYRIGHT$$$
%%

try    
    stProgress = [];
    oProgress = atgcv_progress_create(@i_progress_set, stProgress);
    nProcesses = 3;
    caoProgress = atgcv_progress_children_create(oProgress, ...
            ones(nProcesses,1), ones(nProcesses,1) );
    atgcv_progress_set(caoProgress{1},'msg','moin','current',10,'total',20);
    atgcv_progress_set(caoProgress{2},'msg','moin','current',10,'total',20);
    atgcv_progress_set(caoProgress{3},'msg','moin','current',10,'total',20);
    atgcv_progress_stop(caoProgress{3}, 'Stop progress.');
    
    MU_ASSERT_TRUE(atgcv_progress_stopped(oProgress));   
    MU_ASSERT_TRUE(atgcv_progress_stopped(caoProgress{1}));
    MU_ASSERT_TRUE(atgcv_progress_stopped(caoProgress{2}));
    MU_ASSERT_TRUE(atgcv_progress_stopped(caoProgress{3}));
    
    atgcv_progress_delete(oProgress);
catch
    z = lasterror;
    MU_FAIL(z.message)
end

function i_progress_set( stProgress, nCurrent, nTotal, sMsg )
disp( num2str( nCurrent ) );
disp( sMsg );
% **************************************************************************
% END OF FILE                                                            ***
% **************************************************************************
