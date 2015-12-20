err_cnt=0;
err_list=[];

%Creating model
clear  vmodel_config;
vmodel_config.src_filename       =   'multi_clock_gen_tst.v';  %source *.v file. Required.
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-10;           %simulink sample time
vmodel_config.multiclock         =   1;                %Setting multiclock mode
vmodel_config.clk_to_out         =   1;
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'top';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.clocks.clk.result='any';
vmodel_config.clocks.clk100.freq=1.1*10^6;
vmodel_config.clocks.clk100.shift=0.1;
vmodel_config.clocks.clk100.result='anyedge';
vmodel_config.clocks.clk10.freq=1.01*10^6;
vmodel_config.clocks.clk10.shift180=1;
vmodel_config.clocks.clk10.result='anyedge';
vmodel(vmodel_config);
uut=constructor;
[rs t]=sim_step(uut,21);

clock_test;

%Uncomment to plot waveforms
% figure(1)
% stairs(t2f(t),rs.clk,'-bo');
% hold on
% stairs(t2f(t),rs.clk100+2,'-o');
% stairs(t2f(t),rs.clk10+4,'-o');
% stairs(res_time,res(:,1),'-ro')
% stairs(res_time,res(:,2)+2,'-ro')
% stairs(res_time,res(:,3)+4,'-ro')
% hold off
% grid

[err_cnt, err_list] = add_test_res(err_cnt,err_list,1001,sum((res_time-t2f(t)')>10^-12));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1002,sum(res(:,1)~=double(rs.clk)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1003,sum(res(:,2)~=double(rs.clk100)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1004,sum(res(:,3)~=double(rs.clk10)));

%Simulink test
sim('multi_clock_gen_model',[0 21*10^(-6)]);
simulink_edge_cnt = sum(abs(diff(double(ScopeData.signals.values)))); %Number of out edges in simulink
matlab_edge_cnt = sum(abs(diff(double(ScopeData.signals.values))));   %Number of out edges in matlab
%number of edges should be the same
[err_cnt, err_list] = add_test_res(err_cnt,err_list,1005,sum(simulink_edge_cnt~=matlab_edge_cnt));

if(err_cnt==0) %Test passed if no errors
    result=1;
    %Delete model files if test passed
    delete('constructor.m','sim_step.m','f2t.m','t2f.m',...
        'm_multi_clock_gen_tst.*','s_multi_clock_gen_tst.*',...
        'multi_clock_gen_tst.mdl','random_seed.txt');
else
    result=0;
end    

result_info.name = 'Multiclock simulation test';
result_info.error_count = err_cnt;
result_info.error_list = err_list;