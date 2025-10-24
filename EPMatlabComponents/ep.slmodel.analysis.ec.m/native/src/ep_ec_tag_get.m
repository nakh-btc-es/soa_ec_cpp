function xTag = ep_ec_tag_get(sUseCase)
% This function returns an internal unique tag that has to be used in the given use case
%
%  function xTag = ep_ec_tag_get(sUseCase)
%
%  INPUT              DESCRIPTION
%    - sUseCase           (string)             The use case for which the tag is needed. Currently supported:
%                                                  'All Wrappers' 
%                                                  'Autosar Wrapper Model' 
%                                                  'Autosar Wrapper Model Complete' 
%                                                  'Autosar Main ModelRef'
%  OUTPUT            DESCRIPTION
%
%    - sTag               (string)             The internal tag string


%%
switch lower(sUseCase)
    case 'all wrappers'
        xTag = {'EP_AUTOSAR_SWC_WRAPPER_COMPLETE', 'EP_AUTOSAR_SWC_WRAPPER', Eca.aa.wrapper.Tag.Toplevel};

    case 'autosar wrapper model complete'
        xTag = 'EP_AUTOSAR_SWC_WRAPPER_COMPLETE';
        
    case 'adaptive autosar wrapper model'
        xTag = Eca.aa.wrapper.Tag.Toplevel;
        
    case 'autosar wrapper model'
        xTag = 'EP_AUTOSAR_SWC_WRAPPER';
        
    case 'autosar main modelref'
        xTag = 'BTC AUTOSAR Main Model Reference Block';
        
    otherwise
        error('EP:INTERNAL:TAG:UNKNOWN_USECASE', 'Unknown usecase "%s".', sUseCase);
end
end