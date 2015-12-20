clocks=parse_clocks(vmodel_config.clocks,vmodel_config.fpga_freq*10^6);

%initialisation
cut_time=0;
res=[];
res_time=[];
res_ind=0;
put_first_point=0;
put_last_point=1;
edge_write=cell2mat(clocks(:,5));
clk_count=size(clocks,1);
clk_out=zeros(clk_count,1);        %clock state                                      
half_periods=(zeros(clk_count,1));   %clock periods
time_vector=(zeros(clk_count,1));    %edge time vector
for i=1:clk_count
   half_periods(i)=1/2/cell2mat(clocks(i,2));     %clock halfperiod
   time_vector(i)=mod(cell2mat(clocks(i,3))+half_periods(i),2*half_periods(i));      %next edge time
   
   if(mod(cell2mat(clocks(i,3)),2*half_periods(i))>=half_periods(i))          %if phase more then half period then changing clock in initial moment
       clk_out(i)=~clk_out(i);
   end  
   if cell2mat(clocks(i,4))    %if clock is shifted on 180 degree then changing clock in initial moment
       clk_out(i)=~clk_out(i);
   end    
end
%converting values to string and vice versa to make time parameters same in
%vmodel models and in this script
half_periods = str2num(num2str(half_periods'));
time_vector  = str2num(num2str(time_vector'));
%calculating point count
cur_time=0;
limit_time=21;
point_count=0;

init_time_vector=time_vector;
init_clk_out=clk_out;

if(put_first_point)
            point_count=point_count+1;
end

while cur_time < limit_time
    cur_time=time_vector(1);  %searchin min time for edge
    for i=1:clk_count
       if(cur_time>time_vector(i))
            cur_time=time_vector(i);
       end
    end
    
    if(cur_time > limit_time)   %if next edge is after time_limit then putting last point
        if (put_last_point)
            point_count=point_count+1;
        end
        break;
    end

    save_result=0;
    for i=1:clk_count         %saving result and changing time vector
       if(time_vector(i)==cur_time)
           clk_out(i)=~clk_out(i);
           if((edge_write(i)==1)&&(~clk_out(i)))||...   %negedge write  
             ((edge_write(i)==2)&&(clk_out(i))) ||...   %posedge write
              (edge_write(i)==3)                         %anyedge write
             save_result=1;
           end
           time_vector(i)=time_vector(i)+half_periods(i);
       end
    end
    point_count=point_count+save_result;
end

time_vector=init_time_vector;
clk_out=init_clk_out;

%calculating point count for 1 clk
clk_num=2;
first_point=time_vector(clk_num);
last_point=limit_time;
if (edge_write(clk_num)==3)

end

len=floor((last_point-first_point)/half_periods(clk_num));
if(first_point)
    len=len+1;
end

if (last_point && (len~=(last_point-first_point)/half_periods(clk_num)))
    len=len+1;
end

%running verilator simulation

cur_time=0;

if (put_first_point)
    res_ind=res_ind+1;
    res(res_ind,:)=clk_out';
    res_time(res_ind)=cur_time;
end

%cycle part

while cur_time < limit_time
    cur_time=time_vector(1);  %searchin min time for edge
    for i=1:clk_count
       if(cur_time>time_vector(i))
            cur_time=time_vector(i);
       end
    end
    
    if(cur_time > limit_time)   %if next edge is after time_limit then putting last point
        if (put_first_point)
            res_ind=res_ind+1;
            res(res_ind,:)=clk_out';
            res_time(res_ind)=limit_time;
        end
        break;
    end

    for i=1:clk_count         %changing clocks
       if(time_vector(i)==cur_time) 
           clk_out(i)=~clk_out(i);
       end
    end

    %running verilator simulation

    save_result=0;
    for i=1:clk_count         %saving result and changing time vector
       if(time_vector(i)==cur_time)
           if((edge_write(i)==1)&&(~clk_out(i)))||...   %negedge write  
             ((edge_write(i)==2)&&(clk_out(i))) ||...   %posedge write
              (edge_write(i)==3)                         %anyedge write
             save_result=1;
           end
           time_vector(i)=time_vector(i)+half_periods(i);
       end
    end
    if(save_result)
       res_ind=res_ind+1;
       res(res_ind,:)=clk_out;
       res_time(res_ind)=cur_time;
    end
end



