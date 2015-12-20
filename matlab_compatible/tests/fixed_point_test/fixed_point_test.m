%Creating model
err_cnt=0;
err_list=[];
clear data

for mc=0:1
    for BitWidth=10:16
      params.N=BitWidth;
      insert_with_params('fp_test.v','fp_test_params.v',params);
      data.src_filename = 'fp_test_params.v';   %Path to verilog file
      data.break_condition = 'top->rdy == 1'; %Breaking condition (in C++)
                                              %if set, then sim_name2 function
                                              %will appear
      data.multiclock=mc;
      data.constr_name = 'constructor';  %simulation object constructor name
      data.signals = 'top';
      data.sim_name = 'sim_step';        %simulation function name
      data.sim_name2 = 'sim_tcond';      %simulation until breaking condition name
      data.output = ''; %output directory path (if '' then current directory)
      vmodel(data);     %creating model

        %% Constructing and reseting 
        mult=constructor;
        mult.rst=1;
        sim_step(mult,1,1); %Simulating 1 clock period without output
        mult.rst=0; 
        sim_step(mult,1,1); %Simulating 1 clock period without output
        %% Testing
        N=1000; %Number of tests
        a=zeros(N,1); 
        b=zeros(N,1);
        s=zeros(N,1);
        r=zeros(N,1);

        %Running tests
        for i=1:1:N
            mult.start=1; %Setting start strob 
            mult.a=floor(rand*(2^(BitWidth)-1)); 
            mult.b=floor(rand*(2^(BitWidth)-1));
            sim_step(mult,1,1); %Simulating 1 clock period without output
            res=sim_tcond(mult,32,0); %simulating until breaking condition (top->rdy == 1)
                                        %or until 5000 clock periods
            if mult.a>=(2^(BitWidth-1)) %Converting to signed
                a(i)=mult.a-2^BitWidth;
            else
                a(i)=mult.a;    
            end

            if mult.b>=(2^(BitWidth-1)) %Converting to signed
                b(i)=mult.b-2^BitWidth;
            else
                b(i)=mult.b;    
            end

            if res.c>=(2^(BitWidth-1)) %Converting to signed
                r(i)=double(res.c)-2^BitWidth;
            else
                r(i)=double(res.c);    
            end
        end
    end
    %Cordic multiplier has error no more then 4 LSB
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,400+100*mc+BitWidth,sum(r-fix(a.*b/(2^(BitWidth-1)))>2^4));
    %Simulink
    sim('fp_simulink_model.mdl',[0 1]);
    [err_cnt, err_list] = add_test_res(err_cnt,err_list,600+100*mc+BitWidth,sum(sim_error.signals(1).values>2^4));
end

if(err_cnt==0) %Test passed if no errors
    result=1;
    %Delete model files if test passed
    delete('constructor.m','sim_step.m','m_fp_test_params.*', ...
        's_fp_test_params.*','fp_test_params.mdl',...
        'fp_test_params.v','t2f.m','f2t.m','sim_tcond.m');
else
    result=0;
end    
    
result_info.name = 'Fixed-point math test';
result_info.error_count = err_cnt;
result_info.error_list = err_list;

