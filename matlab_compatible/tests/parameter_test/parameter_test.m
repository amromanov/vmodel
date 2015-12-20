%Creating model
err_cnt=0;
err_list=[];
N=1000;

if(exist('model_data','dir'))
    clear functions
    rmdir('model_data','s');
end

%No clock model
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'

vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,100,exist('mainmodule/m_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,100,exist('mainmodule/s_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,100,exist('mainmodule/obj_dir','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,101,~exist('model_data','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,102,~exist('model_data/CreateModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,103,~exist('model_data/SimModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,104,~exist(['model_data/m_parameter_model.' mexext],'file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,105,exist('model_data/SimModelTillSignalparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,106,exist('model_data/f2t.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,107,exist('model_data/t2f.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,108,~exist('model_data/parameter_model.mdl','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,109,~exist(['model_data/s_parameter_model.' mexext],'file'));

clear functions
rmdir('model_data','s');

%Clock model
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.clk_name           =   'a';                              %name of clock signal. default 'clk'
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'

vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,110,exist('mainmodule/m_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,110,exist('mainmodule/s_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,110,exist('mainmodule/obj_dir','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,111,~exist('model_data','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,112,~exist('model_data/CreateModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,113,~exist('model_data/SimModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,114,~exist(['model_data/m_parameter_model.' mexext],'file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,115,exist('model_data/SimModelTillSignalparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,116,~exist('model_data/f2t.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,117,~exist('model_data/t2f.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,118,~exist('model_data/parameter_model.mdl','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,119,~exist(['model_data/s_parameter_model.' mexext],'file'));

clear functions
rmdir('model_data','s');

%Clock model with breaking condition simulation
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.clk_name           =   'a';                              %name of clock signal. default 'clk'
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.break_condition    =   'top->c==1';                      %Breaking condition
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'

vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,120,exist('mainmodule/m_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,120,exist('mainmodule/s_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,120,exist('mainmodule/obj_dir','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,121,~exist('model_data','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,122,~exist('model_data/CreateModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,123,~exist('model_data/SimModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,124,~exist(['model_data/m_parameter_model.' mexext],'file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,125,~exist('model_data/SimModelTillSignalparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,126,~exist('model_data/f2t.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,127,~exist('model_data/t2f.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,128,~exist('model_data/parameter_model.mdl','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,129,~exist(['model_data/s_parameter_model.' mexext],'file'));

clear functions
rmdir('model_data','s');

%Clock model with breaking condition simulation and no matlab model
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.clk_name           =   'a';                              %name of clock signal. default 'clk'
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.break_condition    =   'top->c==1';                      %Breaking condition
vmodel_config.no_matlab_model    =   1;                                %Do not create matlab model
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'

vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,130,exist('mainmodule/m_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,130,exist('mainmodule/s_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,130,exist('mainmodule/obj_dir','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,131,~exist('model_data','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,132,exist('model_data/CreateModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,133,exist('model_data/SimModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,134,exist(['model_data/m_parameter_model.' mexext],'file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,135,exist('model_data/SimModelTillSignalparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,136,exist('model_data/f2t.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,137,exist('model_data/t2f.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,138,~exist('model_data/parameter_model.mdl','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,139,~exist(['model_data/s_parameter_model.' mexext],'file'));

clear functions
rmdir('model_data','s');

%Clock model with breaking condition simulation and no simulink model
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.clk_name           =   'a';                              %name of clock signal. default 'clk'
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.break_condition    =   'top->c==1';                      %Breaking condition
vmodel_config.no_simulink_model  =   1;                                %Do not create simulink model
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'

vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,141,~exist('model_data','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,142,~exist('model_data/CreateModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,143,~exist('model_data/SimModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,144,~exist(['model_data/m_parameter_model.' mexext],'file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,145,~exist('model_data/SimModelTillSignalparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,146,~exist('model_data/f2t.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,147,~exist('model_data/t2f.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,148,exist('model_data/parameter_model.mdl','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,149,exist(['model_data/s_parameter_model.' mexext],'file'));

clear functions
rmdir('model_data','s');

%No model
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.clk_name           =   'a';                              %name of clock signal. default 'clk'
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.break_condition    =   'top->c==1';                      %Breaking condition
vmodel_config.no_simulink_model  =   1;                                %Do not create simulink model
vmodel_config.no_matlab_model    =   1;                                %Do not create matlab model
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'

vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,151,~exist('model_data','dir'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,152,exist('model_data/CreateModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,153,exist('model_data/SimModelparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,154,exist(['model_data/m_parameter_model.' mexext],'file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,155,exist('model_data/SimModelTillSignalparameter_model.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,156,exist('model_data/f2t.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,157,exist('model_data/t2f.m','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,158,exist('model_data/parameter_model.mdl','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,159,exist(['model_data/s_parameter_model.' mexext],'file'));

clear functions
rmdir('model_data','s');

%Saving cpp files
clear  vmodel_config;
vmodel_config.dirlist            =   {'../submodule/'};                %path to submodules from top
vmodel_config.src_filename       =   'mainmodule/parameter_model.v';   %source *.v file. Required.
vmodel_config.output             =   'model_data';                     %output directory. Default 'm_' + model_name.
vmodel_config.signals            =   'all';                            %'all' - all visible, 'top' - only top module signals, 'public' - verilator public and top module
vmodel_config.verilator_keys     =   '--top-module parameter_model';   %string with additional keys to verilator. eg '--top-module fft'
vmodel_config.save_cpp           =   1;                                %saving cpp files
vmodel(vmodel_config);

[err_cnt, err_list] = add_test_res(err_cnt,err_list,161,~exist('mainmodule/m_parameter_model.cpp','file'));
[err_cnt, err_list] = add_test_res(err_cnt,err_list,162,~exist('mainmodule/s_parameter_model.cpp','file'));

clear functions
rmdir('model_data','s');

%Saving verilation results
vmodel_config.debug_mode         =   1;                                %saving verilation result
vmodel(vmodel_config);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,163,~exist('mainmodule/obj_dir','dir'));

%finally checking if compiled model work correctly
addpath('model_data');
uut=CreateModelparameter_model;
for i=1:N
    uut.a=uint16(round(rand));
    uut.b=uint16(round(rand));
    res=SimModelparameter_model(uut);    
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,170,res.c~=bitxor(uut.a,uut.b));   
end
rmpath('model_data');

clear functions
rmdir('model_data','s');
rmdir('mainmodule/obj_dir','s');
delete('mainmodule/m_parameter_model.cpp','mainmodule/s_parameter_model.cpp');

if(err_cnt==0) %Test passed if no errors
    result=1;
else
    result=0;
end    
    
result_info.name = 'Configuration parameters test';
result_info.error_count = err_cnt;
result_info.error_list=err_list;
