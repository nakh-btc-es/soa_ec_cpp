function varargout = ep_sl_feature_toggle(sCmd, varargin)
% Persistent key-value store for toggling internal features.
%


%% init
persistent p_stFeatures;

if isempty(p_stFeatures)
    p_stFeatures = struct( ...
        'ALLOW_64_BIT', i_evalPreference64Bit());
end

%% main
switch lower(sCmd)
    case 'get'
        sFeature = varargin{1};
        
        if isfield(p_stFeatures, sFeature)
            varargout{1} = p_stFeatures.(sFeature);
        else
            error('EP:INTERNAL:ERROR', 'Requesting unknown feature "%s".', sFeature);
        end
        
    case 'set'
        sFeature = varargin{1};
        bNewValue = varargin{2};
        
        if isfield(p_stFeatures, sFeature)
            if ~islogical(bNewValue)
                error('EP:INTERNAL:ERROR', 'Trying to toggle feature "%s" with non-bool value.', sFeature);
            end
            p_stFeatures.(sFeature) = bNewValue;
        else
            error('EP:INTERNAL:ERROR', 'Trying to toggle unknown feature "%s".', sFeature);
        end
        
    case 'all'
        varargout{1} = p_stFeatures;
        
    otherwise
        error('ATGCV:INTERNAL:ERROR', 'Unknown command "%s".', sCmd);
end
end


%%
function bIsAllowed = i_evalPreference64Bit()
bIsAllowed = ep_sl_preference_64bit_support();
end
