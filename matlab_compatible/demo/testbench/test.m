%%**********vmodel MATLAB Verilog simulator usage example***************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************

data.verilator_path = '/home/chuh/verilator/'; %Path to verilator
data.src_filename = '../cordic_mult_core.v';   %Path to verilog file

data.clk_name='clk'; %Clock signal name (by default 'clk')
data.save_cpp=0;     %Is it necessary to save mex source c++ file

data.dirlist=[];     %verilog source directory list
                     %{DirPath1,{DirPath2...DirPath3}
data.break_condition = 'top->rdy == 1'; %Breaking condition (in C++)
                                        %if set, then sim_name2 function
                                        %will appear
data.multiclock=0;
data.constr_name = 'constructor';  %simulation object constructor name
data.sim_name = 'sim_step';        %simulation function name
data.sim_name2 = 'sim_tcond';      %simulation until breaking condition name
data.coverage = 1;                 %toggle code coverage                                                    
data.output = ''; %output directory path (if '' then current directory)
vmodel(data);     %creating model
tb;
