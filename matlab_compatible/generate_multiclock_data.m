%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2015
%%Authors: Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

function [edges, clocks, halfperiods, timevectors, jitters, clock_chg] = generate_multiclock_data(gl) 
      nl = [char(13) char(10)];
      clk_count=size(gl.clocks,1);
      edge_transform=cell2mat(gl.clocks(:,5));
      clk_out=[];          %clock state 
      half_periods=[];    %clock periods
      time_vector=[];    %edge time vector
      jitter_amp=[];     %jitter_amp
      edge_write=[];
      clock_chg=[];
      for i=1:clk_count
        clock_chg=[clock_chg 'top->' cell2mat(gl.multi_clk_names(i)) ' = clk_out[' int2str(i-1) '];' nl];
        clkout_transform=0;
        halfper_transform=1/2/cell2mat(gl.clocks(i,2));     %clock halfperiod
        timevect_transform=mod(cell2mat(gl.clocks(i,3))+halfper_transform,2*halfper_transform);      %next edge time
        jitter_amp_transform=cell2mat(gl.clocks(i,6))/2^31;      %jitter amplitude (Dividing by 2^31, because lsfr has 32 bit output from [-1;1]
       if(mod(cell2mat(gl.clocks(i,3)),2*halfper_transform)>=halfper_transform)          %if phase more then half period then changing clock in initial moment
           clkout_transform=~clkout_transform;
       end  
       if cell2mat(gl.clocks(i,4))    %if clock is shifted on 180 degree then changing clock in initial moment
           clkout_transform=~clkout_transform;
       end 
       if(i<=(clk_count-1))
           half_periods=[half_periods num2str(halfper_transform) ','];
           time_vector=[time_vector num2str(timevect_transform) ','];
           clk_out=[clk_out num2str(clkout_transform) ','];
           edge_write=[edge_write num2str(edge_transform(i)) ','];
           jitter_amp=[jitter_amp num2str(jitter_amp_transform) ','];         
       else
           half_periods=[half_periods num2str(halfper_transform)];
           time_vector=[time_vector num2str(timevect_transform)];
           clk_out=[clk_out num2str(clkout_transform)];
           edge_write=[edge_write num2str(edge_transform(i))];
           jitter_amp=[jitter_amp num2str(jitter_amp_transform)];           
       end
      end
  
      edges = edge_write;
      clocks = clk_out;
      halfperiods = half_periods;
      timevectors = time_vector;
      jitters = jitter_amp;
end
