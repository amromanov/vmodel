%Creating model
err_cnt=0;
err_list=[];

for mc=0:1
      clear data;
      data.src_filename = 'fpu_mul.v';   %Path to verilog file
      data.multiclock=mc;
      data.constr_name = 'constructor';  %simulation object constructor name
      data.signals = 'top';
      data.reinterpret_floats = 1;       %interrept floats bit-wise
      data.sim_name = 'sim_step';        %simulation function nameg condition name
      data.output = ''; %output directory path (if '' then current directory)
      vmodel(data);     %creating model

      %% Constructing and reseting 
      mult=constructor;
      mult.rst=uint8(1);
      sim_step(mult,1,1); %Simulating 1 clock period without output
      mult.rst=uint8(0); 
      sim_step(mult,1,1); %Simulating 1 clock period without output
      %% Testing
      N=1000; %Number of tests
      a=rand(N,1)*2^100-2^99; 
      b=rand(N,1)*2^100-2^99;
      r=rand(N,1)*2^100-2^99;
      mult.enable=uint16(1);
      mult.rmode=uint16(0);    
      res=sim_step(mult,1);
      %Running tests
      for i=1:1:N
        mult.opa=a(i);
        mult.opb=b(i);
        res=sim_step(mult,1,res);        
      end
      res=sim_step(mult,20,res);
end

%Matlab
[err_cnt, err_list] = add_test_res(err_cnt,err_list,800+mc*10,sum(typecast(res.outfp(22:end),'double')-a.*b)~=0);
%Simulink
sim('floating_point_simulink',[0 1]);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,801+mc*10,sum(sim_error.signals(1).values~=0));

%Simulink (repeat test without rebuilding model)
sim('floating_point_simulink',[0 2]);
[err_cnt, err_list] = add_test_res(err_cnt,err_list,801+mc*10,sum(sim_error.signals(1).values~=0));


if(err_cnt==0) %Test passed if no errors
    result=1;
    %Delete model files if test passed
    rmdir('slprj','s');
    delete('constructor.m','sim_step.m','m_fpu_mul.*', ...
        's_fpu_mul.*','fpu_mul.mdl', 't2f.m','f2t.m','floating_point_simulink_sfun.*');
else
    result=0;
end    
    
result_info.name = 'Multiclock simulation test';
result_info.error_count = err_cnt;
result_info.error_list = err_list;