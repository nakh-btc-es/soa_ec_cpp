function ut_transform_args()
% Tests the transform args method.
%
%  function ut_transform_args()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

% valid case
stArgs = ep_core_transform_args({'key1', 'value1'}, {'key1'});
MU_ASSERT_TRUE(strcmp(stArgs.key1, 'value1'), 'Key-Value pair has not been transformed correctly.');

% KEY_NOT_ALLOWED
try
    ep_core_transform_args({'key2', 'value1'}, {'key1'});
    MU_FAiL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:API:KEY_NOT_ALLOWED', 'Wrong exception thrown.');
end

% INCONSTENT_KEY (empty string)
try
    ep_core_transform_args({'', 'value1'}, {'key1'});
    MU_FAiL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:API:INCONSISTENT_KEY', 'Wrong exception thrown.');
end

% INCONSTENT_KEY (non-string)
try
    ep_core_transform_args({7.6, 'value1'}, {'key1'});
    MU_FAiL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:API:INCONSISTENT_KEY', 'Wrong exception thrown.');
end

% MULTIPLE_KEY
try
    ep_core_transform_args({'key1', 'value1', 'key1', 'value2'}, {'key1'});
    MU_FAiL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:API:MULTIPLE_KEY', 'Wrong exception thrown.');
end

% INCONSTENT_KEY_VALUES (every key must have a value)
try
    ep_core_transform_args({'key1', 'value1', 'key2'}, {'key1', 'key2'});
    MU_FAiL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:API:INCONSISTENT_KEY_VALUES', 'Wrong exception thrown.');
end

% Note: technical constraint -- currently Keys that cannot be used as fieldnames
%       are not supported
% KEY_NOT_SUPPORTED
try
    ep_core_transform_args({'f(hgh', 'value1'}, {'f(hgh'});
    MU_FAiL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:API:KEY_NOT_SUPPORTED', 'Wrong exception thrown.');
end

% Valid key check disabled
stArgs = ep_core_transform_args({'key1', 'value1', 'key2', 'value2'});
MU_ASSERT_TRUE(length(fieldnames(stArgs)) == 2, 'Two fields expected.');
end
