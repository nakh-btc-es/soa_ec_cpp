function testme()

MC_init();
MC_add_sut_file(fullfile(pwd, 'coverme.m'));
MC_on;
coverme;
MC_off;
MC_save_data('data.mat');
MC_clear;
MC_add_data('data.mat');
MC_add_data('data.mat');
coverme;
MC_report;
return;