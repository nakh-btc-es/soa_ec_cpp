classdef ScopeContext
    % Class representing the context of a scope.
    properties
        sPath_ = '';
        sVirtualPath_ = '';        
        aoExtContexts_ = [];
        
        % derived attributes
        sRootPathMatchPattern_ = '';        
    end
    
    methods
        %%
        function oObj = ScopeContext(sPath, sVirtualPath, aoExtContexts)
            oObj.sPath_        = sPath;
            oObj.sVirtualPath_ = sVirtualPath;
            if (nargin > 2)
                oObj.aoExtContexts_ = aoExtContexts;
            end
            oObj.sRootPathMatchPattern_ = i_getRootPathMatchPattern(oObj.sVirtualPath_);
        end
        
        %%
        % function returning the real model path of the context
        function sPath = getPath(oSig)
            sPath = oSig.sPath_;
        end
        
        %%
        % function returning the real model path of the context and the ones of the extended contexts
        function casPaths = getAllPaths(oSig)
            casPaths = {oSig.sPath_};
            for i = 1:numel(oSig.aoExtContexts_)
                casPaths = [casPaths, oSig.aoExtContexts_(i).getAllPaths()]; %#ok<AGROW>
            end
        end
        
        %%
        % is the provided path a real sub-part of the scope context or its extended contexts
        function bContains = contains(oObj, sPath)
            bContains = ~isempty(regexp(sPath, oObj.sRootPathMatchPattern_, 'once'));
            for i = 1:numel(oObj.aoExtContexts_)
                bContains = bContains || oObj.aoExtContexts_(i).contains(sPath);
            end
        end
        
        %%
        % is the provided path the scope context itself or a sub-part of the scope context or its extended contexts
        function bContains = containsOrSame(oObj, sPath)
            bContains = strcmp(oObj.sVirtualPath_, sPath) || oObj.contains(sPath);
            for i = 1:numel(oObj.aoExtContexts_)
                bContains = bContains || oObj.aoExtContexts_(i).containsOrSame(sPath);
            end
        end        
    end
end


%%
function sRootPathMatchPattern = i_getRootPathMatchPattern(sRootPath)
sRootPathMatchPattern = ['^', regexptranslate('escape', sRootPath), '/'];
end
