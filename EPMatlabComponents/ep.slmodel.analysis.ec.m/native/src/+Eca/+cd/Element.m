% Base class for every class in CodeDescritor context.
classdef Element < matlab.mixin.CustomDisplay
    properties (SetAccess = private, Hidden = true)
        oCD_   = [];
        oElem_ = [];
    end

    methods (Access = protected)
        function oObj = Element(oElem, oCD)
            i_assertValidCodeDescriptorElement(oElem);
            i_assertValidCodeDescriptor(oCD);
            oObj.oElem_ = oElem;
            oObj.oCD_ = oCD;
        end

        % default; to be overwritten later by concrete classes
        function displayScalarObject(oObj)
            disp(oObj.oElem_);
        end
    end

    methods (Hidden = true)
        function sClass = getClass(oObj, oElem)
            if (nargin < 2)
                sClass = i_getShortClass(oObj.oElem_);
            else
                sClass = i_getShortClass(oElem);
            end
        end
    end

    methods (Static = true, Access = protected)
        function caoObjects = constructFromSequence(hConstructor, oSequence, varargin)
            caoObjects = arrayfun(@(oObj) feval(hConstructor, oObj, varargin{:}), ...
                oSequence.toArray, 'UniformOutput', false);
        end

        function oObj = constructFromOptional(hConstructor, oElem, varargin)
            oObj = [];
            if isempty(oElem)
                return;
            end

            oObj = feval(hConstructor, oElem, varargin{:});
        end
    end
end



%%
function i_assertValidCodeDescriptorElement(oElement)
if isempty(oElement)
    error('EP:CD:INVALID_ELEMENT', 'Provided CodeDescritor element is empty.');
end
end


%%
function i_assertValidCodeDescriptor(oCD)
if isempty(oCD)
    error('EP:CD:INVALID_CODE_DESCRIPTOR', 'Provided CodeDescritor object is empty.');
end
end


%%
function sClass = i_getShortClass(oObj)
sFullClass = class(oObj);
sClass = regexprep(sFullClass, '.+[.]', ''); % remove the namespace from the class name
end
