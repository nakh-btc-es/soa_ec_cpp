function cahSources = atgcv_m46_tlport_handling(sModel, hPort)
% Special handling for ports, this function looks for the
% source of a port (normaly TL_OutPort) and check whether
% the source has set the TL output class.
% For more information see BTS/12112
% 
% function atgcv_m46_tlport_handling(sModel, hPort)
%
%   INPUT               DESCRIPTION
%       sModel           (string)     Model Name
%       hPort            (handle)     TargetLink Port
%       
%   OUTPUT              DESCRIPTION
%       cahSources      (cell array)  Cell array of sources      
%   REMARKS
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M46
%        Download:
%        
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

cahSources = cell(0);

if (atgcv_version_p_compare('TL3.4') >= 0)
    hFindsrcFunc = @i_findsource_block_tl34;
else
    hFindsrcFunc = @i_findsource_block_tl30;
end

try
    anSigMax = get_param(hPort, 'CompiledPortwidths');    
    for nIndex = 1:length(anSigMax)
        cahTmpSources = feval(hFindsrcFunc, hPort, '1', nIndex);
        if ~isempty(cahTmpSources)
            cahSources = [cahSources, cahTmpSources]; %#ok<AGROW>
        end
    end
catch oEx
    % Exception are ignored (but printed if in DEBUG mode)
	if atgcv_debug_status
		warning(oEx.identifier, oEx.message);
	end
end
end



%%
% tl_find_real_source_block is obsolete with TL3.4
function cahSource = i_findsource_block_tl34(hPort, sType, nIndex)
cahSource = {tl_backtrace_signal(hPort, sType, nIndex)};
end


%%
function cahSource = i_findsource_block_tl30( hPort, sType, nIndex )
cahSource = {tl_find_real_source_block(hPort, sType, nIndex)};
end


