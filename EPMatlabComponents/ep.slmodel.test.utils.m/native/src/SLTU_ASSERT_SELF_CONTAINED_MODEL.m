function SLTU_ASSERT_SELF_CONTAINED_MODEL(sModelName, bIsSLSIL)
% Check if the model has no libraries or model references

if (nargin < 2)
    bIsSLSIL = false;
end

try
    get_param(sModelName, 'handle');
    
catch oEx %#ok<NASGU>
    SLTU_FAIL('Model "%s" is either missing or not open.', sModelName);
    return;
end

try
    stLibInfo = i_libinfo(sModelName);
catch oEx
    MU_FAIL(oEx.message);
    return;
end

abMatchedLibs = ismember({stLibInfo(:).Library}, {'tllib', 'simulink', 'atgcv_lib', 'tl_needs_upgrade'});
MU_ASSERT_TRUE(all(abMatchedLibs),['Not resolved libraries found: ', char({stLibInfo(~abMatchedLibs).Library})]);

% check that no model refs exist
if ~bIsSLSIL
    [casRefMdls, casMdlBlks] = i_find_mdlrefs(sModelName, true);
    iRefAmount = numel(casRefMdls);
        for i = 1:iRefAmount
            bIsCopy = ~isempty(regexp(casRefMdls{i}, ['.*' sModelName], 'once'));
            bCopyExists = exist(get_param(casRefMdls{i}, 'filename'), 'file');
            MU_ASSERT_TRUE(bIsCopy, ['Unexpected model references found. Found models: ', casRefMdls{i}]);
            MU_ASSERT_TRUE(bCopyExists, ['Missing copy of referenced model file. Missing model: ', casRefMdls{i}]);
        end
        for i = 1:numel(casMdlBlks)
            try
                sReference = get_param(casMdlBlks{i}, 'ModelName');
            catch
                MU_ASSERT_TRUE(false, ['Unexpected error: Following model reference block does not contain a model name: ', casMdlBlks{i}, '.']);
            end
            bReferencesCopy = ~isempty(regexp(sReference, ['.*' sModelName], 'once'));
            MU_ASSERT_TRUE(bReferencesCopy, ['Unexpected model references found: Found in model reference blocks: ', casMdlBlks{i}, '. Referenced model: ', sReference]);
        end
else
    [casRefMdls, casMdlBlks] = i_find_mdlrefs(sModelName);
    MU_ASSERT_TRUE(numel(casRefMdls) >= 2, ['Unexpected model references found. Found models: ', casRefMdls{:}]);
    MU_ASSERT_TRUE(~isempty(casMdlBlks), 'Expected model reference not found');
end
end


%%
function varargout = i_find_mdlrefs(xContext, varargin)
if verLessThan('matlab', '9.13')
    [varargout{1:nargout}] = find_mdlrefs(xContext, varargin{:});
else
    stCurrentWarnState = warning('off', 'all');
    oOnCleanupResetWarnState = onCleanup(@() warning(stCurrentWarnState));

    [varargout{1:nargout}] = find_mdlrefs(xContext, varargin{:});    
end
end


%%
function varargout = i_libinfo(sModel)
if verLessThan('matlab', '9.13')
    [varargout{1:nargout}] = libinfo(sModel);
else
    [varargout{1:nargout}] = libinfo(sModel, 'MatchFilter', @Simulink.match.allVariants);
end
end