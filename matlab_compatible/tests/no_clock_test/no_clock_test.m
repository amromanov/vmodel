%Test vmodel with model without clock signals
N=1000; %N - number of test points in each test

clear vmodel_config

err_cnt=0;
err_list=[];

vmodel_config.src_filename       =   'no_clock_model.v';   %source *.v file. Required.
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
vmodel_config.signals            =   'all';               %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '';                  %string with additional keys to verilator. eg '--top-module fft'
vmodel_config.coverage           =   0;                   %toggle code coverage.
vmodel_config.rchg_probability   =   0;
vmodel_config.rchg_full_mem      =   0;
vmodel_config.rchg_show_param    =   0;
vmodel_config.inputs_to_out = 1;
vmodel_config.clk_to_out = 1;

vmodel(vmodel_config);

uut=constructor;

%Checking double input data
for i=1:N
    uut.in_8bit=floor(rand*2^8);
    uut.in_24bit=floor(rand*2^24);
    uut.in_64bit=floor(rand*2^50);
    uut.in_96bit=[floor(rand*2^32); floor(rand*2^32) ; floor(rand*2^32)];
    uut.in_mem_8bit=floor(rand(1,10)*2^8);
    uut.in_mem_64bit=floor(rand(1,10)*2^50);
    uut.in_mem_78bit=[floor(rand(1,10)*2^32); floor(rand(1,10)*2^32) ; floor(rand(1,10)*2^14)];
    res=sim_step(uut,1);
    res1=sim_step(uut,1); 
    [err_cnt, err_list] = check_model_out(err_cnt,err_list,uut,res);    
end

%Checking  mixed input data
for i=1:N
    uut.in_8bit=uint8(floor(rand*2^8));
    uut.in_24bit=int32(floor(rand*2^24));
    uut.in_64bit=int64(floor(rand*2^50));
    uut.in_96bit=double([floor(rand*2^32); floor(rand*2^32) ; floor(rand*2^32)]);
    uut.in_mem_8bit=uint8(floor(rand(1,10)*2^8));
    uut.in_mem_64bit=uint64(floor(rand(1,10)*2^50));
    uut.in_mem_78bit=uint32([floor(rand(1,10)*2^32); floor(rand(1,10)*2^32) ; floor(rand(1,10)*2^14)]);
    res=sim_step(uut,1);
    [err_cnt, err_list] = check_model_out(err_cnt,err_list,uut,res);
    res1=sim_step(uut,1);  %Checking that result doesn't depend from time, only from input data 
    [err_cnt, err_list] = check_model_out(err_cnt,err_list,uut,res);
end

%Checking simulink has the same out as Matlab
for i=1:N
    uut.in_8bit=floor(rand*2^8);
    uut.in_24bit=floor(rand*2^24);
    uut.in_64bit=floor(rand*2^50);
    uut.in_96bit=[floor(rand*2^32); floor(rand*2^32) ; floor(rand*2^32)];
    in8b=uut.in_8bit;
    in24b=uut.in_24bit;
    rs=typecast(uint64(uut.in_64bit),'uint32');
    in64b1=double(rs(1));
    in64b2=double(rs(2));
    in96b1=uut.in_96bit(1);
    in96b2=uut.in_96bit(2);
    in96b3=uut.in_96bit(3);
    res=sim_step(uut,1);
    sim('no_clock_simulink',[0 0.03]);
    %Checking if matlab simulation still Ok on this data
    [err_cnt, err_list] = check_model_out(err_cnt,err_list,uut,res);    
    %Checking if simulink and matlab simulation have the same result
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,30,res.out_24bit~=out24b(end));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,31,res.out_64bit~=typecast([out64b1(end) out64b2(end)],'uint64'));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,32,sum(squeeze(res.out_96bit)~=[out96b1(end);out96b2(end);out96b3(end)]));   
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,33,res.hidden_var~=hidv(end));   
end


%Checking result size
res=sim_step(uut,1,10);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,17,sum(size(res)~=[1 1])); 


%Checking simulation till condition
clear vmodel_config

vmodel_config.src_filename       =   'no_clock_model.v';   %source *.v file. Required.
vmodel_config.no_matlab_model    =   0;                   %1 = don't make model for Matlab, default 0
vmodel_config.no_simulink_model  =   0;                   %1 = don't make model for Simulink, default 0
vmodel_config.constr_name        =   'constructor';       %name of CreateModel.m file. 'CreateModel' + model_name by default
vmodel_config.sim_name           =   'sim_step';          %name of SimModel.mex file. 'SimModel' + model_name by default
vmodel_config.fpga_freq          =   50;                  %frequency of FPGA in MHz. Default is 50 MHz.
vmodel_config.sample_time        =   0.001;               %sample time in Simulink S-fcn. Default 0.001
vmodel_config.output             =   '';                  %output directory. Default 'm_' + model_name.
vmodel_config.reinterpret_floats =   1;                   %1 = floats are reinterpreted as unsigned integers (bitwise)
vmodel_config.first_point        =   1;                   %1 = add to output vector ititial point while modeling, default 0
vmodel_config.any_edge           =   1;                   %1 = output data on every clock change, 0 - only on posedge, default 0
vmodel_config.signals            =   'all';               %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '';                  %string with additional keys to verilator. eg '--top-module fft'
vmodel_config.coverage           =   0;                   %toggle code coverage.
vmodel_config.rchg_probability   =   0;
vmodel_config.rchg_full_mem      =   0;
vmodel_config.rchg_show_param    =   0;
vmodel_config.break_condition   =   'true';              %string containing condition written in C. For example: 'top->rdy == 1';
vmodel_config.sim_name2         =   'sim_tcond';         %name of SimModelTillCondition.mex file. 'SimModelTillSignal' + model_name by default
%Building model with vmodel
vmodel_config.inputs_to_out = 1;
vmodel_config.clk_to_out = 0;

vmodel(vmodel_config);

%"Simulation till conditions" function shall not be created if there is no
%clock
[err_cnt, err_list] = add_test_res(err_cnt,err_list,20,exist('sim_tcond.m','file')); 

%Checking mixed type input data with reinterpret_floats=1
for i=1:N
    uut.in_8bit=uint8(floor(rand*2^8));
    uut.in_24bit=int32(floor(rand*2^24));
    uut.in_64bit=single(rand*2^50);
    uut.in_96bit=single([floor(rand*2^32); floor(rand*2^32) ; floor(rand*2^32)]);  %if size>64 bit, then type cast is always applied
    uut.in_mem_8bit=uint8(floor(rand(1,10)*2^8));
    uut.in_mem_64bit=uint64(floor(rand(1,10)*2^50));
    uut.in_mem_78bit=uint32([floor(rand(1,10)*2^32); floor(rand(1,10)*2^32) ; floor(rand(1,10)*2^14)]);
    res=sim_step(uut,1);
    uut.in_64bit=typecast(uut.in_64bit,'uint32');
    [err_cnt, err_list] = check_model_out(err_cnt,err_list,uut,res);
end


%Checking simulink has the same out as Matlab with reinterpret_floats=1
%reinterpret_floats=1 shall not affect on simulink
for i=1:N
    uut.in_8bit=uint8(floor(rand*2^8));
    uut.in_24bit=int32(floor(rand*2^24));
    uut.in_64bit=single(rand*2^50);
    uut.in_96bit=single([floor(rand*2^32); floor(rand*2^32) ; floor(rand*2^32)]);  %if size>64 bit, then type cast is always applied
    in8b=double(uut.in_8bit);
    in24b=double(uut.in_24bit);
    in64b1=double(typecast(uut.in_64bit,'uint32'));
    in64b2=0;
    in96b1=double(typecast(uut.in_96bit(1),'uint32'));
    in96b2=double(typecast(uut.in_96bit(2),'uint32'));
    in96b3=double(typecast(uut.in_96bit(3),'uint32'));
    res=sim_step(uut,1);
    uut.in_64bit=typecast(uut.in_64bit,'uint32');
    sim('no_clock_simulink',[0 0.03]);
    %Checking if matlab simulation still Ok on this data
    [err_cnt, err_list] = check_model_out(err_cnt,err_list,uut,res);    
    %Checking if simulink and matlab simulation have the same result
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,40,res.out_24bit~=out24b(end));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,41,res.out_64bit~=typecast([out64b1(end) out64b2(end)],'uint64'));
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,42,sum(squeeze(res.out_96bit)~=[out96b1(end);out96b2(end);out96b3(end)]));   
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,43,res.hidden_var~=hidv(end));   
end

%Checking result size
res=sim_step(uut,1,10);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,21,sum(size(res)~=[1 1])); 


%Checking model i/o visibility settings
[err_cnt, err_list] = add_test_res(err_cnt,err_list,22,~isfield(res,'hidden_mem_data')); 

vmodel_config.signals            =   'top';               %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel(vmodel_config);
res=sim_step(uut,1);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,23,isfield(res,'hidden_mem')); 
[err_cnt, err_list] = add_test_res(err_cnt,err_list,23,isfield(res,'hidden_var'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,23,isfield(res,'hidden_mem_data')); 
[err_cnt, err_list] = add_test_res(err_cnt,err_list,23,isfield(res,'huge_hidden_mem')); 

vmodel_config.signals            =   'public';               %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel(vmodel_config);
res=sim_step(uut,1);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,19,isfield(res,'hidden_mem_data')); 

%Interal random change test
%Testing with partial memory change
clear vmodel_config

vmodel_config.src_filename       =   'no_clock_model.v';   %source *.v file. Required.
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
vmodel_config.signals            =   'all';               %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '';                  %string with additional keys to verilator. eg '--top-module fft'
vmodel_config.coverage           =   0;                   %toggle code coverage.
vmodel_config.rchg_probability   =   1;                   %Always change signals
vmodel_config.rchg_full_mem      =   0;
vmodel_config.rchg_show_param    =   1;
vmodel_config.inputs_to_out = 1;
vmodel_config.clk_to_out = 0;
vmodel(vmodel_config);

clear uut;
rchg_cnt = 0;
rchg_list = [];
uut=constructor;
for i=1:N
    uut.in_8bit=floor(rand*2^8);
    res=sim_step(uut,1);
    [rchg_cnt rchg_list] = check_model_out(rchg_cnt,rchg_list,uut,res);
    [rchg_cnt rchg_list] = add_test_res(rchg_cnt,rchg_list,17,res.hidden_mem_data~=0);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,51,length(find(res.hidden_mem))~=1);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,52,length(find(res.huge_hidden_mem))~=4);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,53,sum(sum(squeeze(res.huge_hidden_mem)>=repmat([2^32; 2^32; 2^32; 2^5],1,6)))); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,54,sum(squeeze(res.hidden_mem)>=(ones(1,10).*2^2))); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,55,res.hidden_mem_data>=2^8); 
end
    [err_cnt err_list] = add_test_res(err_cnt,err_list,56,res.rchg_count~=res.rchg_total);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,57,res.rchg_count~=rchg_cnt); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,58,~isempty([find(rchg_list<14); find(rchg_list>17)])); 

%Testing with full memory change
vmodel_config.rchg_full_mem      =   1;
vmodel(vmodel_config);

clear uut;
rchg_cnt = 0;
rchg_list = [];
uut=constructor;
for i=1:N
    uut.in_8bit=floor(rand*2^8);
    res=sim_step(uut,1);
    [rchg_cnt rchg_list] = check_model_out(rchg_cnt,rchg_list,uut,res);
    [rchg_cnt rchg_list] = add_test_res(rchg_cnt,rchg_list,17,res.hidden_mem_data~=0);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,61,length(find(res.hidden_mem))~=10);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,62,length(find(res.huge_hidden_mem))~=24);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,63,sum(sum(squeeze(res.huge_hidden_mem)>=repmat([2^32; 2^32; 2^32; 2^5],1,6)))); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,64,sum(squeeze(res.hidden_mem)>=(ones(1,10).*2^2))); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,65,res.hidden_mem_data>=2^8); 
end
    [err_cnt err_list] = add_test_res(err_cnt,err_list,66,res.rchg_count~=res.rchg_total);   
    [err_cnt err_list] = add_test_res(err_cnt,err_list,67,res.rchg_count~=rchg_cnt); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,68,~isempty([find(rchg_list<14); find(rchg_list>17)])); 
    
%Testing change probability and simulink
vmodel_config.rchg_probability   =   0.25;      %Change every 10th signa;
vmodel_config.rchg_full_mem      =   1;
vmodel_config.rchg_show_param    =   0;
vmodel(vmodel_config);

%Checking there is no fields disabled by rchg_show_param
res=sim_step(uut,1);
[err_cnt err_list] = add_test_res(err_cnt,err_list,70,isfield(res,'rchg_count')); 
[err_cnt err_list] = add_test_res(err_cnt,err_list,71,isfield(res,'rchg_total')); 

p=[];
for i=1:N
    uut.in_8bit=floor(rand*2^8);
    in8b=double(uut.in_8bit);
    %Checking for probability on huge hidden mem
    prob=0;
    for j=1:100
        res=sim_step(uut,1);
        prob=prob+length(find(res.huge_hidden_mem))/24/100;
    end
    %probability may vary not more then 20%
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,72,(prob<vmodel_config.rchg_probability*0.8)+(prob>vmodel_config.rchg_probability*1.2));
    %checking that random change has correct range
    [err_cnt err_list] = add_test_res(err_cnt,err_list,73,sum(sum(squeeze(res.huge_hidden_mem)>=repmat([2^32; 2^32; 2^32; 2^5],1,6)))); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,74,sum(squeeze(res.hidden_mem)>=(ones(1,10).*2^2))); 
    [err_cnt err_list] = add_test_res(err_cnt,err_list,75,res.hidden_mem_data>=2^8); 
    sim('no_clock_simulink',[0 1]);
    prob_s=sum(hidv~=mod(in8b+1,2))/length(hidv);
    %probability may vary not more then 20%
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,76,(prob<vmodel_config.rchg_probability*0.8)+(prob>vmodel_config.rchg_probability*1.2));
    %checking that random change has correct range
    [err_cnt err_list] = add_test_res(err_cnt,err_list,77,sum(hidv>1)); 
end

%testing work with memory and inputs, which indices don't start from 0
no_clock_index_test;
if(err_cnt==0) %Test passed if no errors
    result=1;
    %Delete model files if test passed
    delete('constructor.m','sim_step.m','m_no_clock_model.*', ...
        's_no_clock_model.*','random_seed.txt','no_clock_model.mdl',...
        'no_clock_index_test_model.mdl','s_no_clock_index_test_model.*',...
        'm_no_clock_index_test_model.*');
else
    result=0;
end    
    
result_info.name = 'Simulation without clock';
result_info.error_count = err_cnt;
result_info.error_list=err_list;


