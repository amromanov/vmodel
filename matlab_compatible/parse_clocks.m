%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2014
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************
function [ clocks_arr ] = parse_clocks( clocks, fpga_clock )

if(isstruct(clocks))
    clock_names=fieldnames(clocks);     %Getting clock names
    cl=length(clock_names);             %Getting number of clocks
    clocks_arr=cell(cl,6);              %Creating empty array

    for i=1:1:cl                        %Parsing each clock
        cur_clock=clocks.(cell2mat(clock_names(i)));  
        clocks_arr(i,1)=clock_names(i);
        if(isfield(cur_clock,'freq'))   
            clocks_arr(i,2)={cur_clock.freq/fpga_clock};  %Frequency
        else
           clocks_arr(i,2)={1}; 
        end
        if(isfield(cur_clock,'shift'))
            clocks_arr(i,3)={cur_clock.shift*fpga_clock}; %Clock shift
        else
           clocks_arr(i,3)={0}; 
        end
        if(isfield(cur_clock,'shift180'))               %Add 180 degree phase shift
            clocks_arr(i,4)={cur_clock.shift180};  
        else
           clocks_arr(i,4)={0}; 
        end        
        if(isfield(cur_clock,'result'))         %When save result
            if(ischar(cur_clock.result))
                switch (cur_clock.result)
                    case 'none'
                        cur_clock.result=0;
                    case 'negedge'
                        cur_clock.result=1;
                    case 'posedge'
                        cur_clock.result=2;
                    case 'anyedge'
                        cur_clock.result=3;
                    case 'no'
                        cur_clock.result=0;
                    case 'neg'
                        cur_clock.result=1;
                    case 'pos'
                        cur_clock.result=2;
                    case 'any'
                        cur_clock.result=3;
                    otherwise
                        cur_clock.result=0;
                end
            end
            clocks_arr(i,5)={cur_clock.result};  
        else
           clocks_arr(i,5)={2};            %Default setting is posedge    
        end
      
        if(isfield(cur_clock,'jitter'))       %Clock jitter
            clocks_arr{i,6}=cur_clock.jitter*fpga_clock;  
           if(cell2mat(clocks_arr(i,6))>=(1/2/cell2mat(clocks_arr(i,2))))  %if jitter amp equel or greater then half of period then it will be rounded to 0.99 of half of period
                clocks_arr{i,6}=(1/2/cell2mat(clocks_arr(i,2)))*0.99;
                fprintf(['Warning: clock ' clocks_arr{i,1} ...
                  ' jitter is higher then half of period. Forced to ' num2str(clocks_arr{i,6}/fpga_clock) ' s.\n']);
            end
        else
            clocks_arr(i,6)={0}; 
        end                
    end
else
    clocks_arr=[];
end
