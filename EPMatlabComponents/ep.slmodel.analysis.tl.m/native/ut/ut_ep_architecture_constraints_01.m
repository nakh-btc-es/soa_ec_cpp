function ut_ep_architecture_constraints_01
% Test the architecture constraints feature
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ut_ep_architecture_constraints_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'cal_restrictions');

sTlModel      = 'cal_restrictions';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = [];
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);



%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot); %#ok<ASGLU> onCleanup object

%% open TL model
xOnCleanupCloseModels = ut_open_model(xEnv, {sTlModelFile, sTlInitScript}); %#ok<NASGU> onCleanup object
%xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);


% NOTE: first do the analysis and close the model ...
stModel = ut_ep_model_info_get(stOpt);
clear xOnCleanupCloseModels;

% NOTE: ... now, with the model closed, do the export into XML files (EP-1779 -- export wrongly requires an open model)
ep_model_info_export(stOpt, stModel);


%% assert
i_checkConstraintTLArchFile(stOpt.sTlArchConstrFile);
i_checkConstraintCArchFile(stOpt.sCArchConstrFile);
end


%%
function i_checkConstraintCArchFile(sConstraintsCArch)
hRoot = mxx_xmltree('load', sConstraintsCArch);
xOnCleanupClosehRoot = onCleanup(@() mxx_xmltree('clear', hRoot));

%% top_A.c:1:top_A
sScopePath = 'top_A.c:1:top_A';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'f1[0]', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'a1[0]', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_ratelimiter:rslewrate
sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'g1[0]', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'e1[0]', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_lookup1d:input
sOrigin = 'tl_lookup1d:input';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'aaa[0]', ...
    'les', ...
    'aaa[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[1]', ...
    'les', ...
    'aaa[2]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[2]', ...
    'les', ...
    'aaa[3]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[3]', ...
    'les', ...
    'aaa[4]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[4]', ...
    'les', ...
    'aaa[5]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


sOrigin = 'tl_saturate';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'c', ...
    'leq', ...
    'b'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'c', ...
    'leq', ...
    'd'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'d', ...
    'leq', ...
    'e'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'c1[0]', ...
    'leq', ...
    'b1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'c1[0]', ...
    'leq', ...
    'd1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'d1[0]', ...
    'leq', ...
    'e1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[0]', ...
    'leq', ...
    'bb[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[1]', ...
    'leq', ...
    'bb[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[0]', ...
    'leq', ...
    'dd[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[1]', ...
    'leq', ...
    'dd[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'dd[0]', ...
    'leq', ...
    'ee[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'dd[1]', ...
    'leq', ...
    'ee[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


sOrigin = 'tl_saturate:lowerlimit';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'a', 'leq', i_reformat('1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'a', 'leq', i_reformat('1.7')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


sOrigin = 'tl_relay:onswitch';

casValue = {'e1[0]', 'geq', i_reformat('-1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

sOrigin = 'tl_relay';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};
casValue = {'f1[0]', ...
    'leq', ...
    'g1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


%% top_A.c:1:top_A/top_A.c:1:Sa5_sub_C1
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa5_sub_C1';
% tl_saturate
sOrigin = 'tl_saturate';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'c', ...
    'leq', ...
    'b'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'c', ...
    'leq', ...
    'd'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'d', ...
    'leq', ...
    'e'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'c1[0]', ...
    'leq', ...
    'b1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'c1[0]', ...
    'leq', ...
    'd1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'d1[0]', ...
    'leq', ...
    'e1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A.c:1:top_A/top_A.c:1:Sa6_sub_C2
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa6_sub_C2';
% tl_saturate
sOrigin = 'tl_saturate';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'cc[0]', ...
    'leq', ...
    'bb[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[1]', ...
    'leq', ...
    'bb[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[0]', ...
    'leq', ...
    'dd[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'cc[1]', ...
    'leq', ...
    'dd[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'dd[0]', ...
    'leq', ...
    'ee[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'dd[1]', ...
    'leq', ...
    'ee[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


%% top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'f1[0]', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'a1[0]', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'g1[0]', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'e1[0]', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_lookup1d:input
sOrigin = 'tl_lookup1d:input';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'aaa[0]', ...
    'les', ...
    'aaa[1]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[1]', ...
    'les', ...
    'aaa[2]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[2]', ...
    'les', ...
    'aaa[3]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[3]', ...
    'les', ...
    'aaa[4]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'aaa[4]', ...
    'les', ...
    'aaa[5]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_lookup1d:input
sOrigin = 'tl_saturate:lowerlimit';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'a', 'leq', i_reformat('1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'a', 'leq', i_reformat('1.7')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_relay:onswitch
sOrigin = 'tl_relay:onswitch';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'e1[0]', 'geq', i_reformat('-1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_relay
sOrigin = 'tl_relay';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'f1[0]', 'leq', 'g1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


%% top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa11_sub_K1
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa11_sub_K1';
% tl_relay:onswitch
sOrigin = 'tl_relay:onswitch';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'e1[0]', 'geq', i_reformat('-1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa12_sub_K2
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa12_sub_K2';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'a1[0]', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_ratelimiter:rslewrate
sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'e1[0]', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa13_sub_K3
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa13_sub_K3';
% tl_relay
sOrigin = 'tl_relay';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'f1[0]', 'leq', 'g1[0]'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa14_sub_K4
sScopePath = 'top_A.c:1:top_A/top_A.c:1:Sa7_sub_C3/top_A.c:1:Sa14_sub_K4';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'f1[0]', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_ratelimiter:rslewrate
sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'g1[0]', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

end


%%
function i_checkConstraintTLArchFile(sConstraintsTLArch)
hRoot = mxx_xmltree('load', sConstraintsTLArch);
xOnCleanupClosehRoot = onCleanup(@() mxx_xmltree('clear', hRoot));

% top_A/Subsystem/top_A
sScopePath = 'top_A/Subsystem/top_A';

% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/f1', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K2/RateLimiter/a1', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_ratelimiter:rslewrate
sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/g1', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat9/e1', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_lookup1d:input
sOrigin = 'tl_lookup1d:input';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

for i = 2:6
    casValue = { ...
        sprintf('top_A/Subsystem/top_A/sub_B3/Const2/aaa(%d)', i - 1), ...
        'les', ...
        sprintf('top_A/Subsystem/top_A/sub_B3/Const2/aaa(%d)', i)};
    i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);
end


sOrigin = 'tl_saturate';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat1/c', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat1/b'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat1/c', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat2/d'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat2/d', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat3/e'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat7/c1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat7/b1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat7/c1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat8/d1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat8/d1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat9/e1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(1)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat4/bb(1)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(2)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat4/bb(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(1)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat5/dd(1)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(2)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat5/dd(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat5/dd(1)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat6/ee(1)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat5/dd(2)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat6/ee(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


sOrigin = 'tl_saturate:lowerlimit';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_B1/Const1/a', 'leq', i_reformat('1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_B1/Const1/a', 'leq', i_reformat('1.7')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


sOrigin = 'tl_relay:onswitch';

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat9/e1', 'geq', i_reformat('-1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

sOrigin = 'tl_relay';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};
casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/f1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/g1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


%% top_A/Subsystem/top_A/sub_C1
sScopePath = 'top_A/Subsystem/top_A/sub_C1';
% tl_saturate
sOrigin = 'tl_saturate';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat1/c', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat1/b'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat1/c', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat2/d'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat2/d', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat3/e'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat7/c1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat7/b1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat7/c1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat8/d1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C1/Sat8/d1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C1/Sat9/e1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A/Subsystem/top_A/sub_C2
sScopePath = 'top_A/Subsystem/top_A/sub_C2';
% tl_saturate
sOrigin = 'tl_saturate';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(1)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat4/bb(1)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(2)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat4/bb(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(1)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat5/dd(1)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat4/cc(2)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat5/dd(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat5/dd(1)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat6/ee(1)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C2/Sat5/dd(2)', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C2/Sat6/ee(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


%% top_A/Subsystem/top_A/sub_C3
sScopePath = 'top_A/Subsystem/top_A/sub_C3';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/f1', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K2/RateLimiter/a1', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/g1', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K1/Relay1/e1', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_lookup1d:input
sOrigin = 'tl_lookup1d:input';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(1)', ...
    'les', ...
    'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(2)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(2)', ...
    'les', ...
    'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(3)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(3)', ...
    'les', ...
    'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(4)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(4)', ...
    'les', ...
    'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(5)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(5)', ...
    'les', ...
    'top_A/Subsystem/top_A/sub_C3/Look-Up Table/aaa(6)'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_lookup1d:input
sOrigin = 'tl_saturate:lowerlimit';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/Sat1/a', 'leq', i_reformat('1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

casValue = {'top_A/Subsystem/top_A/sub_C3/Sat1/a', 'leq', i_reformat('1.7')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_relay:onswitch
sOrigin = 'tl_relay:onswitch';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K1/Relay1/e1', 'geq', i_reformat('-1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_relay
sOrigin = 'tl_relay';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/f1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/g1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);


%% top_A/Subsystem/top_A/sub_C3/sub_K1
sScopePath = 'top_A/Subsystem/top_A/sub_C3/sub_K1';
% tl_relay:onswitch
sOrigin = 'tl_relay:onswitch';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K1/Relay1/e1', 'geq', i_reformat('-1')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A/Subsystem/top_A/sub_C3/sub_K2
sScopePath = 'top_A/Subsystem/top_A/sub_C3/sub_K2';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K2/RateLimiter/a1', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_ratelimiter:rslewrate
sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K2/RateLimiter/e1', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A/Subsystem/top_A/sub_C3/sub_K3
sScopePath = 'top_A/Subsystem/top_A/sub_C3/sub_K3';
% tl_relay
sOrigin = 'tl_relay';
sConstraintKind = 'signalSignal';
casProperty = {'signal1', 'relation', 'signal2'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/f1', ...
    'leq', ...
    'top_A/Subsystem/top_A/sub_C3/sub_K3/Relay1/g1'};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

%% top_A/Subsystem/top_A/sub_C3/sub_K4
sScopePath = 'top_A/Subsystem/top_A/sub_C3/sub_K4';
% tl_ratelimiter:fslewrate
sOrigin = 'tl_ratelimiter:fslewrate';
sConstraintKind = 'signalValue';
casProperty = {'signal', 'relation', 'value'};

casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K4/RateLimiter/f1', 'leq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);

% tl_ratelimiter:rslewrate
sOrigin = 'tl_ratelimiter:rslewrate';
casValue = {'top_A/Subsystem/top_A/sub_C3/sub_K4/RateLimiter/g1', 'geq', i_reformat('0.0')};
i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue);
end



%%
function i_assertConstraint(hRoot, sScopePath, sOrigin, sConstraintKind, casProperty, casValue)
ahScopes = mxx_xmltree('get_nodes', hRoot, ['/architectureConstraints/scope[@path="', sScopePath , '"]']);
MU_ASSERT_TRUE(~isempty(ahScopes), ['"', sScopePath, '" is missing']);
if length(ahScopes)~=1
    return;
end
hScope = ahScopes(1);
sXPath = ['./assumptions[@origin="', sOrigin, '"]/', sConstraintKind,...
    '[normalize-space(@', casProperty{1}, ')="', casValue{1}, '" and', ...
    ' normalize-space(@', casProperty{2}, ')="', casValue{2}, '" and', ...
    ' normalize-space(@', casProperty{3}, ')="', casValue{3}, '"]'];
ahAssumptions = mxx_xmltree('get_nodes', hScope, sXPath);
MU_ASSERT_TRUE(~isempty(ahAssumptions), ['Constraint "', sXPath, '" not found']);
end


%%
function sVal = i_reformat(sValue)
sVal = eval(['sprintf(''%.16e'', ', sValue, ')']);
end
