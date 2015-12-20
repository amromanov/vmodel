%Creating model
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.clk_name           =   'clk';            %clock signal name
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-6;            %simulink sample time
vmodel_config.multiclock         =   multiclock;       %Setting multiclock mode
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.inputs_to_out = 1;
vmodel(vmodel_config);

%Reseting
uut=constructor;
uut.rst=1;
sim_step(uut,1,1);
uut.rst=0;

a_m=floor(rand(2^9+257,1)*2^30-2^29);
b_m=floor(rand(2^9+257,1)*2^30-2^29);

uut.a=a_m(1);
uut.b=b_m(1);
[res t]=sim_step(uut,1);


for i=1:(2^9+256)
    uut.a=a_m(i+1);
    uut.b=b_m(i+1);
    [res t]=sim_step(uut,2^7,res,t);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,201,uut.a~=uint2sign(res.a(end),32));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,201,uut.b~=uint2sign(res.b(end),32));
end  

a_s=uint2sign(res.a,32);
b_s=uint2sign(res.b,32);
r_s=uint2sign(res.adder_result,32);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,202,sum(r_s(2:end)~=(a_s(1:end-1)+b_s(1:end-1))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,202,sum(r_s(2:end)~=(a_s(1:end-1)+b_s(1:end-1))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,203,sum(res.counter~=(mod(1:length(res.counter),2^16)')));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,204,sum((res.counter==0)~=(res.counter_rdy)));
db=dec2bin(res.v_97bit_round(:,end:-1:1)',32);
db=[db(1:4:end,32) db(2:4:end,:) db(3:4:end,:) db(4:4:end,:)];
[err_cnt, err_list] = add_test_res(err_cnt,err_list,205,sum(sum(db(2:end,:)~=[db(1:end-1,2:end) db(1:end-1,1)])));
rdy_index=find(res.counter_rdy);
res_etalon=res;

%Second reset
uut=constructor;
uut.rst=1;
sim_step(uut,1,1);
uut.rst=0;

uut.a=a_m(1);
uut.b=b_m(1);
[res]=sim_step(uut,1);


for i=1:(2^9+256)
    uut.a=a_m(i+1);
    uut.b=b_m(i+1);
    [res]=sim_step(uut,2^7,res);
end  

[err_cnt, err_list] = add_test_res(err_cnt,err_list,206,sum(res.a~=res_etalon.a));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,206,sum(res.b~=res_etalon.b));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,207,sum(res.adder_result~=res_etalon.adder_result));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,208,sum(res.a_s~=res_etalon.a_s));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,209,sum(res.b_s~=res_etalon.b_s));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,210,sum(res.cnt~=res_etalon.cnt));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,211,sum(res.counter~=res_etalon.counter));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,212,sum(res.counter_rdy~=res_etalon.counter_rdy));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,213,sum(sum(res.shift~=res_etalon.shift)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,214,sum(sum(res.v_97bit_round~=res_etalon.v_97bit_round)));

%Reset with time shift

uut=constructor;
uut.rst=1;
sim_step(uut,0.2,1); %Super fast reset
uut.rst=0;

uut.a=a_m(1);
uut.b=b_m(1);
[res t1]=sim_step(uut,1);


for i=1:(2^9+256)
    uut.a=a_m(i+1);
    uut.b=b_m(i+1);
    [res t1]=sim_step(uut,2^7,res,t1);
end

edge_points=find((t2f(t1)-round(t2f(t1)))<=1e-10);  %Selecting by time only points where posedge occured
[err_cnt, err_list] = add_test_res(err_cnt,err_list,225,sum(res.a(edge_points)~=res_etalon.a));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,226,sum(res.b(edge_points)~=res_etalon.b));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,227,sum(res.adder_result(edge_points)~=res_etalon.adder_result));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,228,sum(res.a_s(edge_points)~=res_etalon.a_s));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,229,sum(res.b_s(edge_points)~=res_etalon.b_s));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,230,sum(res.cnt(edge_points)~=res_etalon.cnt));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,231,sum(res.counter(edge_points)~=res_etalon.counter));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,232,sum(res.counter_rdy(edge_points)~=res_etalon.counter_rdy));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,233,sum(sum(res.shift(edge_points,:,:)~=res_etalon.shift)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,234,sum(sum(res.v_97bit_round(edge_points,:,:)~=res_etalon.v_97bit_round)));
frac_times=t2f(t1(find((t2f(t1)-round(t2f(t1)))>1e-10))); %Time points not on edge
[err_cnt, err_list] = add_test_res(err_cnt,err_list,234,sum(((frac_times-fix(frac_times))-0.2)>1e-10)); %all fractional time end with 0.2

%Conditional simulation 
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.clk_name           =   'clk';            %clock signal name
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.sim_name2          =   'sim_tcond';      %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.break_condition             =   'top->counter_rdy == 1'; %Breaking condition
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-6;            %simulink sample time
vmodel_config.multiclock         =   multiclock;       %Setting multiclock mode
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.inputs_to_out = 1;
vmodel(vmodel_config);

%Reseting
uut=constructor;
uut.rst=1;
sim_step(uut,1,1); %Super fast reset
uut.rst=0;
sim_step(uut,1.2,1);
[res tc]=sim_tcond(uut,2^17);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,240,sum(res.cnt~=res_etalon.cnt(rdy_index)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,241,sum(res.counter~=res_etalon.counter(rdy_index)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,242,sum(res.counter_rdy~=res_etalon.counter_rdy(rdy_index)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,243,sum(sum(res.shift~=res_etalon.shift(rdy_index,:,:))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,244,sum(sum(res.v_97bit_round~=res_etalon.v_97bit_round(rdy_index,:,:))));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,245,sum(tc~=t(rdy_index)));

%Simulation with timeout shorter then breaking condition period
sim_step(uut,1,1);
res=sim_tcond(uut,2^14); 
[err_cnt, err_list] = add_test_res(err_cnt,err_list,246,res.counter_rdy~=0); %in this case counter_rdy should be 0

[res,tc]=sim_tcond(uut,2^14,res_etalon,t);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,247,(length(res_etalon.counter)+1)~=(length(res.counter)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,248,length(tc)~=(length(t)+1));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,249,sum(tc(1:end-1)~=t));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,250,sum(res.counter(1:end-1)~=res_etalon.counter));

[res]=sim_tcond(uut,2^14,res_etalon);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,247,(length(res_etalon.counter)+1)~=(length(res.counter)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,250,sum(res.counter(1:end-1)~=res_etalon.counter));

%First point parameter simulation
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.clk_name           =   'clk';            %clock signal name
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.sim_name2          =   'sim_tcond';      %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.first_point        =    1;               %add first point to simulation results
vmodel_config.break_condition             =   'top->counter_rdy == 1'; %Breaking condition
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-6;            %simulink sample time
vmodel_config.multiclock         =   multiclock;       %Setting multiclock mode
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel(vmodel_config);

uut=constructor;
uut.rst=1;
[res t]=sim_step(uut,1);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,250,sum(t2f(t)~=[0; 1]));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,250,sum(squeeze(res.v_97bit_round(:,1))~=[1; 1]));
uut.rst=0;
[res t]=sim_step(uut,1);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,251,sum(t2f(t)~=[1; 2]));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,251,sum(squeeze(res.v_97bit_round(:,1))~=[1; 2]));
[res t]=sim_step(uut,1.3);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,252,sum(t2f(t)~=[2; 3; 3.3]));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,252,sum(squeeze(res.v_97bit_round(:,1))~=[2; 4; 4]));
[res t]=sim_step(uut,1.5);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,253,sum(t2f(t)~=[3.3; 4; 4.8]));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,253,sum(squeeze(res.v_97bit_round(:,1))~=[4; 8; 8]));
[res t]=sim_step(uut,1.2);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,254,sum(t2f(t)~=[4.8; 5; 6]));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,254,sum(squeeze(res.v_97bit_round(:,1))~=[8; 16; 32]));
[res t]=sim_step(uut,0);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,255,sum(t2f(t)~=6));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,255,sum(squeeze(res.v_97bit_round(:,1))~=32));

%Any_edge parameter simulation
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.clk_name           =   'clk';            %clock signal name
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.sim_name2          =   'sim_tcond';      %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.first_point        =    0;               %add first point to simulation results
vmodel_config.break_condition             =   'top->counter_rdy == 1'; %Breaking condition
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.sample_time        =   10^-6;            %simulink sample time
vmodel_config.multiclock         =   multiclock;       %Setting multiclock mode
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.any_edge            =   1;                %save data on each edge
vmodel_config.inputs_to_out = 1;                       %copy inputs to simulation results
vmodel_config.clk_to_out = 1;                          %copy clock signals to simulation results
vmodel(vmodel_config);

uut=constructor;
uut.rst=1;
sim_step(uut,1,1);
[res t]=sim_step(uut,0.5);
uut.rst=0;
uut.a=a_m(1);
uut.b=b_m(1);
[res t]=sim_step(uut,0.5,res,t);

for i=1:(2^9+256)
    uut.a=a_m(i+1);
    uut.b=b_m(i+1);
    [res t]=sim_step(uut,2^7,res,t);
end  

edge_points=2:2:length(t);  %Selecting by time only points where posedge occured
[err_cnt, err_list] = add_test_res(err_cnt,err_list,260,sum(res.a(edge_points)~=res_etalon.a));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,261,sum(res.b(edge_points)~=res_etalon.b));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,262,sum(res.adder_result(edge_points)~=res_etalon.adder_result));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,263,sum(res.a_s(edge_points)~=res_etalon.a_s));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,264,sum(res.b_s(edge_points)~=res_etalon.b_s));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,265,sum(res.cnt(edge_points)~=res_etalon.cnt));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,266,sum(res.counter(edge_points)~=res_etalon.counter));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,267,sum(res.counter_rdy(edge_points)~=res_etalon.counter_rdy));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,268,sum(sum(res.shift(edge_points,:,:)~=res_etalon.shift)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,269,sum(sum(res.v_97bit_round(edge_points,:,:)~=res_etalon.v_97bit_round)));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,270,~isempty(find(abs(diff(double(res.clk)))~=1))); %clock should change at every point

res_any_edge=res;

%Simulink test
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.clk_name           =   'clk';            %clock signal name
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.sim_name2          =   'sim_tcond';      %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.any_edge           =   0;                %save data on each edge
vmodel_config.sample_time        =   10^-6/2;          %simulink sample time (over sampling)
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'top';            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.clk_to_out         =   1;                %clk_to_out should not affect simulink
vmodel_config.multiclock         =   multiclock;       %Setting multiclock mode
vmodel(vmodel_config);

%Creating each cycle input vector for Simulink
as_m=[a_m(1); reshape(repmat(a_m(2:end)',2^7,1),1,[])'];
bs_m=[b_m(1); reshape(repmat(b_m(2:end)',2^7,1),1,[])'];
sim('simple_test_simulink.mdl',[0  (98305*10^-6)]);

sim_counter=cntr(2:end);
sim_clk=clk_echo(2:end);
sim_adder_result=add_result(2:end);
sim_97bit_round=rnd97b(2:end,:);
sim_counter_rdy=cnt_rdy(2:end);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,281,sum(res_any_edge.clk~=sim_clk));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,282,sum(res_any_edge.adder_result~=sim_adder_result));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,283,sum(res_any_edge.counter~=sim_counter));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,284,sum(res_any_edge.counter_rdy~=sim_counter_rdy));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,285,sum(sum(squeeze(res_any_edge.v_97bit_round)~=sim_97bit_round)));

%Second simulation without clearing functions

sim('simple_test_simulink.mdl',[0  (98305*10^-6)]);
sim_counter=cntr(2:end);
sim_clk=clk_echo(2:end);
sim_adder_result=add_result(2:end);
sim_97bit_round=rnd97b(2:end,:);
sim_counter_rdy=cnt_rdy(2:end);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,281,sum(res_any_edge.clk~=sim_clk));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,282,sum(res_any_edge.adder_result~=sim_adder_result));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,283,sum(res_any_edge.counter~=sim_counter));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,284,sum(res_any_edge.counter_rdy~=sim_counter_rdy));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,285,sum(sum(squeeze(res_any_edge.v_97bit_round)~=sim_97bit_round)));

%Interal random change (partial memory change) 
clear  vmodel_config;
vmodel_config.src_filename       =   'simple_test.v';  %source *.v file. Required.
vmodel_config.clk_name           =   'clk';            %clock signal name
vmodel_config.constr_name        =   'constructor';    %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';       %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   1;                %freq
vmodel_config.any_edge           =   1;                %save data on each edge
vmodel_config.sample_time        =   10^-6/2;          %simulink sample time
vmodel_config.output             =   '';               %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'public';         %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.clk_to_out = 1;
vmodel_config.rchg_probability   =   1;                %Change signal in 100% of cases
vmodel_config.rchg_full_mem      =   0;
vmodel_config.rchg_show_param    =   0;
vmodel_config.multiclock         =   multiclock;       %Setting multiclock mode
vmodel(vmodel_config);

uut=constructor;
res=sim_step(uut,10000);


[err_cnt err_list] = add_test_res(err_cnt,err_list,290,sum(sum(squeeze(res.hidden_mem(:,1,:))>=ones(20000,100)*2.^32))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,290,sum(sum(squeeze(res.hidden_mem(:,2,:))>=ones(20000,100)*2.^32))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,290,sum(sum(squeeze(res.hidden_mem(:,3,:))>=ones(20000,100)*2.^32))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,291,sum(sum(squeeze(res.hidden_signal)>=repmat([2^32  2^32 2^11],20000,1)))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,292,sum(sum(squeeze(res.short_hidden_signal)>=repmat(2^13,20000,1)))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,293,length(find(diff(squeeze(double(res.hidden_mem(:,1,:))))~=0))~=19999);  %Only one memory element should change per one cycly
[err_cnt err_list] = add_test_res(err_cnt,err_list,293,length(find(diff(squeeze(double(res.hidden_mem(:,2,:))))~=0))~=19999);  %Only one memory element should change per one cycly
[err_cnt err_list] = add_test_res(err_cnt,err_list,293,length(find(diff(squeeze(double(res.hidden_mem(:,3,:))))~=0))~=19999);  %Only one memory element should change per one cycly
[err_cnt err_list] = add_test_res(err_cnt,err_list,294,length(find(diff(double(res.hidden_signal(:,1,1)))~=0))~=19999);    %Signal should change every cycle
[err_cnt err_list] = add_test_res(err_cnt,err_list,294,length(find(diff(double(res.hidden_signal(:,1,2)))~=0))~=19999);    %Signal should change every cycle
[err_cnt err_list] = add_test_res(err_cnt,err_list,294,length(find(diff(double(res.hidden_signal(:,1,3)))~=0))~=19999);    %Signal should change every cycle
[err_cnt err_list] = add_test_res(err_cnt,err_list,295,isfield(res,'rchg_total'));
[err_cnt err_list] = add_test_res(err_cnt,err_list,295,isfield(res,'rchg_count'));

%Interal random change (full memory change) 
vmodel_config.rchg_full_mem      =   1;

vmodel(vmodel_config);

uut=constructor;
res=sim_step(uut,10000);


[err_cnt err_list] = add_test_res(err_cnt,err_list,296,sum(sum(squeeze(res.hidden_mem(:,1,:))>=ones(20000,100)*2.^32))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,296,sum(sum(squeeze(res.hidden_mem(:,2,:))>=ones(20000,100)*2.^32))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,296,sum(sum(squeeze(res.hidden_mem(:,3,:))>=ones(20000,100)*2.^32))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,297,sum(sum(squeeze(res.hidden_signal)>=repmat([2^32  2^32 2^11],20000,1)))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,298,sum(sum(squeeze(res.short_hidden_signal)>=repmat(2^13,20000,1)))); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,299,length(find(diff(squeeze(double(res.hidden_mem(:,1,:))))~=0))~=19999*100);  %All memory elements should change per one cycly
[err_cnt err_list] = add_test_res(err_cnt,err_list,299,length(find(diff(squeeze(double(res.hidden_mem(:,2,:))))~=0))~=19999*100);  %All memory elements should change per one cycly
[err_cnt err_list] = add_test_res(err_cnt,err_list,299,length(find(diff(squeeze(double(res.hidden_mem(:,3,:))))~=0))~=19999*100);  %All memory elements should change per one cycly
[err_cnt err_list] = add_test_res(err_cnt,err_list,300,length(find(diff(double(res.hidden_signal(:,1,1)))~=0))~=19999);    %Signal should change every cycle
[err_cnt err_list] = add_test_res(err_cnt,err_list,300,length(find(diff(double(res.hidden_signal(:,1,2)))~=0))~=19999);    %Signal should change every cycle
[err_cnt err_list] = add_test_res(err_cnt,err_list,300,length(find(diff(double(res.hidden_signal(:,1,3)))~=0))~=19999);    %Signal should change every cycle

%Interal random change (full memory change) 
vmodel_config.rchg_probability   =   0.25;                %Change signal in 25% of cases
vmodel_config.rchg_full_mem      =   1;
vmodel_config.rchg_show_param    =   1;

vmodel(vmodel_config);

uut=constructor;
res=sim_step(uut,10000);

m_prob1=length(find(diff(squeeze(double(res.hidden_mem(:,1,:))))~=0))./(size(res.hidden_mem,1)*size(res.hidden_mem,3));
m_prob2=length(find(diff(squeeze(double(res.hidden_mem(:,2,:))))~=0))./(size(res.hidden_mem,1)*size(res.hidden_mem,3));
m_prob3=length(find(diff(squeeze(double(res.hidden_mem(:,3,:))))~=0))./(size(res.hidden_mem,1)*size(res.hidden_mem,3));
hs_prob1=length(find(diff(double(res.hidden_signal(:,1,1)))~=0))/size(res.hidden_signal,1);
hs_prob2=length(find(diff(double(res.hidden_signal(:,1,2)))~=0))/size(res.hidden_signal,1);
hs_prob3=length(find(diff(double(res.hidden_signal(:,1,3)))~=0))/size(res.hidden_signal,1);
shs_prob=length(find(diff(double(res.short_hidden_signal))~=0))/size(res.short_hidden_signal,1);
total_prob=double(res.rchg_count(end))/double(res.rchg_total(end));

[err_cnt, err_list] = add_test_res(err_cnt,err_list,301,(m_prob1<vmodel_config.rchg_probability*0.8)+(m_prob1>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,302,(m_prob2<vmodel_config.rchg_probability*0.8)+(m_prob2>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,303,(m_prob3<vmodel_config.rchg_probability*0.8)+(m_prob3>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,304,(hs_prob1<vmodel_config.rchg_probability*0.8)+(hs_prob1>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,305,(hs_prob2<vmodel_config.rchg_probability*0.8)+(hs_prob2>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,306,(hs_prob3<vmodel_config.rchg_probability*0.8)+(hs_prob3>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,307,(shs_prob<vmodel_config.rchg_probability*0.8)+(shs_prob>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,308,(total_prob<vmodel_config.rchg_probability*0.8)+(total_prob>vmodel_config.rchg_probability*1.2));

%Creating each sample for Simulink 
r_dt=vmodel_config.sample_time;
sim('simple_test_rchg_simulink.mdl',[0  10000*10^-6]);
hs_prob1=length(find(diff(double(simout(:,2)))~=0))/size(simout,1)/2; %Each simulation cycle has 2 evals() and to random changes, one at input assignment, second on clock cycle
hs_prob2=length(find(diff(double(simout(:,3)))~=0))/size(simout,1)/2; %Each simulation cycle has 2 evals() and to random changes, one at input assignment, second on clock cycle
hs_prob3=length(find(diff(double(simout(:,4)))~=0))/size(simout,1)/2; %Each simulation cycle has 2 evals() and to random changes, one at input assignment, second on clock cycle
shs_prob=length(find(diff(double(simout(:,1)))~=0))/size(simout,1)/2; %Each simulation cycle has 2 evals() and to random changes, one at input assignment, second on clock cycle
total_prob=double(simout(end,6))/double(simout(end,5));

[err_cnt, err_list] = add_test_res(err_cnt,err_list,310,(hs_prob1<vmodel_config.rchg_probability*0.8)+(hs_prob1>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,311,(hs_prob2<vmodel_config.rchg_probability*0.8)+(hs_prob2>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,312,(hs_prob3<vmodel_config.rchg_probability*0.8)+(hs_prob3>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,313,(shs_prob<vmodel_config.rchg_probability*0.8)+(shs_prob>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,314,(total_prob<vmodel_config.rchg_probability*0.8)+(total_prob>vmodel_config.rchg_probability*1.2));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,315,(simout(end,6)<500000)); %With full memory change number of changes should be quite big (more then 100000) 
[err_cnt, err_list] = add_test_res(err_cnt,err_list,316,sum(simout(:,4)>=2^11));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,317,sum(simout(:,1)>=2^13));