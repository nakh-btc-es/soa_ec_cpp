function bIsValid = ep_ec_aa_version_check()
%%
bIsValid = true;

% if EP_TOGGLE_AA_SUPPORT is not set, AA is not supported
% if ~strcmp(getenv('EP_TOGGLE_AA_SUPPORT'), 'true')
%     bIsValid = false;
%     return;
% end

% Matlab Version + Update config which is officially supported
sVer24b = 'R2024b Update5';

bActivateCheck = ~strcmp(getenv('EP_DEACTIVATE_AA_VERSION_CHECK'), 'true');
if bActivateCheck
    mRelease = matlabRelease();    
    sVer = [char(mRelease.Release), ' Update', num2str(mRelease.Update)];

    if ~strcmp(sVer, sVer24b)
        error('EP:EC:ANALYSIS_FAILED', ...
            ['EmbeddedPlatform only supports EC AdaptiveAUTOSAR models in Matlab version ', sVer24b, ' ...  ', newline, ...
            'Hint: Use command " setenv(''EP_DEACTIVATE_AA_VERSION_CHECK'', ''true'') " ', ...
            'to enable EC AA for untested and not officially supported versions.']);
    end
end
end