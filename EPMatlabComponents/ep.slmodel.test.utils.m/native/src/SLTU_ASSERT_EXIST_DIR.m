function SLTU_ASSERT_EXIST_DIR(sDirectory)
% Asserts that the directory exists.
%


%%
SLTU_ASSERT_TRUE(exist(sDirectory, 'dir'), 'Directory does not exist.');

% NOTE: currently no validation done!
end