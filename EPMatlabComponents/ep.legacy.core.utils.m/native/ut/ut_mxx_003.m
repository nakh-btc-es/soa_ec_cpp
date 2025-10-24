function ut_mxx_003
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
    atgcv_progress_set(oProgress,'msg','moin');
    
    atgcv_progress_stop( oProgress, 'Stop progress.');
    atgcv_progress_set(oProgress,'msg','moin');
    MU_ASSERT_TRUE(atgcv_progress_stopped(oProgress)); 
    
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
