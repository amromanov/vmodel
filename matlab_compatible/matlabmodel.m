%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A, Slaschov B
%%
%%Distributed under the GNU LGPL
%%**********************************************************************


function [] = matlabmodel(gl)
%MATLABMODEL Generator of matlab model
%   Function generates matlab model, must be called from vmodel.m

% gl is a structure, containing information about verilog model

%copying inputs to output if necessary
  if (gl.inp_to_out)   
    gl.outputs = [gl.inputs gl.outputs];
  end
  
%copying clock signals to output if necessary
  if (gl.clk_to_out)
    gl.outputs = [gl.outclks gl.outputs];
  end

%help string will be displayed when user prints "help simMyModel
  help_string = generate_help(gl);
  
%constructor is a function, creating of matlab object, representing the model 
  generate_constructor(gl, help_string);
  
%sim is a function, which used for simulation of given matlab object
  generate_sim(gl, help_string);
  
%t2f and f2t are functions which used for convertions between time and tacts  
    if(gl.clk)  %Generate only if there is clock in design
        generate_timefreq_fcn(gl);
    end
%m_cpp is interface for S-function and main cpp module
  generate_m_cpp(gl);
  
end

function [help_string] = generate_help(gl)
  %#ok<*AGROW>
  nl = [char(13) char(10)];
  
  help_string = '';
  for i = 1:size(gl.inputs, 2)
    if (matlab_filter(gl, gl.inputs{i}) == 0)
        continue;
    end
    help_string = [help_string '%%input ' get_m_name(gl.inputs{i})];
    if (gl.inputs{i}.high ~= gl.inputs{i}.low)
      help_string = [help_string, '[' int2str(gl.inputs{i}.high) ':' ...
      int2str(gl.inputs{i}.low) ']'];
    end
    mem_depth=get_mem_depth(gl.inputs{i}.name);
    if (mem_depth>0)
        help_string = [help_string '[0:' int2str(mem_depth-1) ']'];
    end
    help_string = [help_string nl];
  end
  
  for i = 1:size(gl.outputs, 2)
    if (matlab_filter(gl, gl.outputs{i}) == 0)
        continue;
    end
    help_string = [help_string '%%output ' get_m_name(gl.outputs{i})];
    if (gl.outputs{i}.high ~= gl.outputs{i}.low)
      help_string = [help_string, '[' int2str(gl.outputs{i}.high) ':' ...
      int2str(gl.outputs{i}.low) ']'];
    end
    mem_depth=get_mem_depth(gl.outputs{i}.name);
    if (mem_depth>0)
        help_string = [help_string '[' int2str(mem_depth) ']'];
    end
    help_string = [help_string nl];
  end
  

end
  
function [] = generate_constructor(gl, help_string)
  constr_string = '';
  nl = [char(13) char(10)];
    
  %assign null to all inputs, so they can be choose from matlab main file
  for i = 1:size(gl.inputs, 2)
    if (matlab_filter(gl, gl.inputs{i}) == 0)
        continue;
    end
    %if width of input < 65 then assign single value(0)
    mem_depth=get_mem_depth(gl.inputs{i}.name);
    if (gl.inputs{i}.high - gl.inputs{i}.low < 64)
        if(mem_depth>0)
          constr_string = [constr_string gl.src_file '.' ...
            get_m_name(gl.inputs{i}) '= zeros(1,' int2str(mem_depth) ');' nl];
        else
            constr_string = [constr_string gl.src_file '.' ...
                get_m_name(gl.inputs{i}) ' = 0;' nl];
        end
    else
      %if width > 64 then assing matrix
      if(mem_depth==0)  %not memory is the same as memory with 1 element
          mem_depth=1;  %from point of creating array
      end
      constr_string = [constr_string gl.src_file '.' ...
        get_m_name(gl.inputs{i}) '= zeros(' ...
        int2str(floor((gl.inputs{i}.high - gl.inputs{i}.low + 32) / 32)) ...
        ', ' int2str(mem_depth) ');' nl];
    end
  end
  if isempty(constr_string)
    constr_string = [gl.src_file ' = [];'];
  end
  %build string with content of constructor
  s = ['function[' gl.src_file '] = ' gl.constr_name '()' nl '%%' ...
  gl.src_file ' constructor' nl help_string constr_string 'end'];

%write to disk
  f = fopen([gl.output_dir gl.slash gl.constr_name '.m'], 'w');
  fwrite(f, s);
  fclose(f);
end

function [] = generate_sim(gl, help_string)

  nl = [char(13) char(10)];

  %read template from file
  f = fopen('sim_template', 'r');
  s = fscanf(f, '%c', inf);
  fclose(f); 
  
  %generate string of all inputs, like "obj.input1, obj.input2, ..."
  inputs = '';
  for i = 1:size(gl.inputs, 2)
    if (matlab_filter(gl, gl.inputs{i}) == 0)
        continue;
    end
    inputs = [inputs 'obj.' get_m_name(gl.inputs{i}) ', '];
  end
  
  %generate string of all outputs and concat, like "res.out1, res.out2 ..."
  outputs = '';
  concat_str = '';
  
  for i = 1:size(gl.outputs, 2)
    if (matlab_filter(gl, gl.outputs{i}) == 0)
        continue;
    end
    if (i > 1) 
      outputs = [outputs ', '];
      concat_str = sprintf('%s\n\t\t',concat_str);               
    end
    outputs = [outputs 'res.' get_m_name(gl.outputs{i})];
    concat_str = [concat_str 'res.' get_m_name(gl.outputs{i}) ' = [pres.' get_m_name(gl.outputs{i}) ...
                    '; res.' get_m_name(gl.outputs{i}) '];' ];    
  end
  if (gl.type > 1)
      outputs = [outputs ' time'];
  end
  
  gl64str = '';
  
  %if there is no clock, we don't need to model more, that 1 tact
  if (gl.type == 1) 
     gl64str = [gl64str nl '    n=1; %% if there is no clock, n must be 1\n'];  
  end
   
  time_recalc = '';
  if (gl.type > 1)
      time_recalc = ['time = time / (2*' num2str(gl.fpga_freq * 10^6) ');'];
  end
  
  s = strrep(s, '%modelname', gl.src_file);
  s = strrep(s, '%help_string', help_string);
  s = strrep(s, '%inputs', inputs);
  s = strrep(s, '%outputs', outputs);
  s = strrep(s, '%concat_results', concat_str);
  s = strrep(s, '%mex_name', ['m_' gl.src_file]);
  s = strrep(s, '%time_recalc', time_recalc);
  if (gl.type == 3)
    %if (gl.type == 3) we must create m-file to simulate until condition
    s2 = strrep(s, '%funcname', gl.sim_name2);
    s2 = strrep(s2, '%64arch', ['  n = -n;' nl]);
    f = fopen([gl.output_dir gl.slash gl.sim_name2 '.m'], 'w');
    fwrite(f, s2);
    fclose(f);
  end
  s = strrep(s, '%funcname', gl.sim_name);
  s = strrep(s, '%64arch', gl64str);
  
  %save all to disk
  f = fopen([gl.output_dir gl.slash gl.sim_name '.m'], 'w');
  fwrite(f, s);
  fclose(f);
end

function [] = generate_timefreq_fcn(gl)

  nl = [char(13) char(10)];

  %read template from file
  f = fopen('time_freq_template', 'r');
  s = fscanf(f, '%c', inf);
  fclose(f); 
     
  if(gl.multiclocks)
      s1=sprintf('switch clock_name\n');
      for i=1:size(gl.clocks,1);        
        s1=[s1  sprintf(['    case ''' cell2mat(gl.multi_clk_names(i)) ... 
                 '''\n        fpga_freq=' num2str(cell2mat(gl.clocks(i,2))*gl.fpga_freq*10^6) ';\n'])];
      end    
      s1=[s1  sprintf('    otherwise\n')]; 
      s1=[s1  sprintf(['        fpga_freq=' num2str(gl.fpga_freq*10^6) ';\n'])];
      s1=[s1  'end'];
      s = strrep(s, '%clock_names_case', s1);
  else
      s = strrep(s, '%clock_names_case', ['fpga_freq=' num2str(gl.fpga_freq*10^6) ';']);
  end

  
  
  s = strrep(s, '%freq', num2str(gl.fpga_freq * 10^6));

  pos = strfind(s, '==== cut here ====');
  s1 = s(1:pos-2);
  s2 = s(pos+19:size(s, 2));
  
  %save all to disk
  f = fopen([gl.output_dir gl.slash 't2f.m'], 'w');
  fwrite(f, s1);
  fclose(f); 
  
  f = fopen([gl.output_dir gl.slash 'f2t.m'], 'w');
  fwrite(f, s2);
  fclose(f);
end

function [] = generate_m_cpp(gl)
  %read template from disk
  f = fopen('data_vmodel', 'r');
  s = fscanf(f, '%c', inf);
  fclose(f);  
  
  nl = [char(13) char(10)];
  
  %initialing
  inputs_count = 0;
  outputs_count = 0;
  inputs_sizes = '';
  inputs_mem_sizes = '';
  outputs_sizes = '';
  inputs_set = '';
  outputs_set = '';
  
  %getting information about inputs, 
  %inputs_sizes string like "1, 2, 5" 1 for 32bit input, 2 for 64bit input,
  %>2 for >64bit input
  %inputs_set is string 
  for i = 1:size(gl.inputs, 2)
    if (matlab_filter(gl, gl.inputs{i}) == 0)
        continue;
    end
    if (i > 1)
      inputs_sizes = [inputs_sizes ', '];
      inputs_mem_sizes = [inputs_mem_sizes ', '];
    end
    [mem_size, clean_name]=get_mem_depth(gl.inputs{i}.name);
    if(mem_size>0)
        clean_name=[clean_name '[0]'];
        inputs_mem_sizes = [inputs_mem_sizes int2str(mem_size)];
    else
        mem_size=1;
        inputs_mem_sizes = [inputs_mem_sizes '1'];    
    end
    switch gl.inputs{i}.size
      case 1
        %parse 32-bit input
        inputs_sizes = [inputs_sizes '1'];
        inputs_set = [inputs_set '  assign_input(&' gl.inputs{i}.c_path ...
            clean_name ', sizeof(' gl.inputs{i}.c_path clean_name '), prhs[' int2str(inputs_count) ...
            '], i_sz[' int2str(inputs_count) '], i_msz[' int2str(inputs_count) '], ' int2str(mem_size) ', 0);' nl];
        inputs_count = inputs_count + 1;   
      case 2
        %parse 64-bit input
        inputs_sizes = [inputs_sizes '1'];
        inputs_set = [inputs_set '  assign_input(&' gl.inputs{i}.c_path ...
            clean_name ', sizeof(' gl.inputs{i}.c_path clean_name '), prhs[' int2str(inputs_count) ...
            '], i_sz[' int2str(inputs_count) '], i_msz[' int2str(inputs_count) '], ' int2str(mem_size) ', 0);' nl];
        inputs_count = inputs_count + 1;   
      otherwise
        input_width = floor((gl.inputs{i}.high - gl.inputs{i}.low + 32) / 32);
        inputs_sizes = [inputs_sizes int2str(input_width)];
        inputs_set = [inputs_set '  assign_input(&' gl.inputs{i}.c_path ...
            clean_name ...
            '[0], sizeof(' gl.inputs{i}.c_path clean_name '[0]), prhs[' int2str(inputs_count) ...
            '], i_sz[' int2str(inputs_count) '], i_msz[' int2str(inputs_count) '], ' int2str(input_width*mem_size) ...
            ', 1);' nl];
        inputs_count = inputs_count + 1;  
    end
  end
  
  for i = 1:size(gl.outputs, 2)
    if (matlab_filter(gl, gl.outputs{i}) == 0)
        continue;
    end
    if (i > 1)
      outputs_sizes = [outputs_sizes ', '];
    end
    current_output = gl.outputs{i};
    [mem_depth, clear_name] = get_mem_depth(current_output.name);
    if (mem_depth > 0)
      outputs_set = sprintf('%s    for(int k=0; k<%i; k++){\n', ...
          outputs_set, mem_depth);
    end
    c_name = clear_name;
    outputs_sizes = [outputs_sizes int2str(max(mem_depth, 1)) ', '];
    if (mem_depth > 0)
        c_name = [c_name '[k]'];
    end    
    switch current_output.size
      case 1
        %parse 32-bit output
        outputs_sizes = [outputs_sizes '1'];
        if (mem_depth == 0)
          outputs_set = sprintf('%s    ((puint32)_out[%i])[point_id] = %s%s;\n', ...
            outputs_set, outputs_count, current_output.c_path, c_name);
        else
          outputs_set = sprintf('%s    ((puint32)_out[%i])[k*number_of_points+point_id] = %s%s;\n', ...
            outputs_set, outputs_count, current_output.c_path, c_name);
        end
        outputs_count = outputs_count + 1;   
      case 2
        %parse 64-bit output
        outputs_sizes = [outputs_sizes '2'];
        if (mem_depth == 0)
          outputs_set = sprintf('%s    ((puint64)_out[%i])[point_id] = %s%s;\n', ...
            outputs_set, outputs_count, current_output.c_path, c_name);
        else
          outputs_set = sprintf('%s    ((puint64)_out[%i])[k*number_of_points+point_id] = %s%s;\n', ...
            outputs_set, outputs_count, current_output.c_path, c_name);
        end
       outputs_count = outputs_count + 1;   
      otherwise
        outputs_sizes = [outputs_sizes int2str(gl.outputs{i}.size)];
        if (mem_depth == 0)
          outputs_set = sprintf(['%s    for (j=0; j<%i; j++)\n' ...
            '    ((puint32)_out[%i])[j*number_of_points+point_id] = %s%s[j];\n'], ...
            outputs_set, current_output.size, outputs_count, ...
            current_output.c_path, c_name);
        else
          outputs_set = sprintf(['%s    for (j=0; j<%i; j++)\n' ...
            '    ((puint32)_out[%i])[(j+k*%i)*number_of_points+point_id] = %s%s[j];\n'], ...
            outputs_set, current_output.size, outputs_count, current_output.size, ...
            current_output.c_path, c_name);
        end
        outputs_count = outputs_count + 1;  
    end
    if (mem_depth > 0)
      outputs_set = [outputs_set '    }' nl];
    end
  end
  
  if(gl.rchg_probability>0)  %If random change probability > 0 then adding change string
    [ random_chg_set ] = generate_rchg_data( gl );
  end
   
  if (gl.type > 1)
      % output for time vector
      outputs_count = outputs_count + 1;
  end
  
  defines = ['#include "mex.h"' nl '#include "math.h"' nl ...
    gl.include ...
    '#define TOP_NAME V' gl.src_file nl ...
    '#define INPUT_COUNT ' int2str(inputs_count + 1) nl ...
    '#define OUTPUT_COUNT ' int2str(outputs_count) nl ...
    '#define CLOCK top->' gl.clk_name nl];

  if(gl.multiclocks)
     [edges, clocks, halfperiods, timevectors, jitters, clock_chg] = generate_multiclock_data(gl);
      defines = [defines '#define CLOCK_AMOUNT ' int2str(size(gl.clocks,1)) nl ...%number of clocks for multiclock
    '#define MULTICLOCK' nl];%enable multiclock mode
      if (gl.jitter_sim_on == 1)
        defines = [defines '#define JITTER_SIM' nl];
      end
  end

  if (gl.coverage)
    defines = [defines '#define CODE_COVERAGE' nl ...
                       '#include "verilated_cov.h"' nl];
  end
  if (gl.any_edge == 1)
    defines = [defines '#define ANY_EDGE' nl];
  end

  if (gl.first_point == 1)
    defines = [defines '#define FIRST_POINT' nl];
  end

  if (gl.reinterpret_floats ~= 1)
    defines = [defines '#define EXPLICIT_CAST_FLOATS' nl];
  end
  
  switch gl.type
    case 1
      defines = [defines '#define TYPE_A' nl];
    case 2
      defines = [defines '#define TYPE_B' nl ...
        '#define BREAK_CONDITION false' nl];
    otherwise
      defines = [defines '#define TYPE_C' nl ...
        '#define BREAK_CONDITION ' gl.break_condition nl];
  end
  
  if (gl.rchg_show_param)
      defines = [defines '#define RCHG_PARAMS_OUT' nl];
  end
  
  ports_info = ['  int i_sz[INPUT_COUNT] = {%inputs_sizes 1};' nl ...
    '  int i_msz[INPUT_COUNT] = {%inputs_mem_sizes 1};' nl ...  
    '  int o_sz[OUTPUT_COUNT*2] = {%outputs_sizes};' nl];
  
  %if there is no inputs (only clocks), then ',' should not be added after
  %inputs_sizes and inputs_mem_sizes strings
  if (~isempty(inputs_sizes))
    inputs_sizes=[inputs_sizes ', '];
  end
  
  if (~isempty(inputs_mem_sizes))
    inputs_mem_sizes=[inputs_mem_sizes ', '];
  end
  
  ports_info = strrep(ports_info, '%inputs_sizes', inputs_sizes);
  ports_info = strrep(ports_info, '%inputs_mem_sizes', inputs_mem_sizes);
  ports_info = strrep(ports_info, '%outputs_sizes', outputs_sizes);
  
  s = strrep(s, '%defines', defines);
  s = strrep(s, '%inputs_description', ports_info);
  s = strrep(s, '%set_inputs', inputs_set);
  s = strrep(s, '%set_outputs', outputs_set);
  s = strrep(s, '%random_seed', num2str(uint32(gl.random_seed)));
  s = strrep(s, '%r_chg_prob',  num2str(uint32(gl.rchg_probability*(2^32-1))));
  if(gl.rchg_probability>0)
      s = strrep(s, '%rnd_chg_interal', random_chg_set);
  else
      s = strrep(s, '%rnd_chg_interal', '');
  end
  s = strrep(s, '%check_break_condition', gl.break_condition);

  if(gl.multiclocks~=0)
      s = strrep(s, '%edges', edges);
      s = strrep(s, '%clocks', clocks);
      s = strrep(s, '%halfperiods', halfperiods);
      s = strrep(s, '%timevectors', timevectors);
      s = strrep(s, '%jitter_amp', jitters);
      s = strrep(s, '%clock_chg', clock_chg);
  end
    
  f = fopen([gl.src_path 'm_' gl.src_file '.cpp'], 'w');
  fwrite(f, s);
  fclose(f);

end

function [res] = get_m_name(port)
  [~, clear_name] = get_mem_depth(port.name);
  res = [port.m_path clear_name];
  res = strrep(res, '__PVT__', '');
  res = strrep(res, 'v__DOT__', '');
  res = strrep(res, '__DOT__', '.');
  res = strrep(res, '._', '.v_');       %MATLAB doesn't support variables, starting with _, so changing all ._ into .v_
  if(strcmp(res(1),'_'))                
    res=['v_',res(2:end)];
  end
end

function [res] = matlab_filter(gl, port)
    if (gl.visibility == 0) %public
        if (port.visibility < 2)
            res = 1;
        else
            res = 0;
        end
    elseif (gl.visibility == 1) %top
        if (port.visibility == 0)
            res = 1;
        else
            res = 0;
        end
    else %all
        res = 1;        
    end
end
