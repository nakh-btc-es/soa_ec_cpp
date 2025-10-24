function tu_bus_objects_createin(ws, varargin)
% create Simulink.Bus Objects from into provided Workspace
%
% function  tu_bus_objects_createin(ws, varargin)
%
%
%   INPUT               DESCRIPTION
%      ws            (string/handle)   workspace
%      varargin   --------- following structure-----------               
%             (<BusName> <ElementInfo>)+   with
%
%      BusName         (string)       name of the Bus object in workspace
%      ElementInfo     (cell)         with following info                          
%                                     {(<ElemName>, <ElemDim>, <ElemDataType>)+} 
%
%   REMARKS    
%      Note: No consistency checks for the BusObjects done.
%     
%   <et_copyright>

%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alex Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision$
%   Last modified: $Date$ 
%   $Author$
%

if (nargin < 3)
    return;
end

caxArgs = varargin;
nArgs = length(caxArgs);
if (mod(nArgs, 2) ~= 0)
    error('TU:USAGE:ERROR', ...
        'Argument _pairs_ expected. Please refer to "help".');
end

for i = 1:2:nArgs
    sName = caxArgs{i};
    caxElemInfo = caxArgs{i + 1};
    i_checkArgs(((i+1)/2), sName, caxElemInfo);
    
    oBus = i_createBus(caxElemInfo);
    assignin(ws, sName, oBus);
end
end


%%
function oBus = i_createBus(caxElemInfo)
oBus = Simulink.Bus;
oBus.Elements = i_createElements(caxElemInfo);
end


%%
function aElements = i_createElements(caxElemInfo)
nInfos = length(caxElemInfo);
nElems = nInfos/3;

aElements = repmat(Simulink.BusElement, 1, nElems);
for i = 1:3:nInfos
    iIdx = (i+2)/3;
    
    aElements(iIdx).Name       = caxElemInfo{i};
    aElements(iIdx).Dimensions = caxElemInfo{i + 1};
    aElements(iIdx).DataType   = caxElemInfo{i + 2};    
end
end


%%
function i_checkArgs(iPair, sName, caxElemInfo)
if ~ischar(sName)
    error('TU:USAGE:ERROR', ...
        'Pair %d: First Arg (Name of BusObject) needs to be a String.', iPair);
end
if (~iscell(caxElemInfo) || (mod(length(caxElemInfo), 3) ~= 0))
    error('TU:USAGE:ERROR', ...
        'Pair %d: Second Argument (Element Info) needs to be a Cell with mutliple-of-3 elements.', iPair);
else
    for i = 1:3:length(caxElemInfo)
        if ~ischar(caxElemInfo{i})
            error('TU:USAGE:ERROR', ...
                'Pair %d: Cell-Element %d (Element Name) needs to be a String.', iPair, i);
        end
        if ~isnumeric(caxElemInfo{i + 1})
            error('TU:USAGE:ERROR', ...
                'Pair %d: Cell-Element %d (Dimension) needs to be a Number.', iPair, i);
        end
        if ~ischar(caxElemInfo{i + 2})
            error('TU:USAGE:ERROR', ...
                'Pair %d: Cell-Element %d (Data Type) needs to be a String.', iPair, i);
        end
    end
end
end


