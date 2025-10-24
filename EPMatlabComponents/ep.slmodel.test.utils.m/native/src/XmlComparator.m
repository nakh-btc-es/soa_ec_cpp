classdef XmlComparator < handle
    % Helper class to compare to xml files in matlab
    % 
    %   An object of the class always describes a node of the XML file. This can be created using the method
    %   "createNodeInfo". It has the information about the node kind (sObjKind), the attributes (stAttributes) and the
    %   child nodes. The child nodes are described via a map of objects of this class.
    %   
    %   The class method compareMapsRecursive compares two maps of class objects.
    
    properties
        sObjKind
        stAttributes
        mChildren
    end
    
    methods (Access = private)
        function oObj = XmlComparator(sObjKind, stAttributes, mChildren)
            oObj.sObjKind = sObjKind;
            oObj.stAttributes = stAttributes;
            oObj.mChildren = mChildren;
        end
    end
    
    methods(Static)
        function oObj = createNodeInfo(sObjKind, stAttributes, mChildren)
            if (nargin < 3)
                mChildren = [];
            end
            if (nargin < 2)
                stAttributes = [];
            end
            oObj = XmlComparator(sObjKind, stAttributes, mChildren);
        end
        
        function bIsEqual = compareMapsRecursive(mExpMap, mFoundMap, hObjKindMessage)
            if (nargin < 3)
                hObjKindMessage = @i_getDefaultObjKindMessage;
            end
            bIsEqual = i_compareMapsRecusive(mExpMap, mFoundMap, hObjKindMessage);
        end
    end
end


%%
function bIsEqual = i_compareMapsRecusive(mExpMap, mFoundMap, hObjKindMessage)
bIsEqual = true;
if isempty(mExpMap) && isempty(mFoundMap)
    return
elseif isempty(mExpMap) || isempty(mFoundMap)
    bIsEqual = false;
    return
end
casExpected = mExpMap.keys;
for i = 1:numel(casExpected)
    sExpected = casExpected{i};
    oExp = i_getAndCheckMapValue(mExpMap, sExpected);
    
    if mFoundMap.isKey(sExpected)
        oFound = i_getAndCheckMapValue(mFoundMap, sExpected);
        
        bEqualObjKind = strcmp(oExp.sObjKind, oFound.sObjKind);
        bEqualAtt = isequal(oExp.stAttributes, oFound.stAttributes);
        bEqualChildren = i_compareMapsRecusive(oExp.mChildren, oFound.mChildren, hObjKindMessage);
        bIsEqualMapEntry = bEqualObjKind && bEqualAtt && bEqualChildren;
        
        SLTU_ASSERT_TRUE(bIsEqualMapEntry, 'Found unexpected properties in %s "%s".', ...
            feval(hObjKindMessage, oExp.sObjKind), sExpected);
        bIsEqual = bIsEqual && bIsEqualMapEntry;
    else
        bIsEqual = false;
        SLTU_FAIL('Expected %s "%s" not found.', feval(hObjKindMessage, oExp.sObjKind), sExpected);
    end
end

casFound = mFoundMap.keys;
casUnexpected = setdiff(casFound, casExpected);
for i = 1:numel(casUnexpected)
    bIsEqual = false;
    oFound = i_getAndCheckMapValue(mFoundMap, casUnexpected{i});
    SLTU_FAIL('Found unexpected %s "%s".', feval(hObjKindMessage, oFound.sObjKind), casUnexpected{i});
end
end


%%
function sMessage = i_getDefaultObjKindMessage(sObjKind)
sMessage = sObjKind;
end


%%
function oObj = i_getAndCheckMapValue(mMap, sKey)
oObj = mMap(sKey);
if ~isa(oObj, 'XmlComparator')
    error('XML_COMPARATOR:USER_ERROR:WRONG_OBJECT', 'The map value has the wrong class');
end
end