%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [cov_result]=parse_vcov_line(data)
%PARSE_V_VCOV_LINE parses one line from coverage.pl (For internal use only)
%INPUTS
%data - line with raw coverage information from coverage pl
%OUTPUTS
%cov_result  - structure with coverage data, parsed from input string

    last_param=[];
    last_data=[];
    do_param=0;
    do_data=0;
    i=1;
    cov_result=[];
    if (length(data)>2)     %Checking line size
        if (strcmp(data(1),'C'))     %Checking for line start mark
            for i=2:length(data)
                if do_param
                    last_param = [last_param,data(i)];
                end
                if do_data
                    last_data = [last_data,data(i)];
                end
                if strcmp(data(i),char(1))||strcmp(data(i),'''') %Start of new param
                       do_param = 1;
                       if(do_data)  %Saving last data
                            cov_result=setfield(cov_result,last_param(1:end-1),last_data(1:end-1));
                            do_data = 0;
                       end
                       last_param = [];         
                       last_data  = [];
                end
                if strcmp(data(i),char(2)) %Start of new data
                       do_data = 1;
                       do_param = 0;
                end
                if(strcmp(data(i),char(10))||strcmp(data(i),char(13))||(i==length(data)))
                    if(strcmp(last_param(1),' '))  %cutting space before number
                        st_ind=2;
                    else
                        st_ind=1;
                    end
                    if(~(strcmp(data(i),char(10))||strcmp(data(i),char(13)))) %if last char is not NEWLINE then copy full parameter 
                        cov_result=setfield(cov_result,'count',last_param(st_ind:end));       
                    else                                             %else cut last char
                        cov_result=setfield(cov_result,'count',last_param(st_ind:end-1));        
                    end
                end
            end
        end
    end
end