%%install(verilator_path, do_cygwin);
%%run_vmodel_tests - Self-test for vmodel
%%Test duration is approx. 12 min
%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

if(isunix)  %Define path delimiter depending on OS
    dir_slash='/';
else
    dir_slash='\';
end

tests_dir=pwd;  %Locating tests directory
vmodel_dir=pwd; 

if(tests_dir(end)~=dir_slash)
    tests_dir=[tests_dir dir_slash];
end

tests_dir=[tests_dir 'tests'];


addpath(tests_dir); %Adding path of add_test_res.m to path
dirlist=dir(tests_dir);

rinfo=[];   %Structure with results
result_info=[];
tic
for ind=1:size(dirlist,1) %Serching for directories with tests
    if (strcmp(dirlist(ind).name,'.')||strcmp(dirlist(ind).name,'..')||(~dirlist(ind).isdir))      %Skip if not valid directory
        continue;
    end
    try
        cd([tests_dir dir_slash dirlist(ind).name]); %Change dir and run there script with directory name
        run(dirlist(ind).name);
    catch err
        result = 0;
        result_info.name=['Test in directory ' dirlist(ind).name];
        result_info.error_count=1;
        result_info.error_list=-1;
    end
    rinfo=[rinfo; result_info]; %Adding test result
    cd(tests_dir);
    if(result==0)  %if test failed then break
        break;
    end    
end
t=toc;
fprintf('\nVmodel toolbox self-test report\n'); 
fprintf('-------------------------------\n'); 

failed=0;
for ind=1:size(rinfo)
   if(rinfo(ind).error_count==0)
       passed='passed';
   else
       passed='failed';
       failed=1;
   end
   fprintf('%s - %s\n',rinfo(ind).name, passed); 
end
fprintf('\n');
if(failed)
    fprintf('See result_info structure for details\n'); 
end
fprintf('Test duration: %f s\n',t); 
result_info=rinfo;
rmpath(tests_dir); %removing path of add_test_res.m to leave everything as it was before
cd(vmodel_dir);