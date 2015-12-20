%Creating model
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-9;            %simulink sample time
vmodel_config.multiclock         =   1;                %Setting multiclock mode
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'top';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.clocks.clk.freq = 10^6;
vmodel_config.clocks.clk.shift = 0;
vmodel_config.clocks.clk.shift180 = 1;
vmodel_config.clocks.clk.result = 'any';
vmodel_config.clocks.clk.jitter = 10^-7;               %Maximal jitter, should be rounded to half period
vmodel_config.random_seed       = 1;                   %Setting random seed to be sure test is always same
vmodel(vmodel_config);

uut=constructor;
uut.rst=1;
sim_step(uut);
uut.rst=0;
sim_step(uut);

[res, t]=sim_step(uut,10000);
time_diff=diff(t2f(t(1:end-1)));
period=mean(time_diff);
rangej=[min((time_diff-period)) max((time_diff-period))];
maxj=vmodel_config.clocks.clk.jitter*(vmodel_config.fpga_freq*10^6);
 
[err_cnt, err_list] = add_test_res(err_cnt,err_list,331,((rangej(1)<(-maxj*1.01))+(rangej(1)>(-maxj*0.99))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,332,((rangej(2)<(maxj*0.99))+(rangej(1)>(maxj*1.01))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,333,(period<0.49)+(period>0.51));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,334,sum(res.counter(1:2:end-1)'~=1:10000));

sim('simple_test_jitter.mdl',[0 10^-3]);
edge_points=find(abs(diff(double(sim_result.signals(1).values))));
time_diff=diff(t2f(edge_points*10^-9));
period=mean(time_diff);
rangej=[min((time_diff-period)) max((time_diff-period))];
maxj=vmodel_config.clocks.clk.jitter*(vmodel_config.fpga_freq*10^6);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,335,((rangej(1)<(-maxj*1.01))+(rangej(1)>(-maxj*0.99))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,336,((rangej(2)<(maxj*0.99))+(rangej(1)>(maxj*1.01))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,337,(period<0.49)+(period>0.51));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,338,sum(double(sim_result.signals(2).values(edge_points(1:2:end)))'~=(0:999)));
