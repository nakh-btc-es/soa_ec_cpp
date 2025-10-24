function [ret] = atgcv_debug_internal(varargin)

persistent debug_status;

if isempty(debug_status)
    debug_status = 0;
end

if ~isempty(varargin)
    bOn = varargin{1};
    if ~isa(bOn, 'double')
        bOn = 0;
    end
    debug_status = bOn;
end

ret = debug_status;

return;

