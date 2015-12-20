%testing work with memory and inputs, which indices don't start from 0
clear  vmodel_config;
vmodel_config.src_filename       =   'no_clock_index_test_model.v';   %source *.v file. Required.
vmodel_config.no_matlab_model    =   0;                   %1 = don't make model for Matlab, default 0
vmodel_config.no_simulink_model  =   0;                   %1 = don't make model for Simulink, default 0
vmodel_config.constr_name        =   'constructor';       %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';          %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   50;                  %frequency of FPGA in MHz. Default is 50 MHz.
vmodel_config.sample_time        =   0.001;               %sample time in Simulink S-fcn. Default 0.001
vmodel_config.output             =   '';                  %output directory. Default 'm_' + model_name.
vmodel_config.reinterpret_floats =   0;                   %1 = floats are reinterpreted as unsigned integers (bitwise)
vmodel_config.first_point        =   0;                   %1 = add to output vector ititial point while modeling, default 0
vmodel_config.any_edge           =   0;                   %1 = output data on every clock change, 0 - only on posedge, default 0
vmodel_config.signals            =   'top';               %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '';                  %string with additional keys to verilator. eg '--top-module fft'
vmodel_config.coverage           =   0;                   %toggle code coverage.
vmodel_config.rchg_probability   =   0;
vmodel_config.rchg_full_mem      =   0;
vmodel_config.rchg_show_param    =   0;
vmodel_config.inputs_to_out = 0;
vmodel_config.clk_to_out = 0;

vmodel(vmodel_config);

uut=constructor;
for i=1:N
    uut.in_mem_8bit=floor(rand(1,4)*2^8);
    uut.v_24bit=floor(rand*2^24);
    uut.v_71bit(1)=floor(rand*2^32);
    uut.v_71bit(2)=floor(rand*2^32);
    uut.v_71bit(3)=floor(rand*2^7);
    in24b=uut.v_24bit;
    in71b1=uut.v_71bit(1);
    in71b2=uut.v_71bit(2);
    in71b3=uut.v_71bit(3);
    res=sim_step(uut);
    sim('no_clock_index_test_simulink',[0 0.003]);
    l=fix(uut.v_24bit/2^(16-8))+fix(uut.v_71bit(1)/2^(50-30))*2^(31-16+1);
    h=mod(uut.v_71bit(2),2^(41-(32-16+1)-(32-(50-30+1)) ))*2^(32-16+1+32-(50-30+1));
    r=l+h;
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,81,(res.v_41bit_out~=r));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,82,sum(res.out_mem_8bit~=[0 0 0 0 uut.in_mem_8bit(4:-1:1) 0 0]));   
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,83,(res.v_41bit_out~=typecast([out41b1(end) out41b2(end)],'uint64')));
end