err_cnt=0;
err_list=[];

%Creating model
clear  vmodel_config;
vmodel_config.src_filename       =   'cov_tst_main.v'; %source *.v file. Required.
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-6;           %simulink sample time
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.coverage           =   0;                %turning off code coverage            
vmodel(vmodel_config);
uut=constructor;
uut.rst=1;
sim_step(uut,1,1);
uut.rst=0;
sim_step(uut,1,1);

if (exist('coverage.dat','file'))
    delete('coverage.dat');
end

for i=1:100
   uut.in=floor(rand*256);
   sim_step(uut,1,1);
end

%saving coverage data (should have no affect due to coverage = 0);
sim_step(uut,0,1)
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1071, exist('coverage.dat','file'));


vmodel_config.coverage           =   1;                %turning on code coverage            
vmodel(vmodel_config);
uut=constructor;
uut.rst=1;
sim_step(uut,1,1);
uut.rst=0;
sim_step(uut,1,1);

for i=1:10000
   uut.in=floor(rand*256);
   sim_step(uut,1,1);
end

%saving coverage data
sim_step(uut,0,1)
[prcnt,covered_lines,total_lines] = vcoverage( 1000, 0, {}, 'coverage.dat', 'cov_result' );

[err_cnt, err_list] = add_test_res(err_cnt,err_list,1021, covered_lines~=10);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1022, total_lines~=14);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1023, prcnt~=10/14*100);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1024, ~exist('cov_result','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1025, ~exist('cov_result/cov_tst_main.v','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1026, ~exist('cov_result/cov_tst_sup.v','file'));
copyfile('coverage.dat','cov.dat','f');

[prcnt,covered_lines,total_lines] = vcoverage( 2000, 1, {}, 'cov.dat', 'cov_result_strict' );
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1031, covered_lines~=8);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1032, total_lines~=14);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1033, prcnt~=8/14*100);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1034, ~exist('cov_result_strict','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1035, ~exist('cov_result_strict/cov_tst_main.v','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1036, ~exist('cov_result_strict/cov_tst_sup.v','file'));

[prcnt,covered_lines,total_lines] = vcoverage( 20, 0, {'cov_tst_sup'} );
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1041, covered_lines~=10);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1042, total_lines~=12);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1043, prcnt~=10/12*100);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1044, ~exist('coverage_source','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1045, ~exist('coverage_source/cov_tst_main.v','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1046, exist('coverage_source/cov_tst_sup.v','file'));

[prcnt,covered_lines,total_lines] = vcoverage( 20, 0, {'cov_tst_sup','cov_tst_main'},'cov.dat', 'cov_result_empty'  );
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1051, covered_lines~=0);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1052, total_lines~=0);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1053, prcnt~=0);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1054, ~exist('cov_result_empty','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1055, exist('cov_result_empty/cov_tst_main.v','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1056, exist('cov_result_empty/cov_tst_sup.v','file'));

%Cleaing coverage data
rmdir('coverage_source','s')
%Testig simulink
sim('cov_test_model',[0 10^-4]);
[prcnt,covered_lines,total_lines] = vcoverage;
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1061, covered_lines~=4);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1062, total_lines~=14);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1063, prcnt~=4/14*100);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1064, ~exist('coverage_source','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1065, ~exist('coverage_source/cov_tst_main.v','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1066, ~exist('coverage_source/cov_tst_sup.v','file'));

rmdir('coverage_source','s')
sim('cov_test_model',[0 10^-4]);
[prcnt,covered_lines,total_lines] = vcoverage;
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1067, covered_lines~=5);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1068, total_lines~=14);

%Resetin coverage data
clear functions

rmdir('coverage_source','s')
sim('cov_test_model',[0 10^-4]);
[prcnt,covered_lines,total_lines] = vcoverage;
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1069, covered_lines~=4);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1070, total_lines~=14);

if(err_cnt==0) %Test passed if no errors
    result=1;
    %Delete model files if test passed
    delete('constructor.m','sim_step.m','f2t.m','t2f.m',...
        'm_cov_tst_main.*','s_cov_tst_main.*',...
        'cov_tst_main.mdl','coverage.dat','cov.dat');
    rmdir('coverage_source','s')
    rmdir('cov_result','s')
    rmdir('cov_result_empty','s')
    rmdir('cov_result_strict','s')
else
    result=0;
end


result_info.name = 'Code coverage test';
result_info.error_count = err_cnt;
result_info.error_list = err_list;
