function ut_ep_sim_bus_info_build()
% Checking bugfix for EP-2359 on low level function.
%
%

%%
% simple scalar signal
astBusExpected = i_busLeafInfo('a', 'mytype', 'mydim');
astBusInfo = ep_sim_bus_info_build({'a'}, {'mytype'}, {'mydim'});
SLTU_ASSERT_EQUAL_STRUCT(astBusExpected, astBusInfo);


%%
% simple bus signal with one child signal
stChild = i_busLeafInfo('b', 'mytypeB', 'mydimB');
astBusExpected = i_busInfo('a', stChild);
astBusInfo = ep_sim_bus_info_build( ...
    {'a.b'}, ...
    {'mytypeB'}, ...
    {'mydimB'});
SLTU_ASSERT_EQUAL_STRUCT(astBusExpected, astBusInfo);


%%
% simple bus signal with two child signals with order C,B
stChildB = i_busLeafInfo('b', 'mytypeB', 'mydimB');
stChildC = i_busLeafInfo('c', 'mytypeC', 'mydimC');
astBusExpected = i_busInfo('a', [stChildC, stChildB]);

astBusInfo = ep_sim_bus_info_build( ...
    {'a.c',     'a.b'}, ...
    {'mytypeC', 'mytypeB'}, ...
    {'mydimC',  'mydimB'});
SLTU_ASSERT_EQUAL_STRUCT(astBusExpected, astBusInfo);


%%
% EP-2359: deeply nested bus hiearchy with three simple leafs
stChildX     = i_busLeafInfo('x', 'mytypeX', 'mydimX');
stChildY     = i_busLeafInfo('y', 'mytypeY', 'mydimY');
astChildBusD = i_busInfo('d', [stChildX, stChildY]);
astChildBusC = i_busInfo('c', astChildBusD);
astChildBusB = i_busInfo('b', astChildBusC);
stChildZ     = i_busLeafInfo('z', 'mytypeZ', 'mydimZ');
astBusExpected = i_busInfo('a', [stChildZ, astChildBusB]);

astBusInfo = ep_sim_bus_info_build( ...
    {'a.z',     'a.b.c.d.x', 'a.b.c.d.y'}, ...
    {'mytypeZ', 'mytypeX',   'mytypeY'}, ...
    {'mydimZ',  'mydimX',    'mydimY'});
SLTU_ASSERT_EQUAL_STRUCT(astBusExpected, astBusInfo);


%%
% corner case: empty input --> be robust
astBusInfo = ep_sim_bus_info_build({}, {}, {});
MU_ASSERT_TRUE(isempty(astBusInfo), 'Empty signal list should produce an empty return structure.');
end


%%
function stBusInfo = i_busInfo(sElemName, astChildBusInfos)
stBusInfo = struct( ...
    'sBusElemName', sElemName, ...
    'bIsBus',       true, ...
    'sType',        '', ...
    'sDim',         '', ...
    'astBusInfo',   astChildBusInfos);
end


%%
function stBusInfo = i_busLeafInfo(sElemName, sType, sDim)
stBusInfo = struct( ...
    'sBusElemName', sElemName, ...
    'bIsBus',       false, ...
    'sType',        sType, ...
    'sDim',         sDim, ...
    'astBusInfo',   []);
end
