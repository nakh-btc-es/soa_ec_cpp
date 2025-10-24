function bIsNeeded = ep_sil_scaling_needed(sBaseTypeTL, bIsFloat, dLsb, dOffset, sTypeMIL)
% Deciding if the FixedPoint Scaling info (LSB, Offset) for a SIL interface is really needed.
%
% bIsNeeded = ep_sil_scaling_needed(sBaseTypeTL, bIsFloat, dLsb, dOffset, sTypeMIL)
%
%   INPUT               DESCRIPTION
%    - sBaseTypeTL          (string)   the TargetLink base type, e.g. 'Int32', 'Bool', 'Float32', ...
%    - bIsFloat             (bool)     flag if the type is a floating point value type
%    - dLsb                 (double)   value of the FixedPoint parameter "LSB"
%    - dOffset              (double)   value of the FixedPoint paraemter "Offset"
%    - sTypeMIL             (string)   optional: the corresponding Simulink type, e.g. 'double', 'single', 'int32', 'boolean', ...
%
%   OUTPUT              DESCRIPTION
%    - bIsNeeded            (bool)     flag if the FixedPoint scaling is needed for correct representation
%
%
%   REMARK:
%     This is a heuristic approach to determine the intention of the User if a default Scaling (LSB=1.0 and Offset=0.0)
%     is provided in TargetLink (TL) for an interface object. Even though TL does not store this info, EP2.x shall
%     discriminate between a "pure" Integer type and a FixedPoint type with LSB=1.0 and Offset=0.0.
%
%     --> Main idea: basis for the decision is the MIL type
%
%
% $$$COPYRIGHT$$$
%

%%
if ((nargin < 5) || isempty(sTypeMIL))
    sTypeMIL = 'double'; % use the default Simulink MIL type "double" if not provided by User
end

%%
% 1) if SIL type is float type or Bool or Bitfield --> Scaling is never needed
if (bIsFloat || any(strcmp(sBaseTypeTL, {'Bool', 'Bitfield'})))
    bIsNeeded = false;
    return;
end

% 2) now take the MIL type into account to "guess" the intention of the SIL type: 
%    a) if MIL is float type, SIL Scaling is _always_ needed
%    b) if MIL is integer type, i.e. (u)int8, (u)int16, (u)int32, (u)int64,
%       SIL Scaling is perhaps not needed, depeding on LSB and Offset
bIsIntegerMIL = ~isempty(regexp(sTypeMIL, '^u?int', 'once'));
bIsNeeded = ~bIsIntegerMIL || (dLsb ~= 1.0) || (dOffset ~= 0.0);
end


