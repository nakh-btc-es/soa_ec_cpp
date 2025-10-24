function bIsValid = atgcv_m01_module_check(varargin)
% Check if the module is valid, i.e. usable by EmbeddedTester.
%
% --------------- usual case -----------------------------------------------
% function bIsValid = atgcv_m01_module_check(stEnv, xModule)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)    error messenger environment
%     xModule           (handle)    DD handle/path of module
%
%   OUTPUT              DESCRIPTION
%     bIsValid          (bool)      TRUE if module is valid; otherwise FALSE
%
% --------------------------------------------------------------------------
%
% --------------- special case ---------------------------------------------
% function atgcv_m01_module_check('EXCLUDE_TLSIM')
%
%   INPUT               DESCRIPTION
%     sFlag             (struct)    'EXCLUDE_TLSIM'
%
%   OUTPUT              DESCRIPTION
%
%  setting this flag leads to invalidation of _all_ sim-frame files
%  --> this means also the AUTOSAR RTE-files will not be supported anymore
%
% --------------------------------------------------------------------------
%
%   REMARKS
%
%   <et_copyright>


%% internal
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 92173 $
%   Last modified: $Date: 2011-07-28 10:58:08 +0200 (Do, 28 Jul 2011) $
%   $Author: ahornste $

persistent bSimFrameValid;



%% handle init of persistent variables
if isempty(bSimFrameValid)
    bSimFrameValid = true;
end


%% check inputs
if (nargin < 2)
    sFlag = varargin{1};
    if strcmpi(sFlag, 'EXCLUDE_TLSIM')
        bSimFrameValid = false;
    end
    return;
else
    stEnv   = varargin{1};
    xModule = varargin{2};
end


%% main
bIsValid = false;
[bExist, hModule] = dsdd('Exist', xModule, 'objectKind', 'Module');
if ~bExist
    return;
end

hModuleInfo = atgcv_mxx_dsdd(stEnv, 'GetModuleInfo', hModule);
if ~isempty(hModuleInfo)
    ahFileInfo  = atgcv_mxx_dsdd(stEnv, 'Find', hModuleInfo, ...
        'objectKind', 'FileInfo', 'property', {'name', 'FileType'});
    if ~isempty(ahFileInfo)
        if bSimFrameValid
            bIsValid = true;
        else
            bIsValid = i_checkNotSimFrame(stEnv, ahFileInfo(1));
        end
    end
end
end




%% internal functions

% function bIsValid = i_checkModuleFile(stEnv, hModuleInfo, hFileInfo)
% bIsValid = true;
% bIsValid = false;
% 
% % check SimulationFrameFiles more thoroughly
% sFileType = atgcv_mxx_dsdd(stEnv, 'GetFileType', hFileInfo);
% if strcmpi(sFileType, 'SimulationFrameFile')
%     % SimulationFrameFile is valid if it starts with Rte_ 
%     % (TL-default for AUTOSAR)
%     sFileName = atgcv_mxx_dsdd(stEnv, 'GetFileName', hFileInfo);
%     if ~isempty(regexpi(sFileName, '^Rte_', 'once'))
%         bIsValid = true;
%     else
%         % one can rename RTE files; however they should still have a PoolRef then
%         % module is valid if it has a PooRef (TL3.1 and higher)
%         if dsdd('Exist', hModuleInfo, 'Property', {'Name', 'PoolRef'})
%             sPoolRef = atgcv_mxx_dsdd(stEnv, 'Get', hModuleInfo, 'PoolRef');
%             if ~isempty(sPoolRef)
%                 bIsValid = true;
%             end
%         end
%     end
% else
%     bIsValid = true;
% end
% end

function bIsValid = i_checkNotSimFrame(stEnv, hFileInfo)
sFileType = atgcv_mxx_dsdd(stEnv, 'GetFileType', hFileInfo);
bIsValid = ~strcmpi(sFileType, 'SimulationFrameFile');
end
