classdef ModelKind
    properties (Access = private)
        bIsClassicAUTOSAR  = false;        
        bIsAdaptiveAUTOSAR = false;        
    end

    methods (Static = true)
        function oObj = get(sModelName)
            oObj = Eca.ModelKind();

            sKind = i_getModelKind(sModelName);
            switch sKind
                case 'ClassicAUTOSAR'
                    oObj.bIsClassicAUTOSAR = true;

                case 'AdaptiveAUTOSAR'
                    oObj.bIsAdaptiveAUTOSAR = true;

                otherwise
                    % regular model; nothing to do
            end
        end
    end

    methods
        function bIsAR = isAUTOSAR(oObj)
            bIsAR = oObj.bIsAdaptiveAUTOSAR || oObj.bIsClassicAUTOSAR;
        end

        function bIsAR = isClassicAUTOSAR(oObj)
            bIsAR = oObj.bIsClassicAUTOSAR;
        end

        function bIsAR = isAdaptiveAUTOSAR(oObj)
            bIsAR = oObj.bIsAdaptiveAUTOSAR;
        end
    end
end


%%
function sKind = i_getModelKind(sModelName)
try
    get_param(sModelName, 'AutosarSchemaVersion');
    
    sTargetLang = get_param(sModelName, 'TargetLang');
    if strcmpi(sTargetLang, 'C++')
        sKind = 'AdaptiveAUTOSAR';
    else
        sKind = 'ClassicAUTOSAR';
    end
catch
    sKind = 'NonAUTOSAR';
end
end
