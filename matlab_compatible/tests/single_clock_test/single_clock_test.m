err_cnt=0;
err_list=[];
multiclock=0;
single_clock_pr_test;  %Testing single clock simulation in single clock mode (Errors: 200-330)
multiclock=1;
single_clock_pr_test;  %Testing single clock simulation in multiclock mode (Errors: 200-330)
single_clock_jitter_test; %Testing jitter simulation in single clock design  (Errors: 331-340);

if(err_cnt==0) %Test passed if no errors
    result=1;
    %Delete model files if test passed
    delete('constructor.m','sim_step.m','m_simple_test.*', ...
        's_simple_test.*','random_seed.txt','simple_test.mdl',...
        't2f.m','f2t.m','sim_tcond.m');
else
    result=0;
end    
    
result_info.name = 'Single clock simulation test';
result_info.error_count = err_cnt;
result_info.error_list = err_list;