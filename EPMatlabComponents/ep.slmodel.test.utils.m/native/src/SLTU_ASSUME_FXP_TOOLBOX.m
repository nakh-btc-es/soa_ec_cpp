function bIsAssumptionTrue = SLTU_ASSUME_FXP_TOOLBOX
% assumption for an access to the FixedPoint Toolbox by Simulink
%

bIsAssumptionTrue = license('test', 'fixed_point_toolbox');
if ~bIsAssumptionTrue
    MU_MESSAGE('TEST SKIPPED: FixedPoint license not available.');
    return;
end
end

