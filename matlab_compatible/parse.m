%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************


function [gl] = parse(gl, level, ctop_name, mtop_name, fName)
%PARSE Summary of this function goes here
%   Detailed explanation goes here

  nl = [char(13) char(10)];

  %read source file
  handle = fopen([gl.src_path 'obj_dir' gl.slash fName]);
  s = fscanf(handle, '%c', inf);
  fclose(handle);
  
  expr = '\/\/ CELLS(?<cells>.*)\/\/ PORTS(?<ports>.*)\/\/ LOCAL VARIABLES';
  fVars = regexp(s, expr, 'names');
  %fVars.cells = CELLS section; fVars.ports = PORTS and LOCAL SIGNALS section;

  %split CELLS section, in this section there are names of included files
  expr = '\n+\s*(?<c>[^\/;]+);';
  cells = regexp(fVars.cells, expr, 'names');

  %split PORTS section, here there is information about
  %inputs/outputs/signals
  expr = '\n+\s*VL_{1}(?<t>\S[^\(]+)\((?<p>.[^\)]+)';
  ports = regexp(fVars.ports, expr, 'names');
  
  %%
  gl.include = [gl.include '#include "obj_dir' gl.slash fName '"' nl];

  for i=1:size(ports, 2)
    %data.n = signal_name, data.a = high dimension, data.b = low dimension
    expr = '(?<n>[^,]+),+(?<a>[^,]+),+(?<b>[^,]+),*(?<c>[^,]*)';
    data = regexp(ports(i).p, expr, 'names');
    
    %skip clock signal
    if(gl.multiclocks)                  %Multi clock mode
        clk_found=0;
        for clk_i=1:length(gl.multi_clk_names)
            if (strcmp(data.n, gl.multi_clk_names(clk_i)) && ...
                (strcmp(ports(i).t, 'IN8') || ...
                strcmp(ports(i).t, 'IN16') || ...
                strcmp(ports(i).t, 'IN') ))
              gl.clk = true;
              clk_found=1;
              break;
            end
        end
    else                                %Single clock mode
        clk_found=0;
        if (strcmp(data.n, gl.clk_name) && ...
            (strcmp(ports(i).t, 'IN8') || ...
            strcmp(ports(i).t, 'IN16') || ...
            strcmp(ports(i).t, 'IN') ))
          gl.clk = true;
          clk_found=1;
        end
    end

    if(clk_found&&(~gl.clk_to_out))       %if clock found then continue
        continue;
    end        
    
    %skip clock_enable signal
    if (strcmp(data.n, gl.clk_enable_name) && ...
        (strcmp(ports(i).t, 'IN8') || ...
        strcmp(ports(i).t, 'IN16') || ...
        strcmp(ports(i).t, 'IN') ))
      gl.clk_enable = true;
      continue;
    end
    
    %skip reset signal
    if (strcmp(data.n, gl.rst_name) && ...
        (strcmp(ports(i).t, 'IN8') || ...
        strcmp(ports(i).t, 'IN16') || ...
        strcmp(ports(i).t, 'IN') ))
      gl.rst = true;
      continue;
    end
    
    switch ports(i).t;
      case {'IN8', 'IN16', 'IN', 'IN64', 'INW'}
        wire_type = 0;
       case {'OUT8', 'OUT16', 'OUT', 'OUT64', 'OUTW'}
        wire_type = 1;
       case {'SIG8', 'SIG16', 'SIG', 'SIG64', 'SIGW'}
        wire_type = 2;
      otherwise
        continue;
    end
    
    if(clk_found)       %if get here with clk_found=1 then clocks should be copied to 
        wire_type=-1;   %clocks array
    end        
    

    %all inputs and outputs like top->v->my_input are ingored because 
    %they are copies of top->my_input
    if ((wire_type < 2) && (level == 2))
      continue;
    end
    
    %skip all inputs in submodules
    if ((wire_type == 0) && (level > 1))
      continue;
    end

    if (level > 2)
        signal_level = level - 1;
    else
        signal_level = 1;
    end
    signal_level = signal_level + size(strfind(data.n, '__DOT__'), 2);
    
    %check for visibility. There is 3 types: global(only in main module),
    %local (local variables in all modules) and verilator_public (local
    %variables, declared as public by /*verilator public*/
    %global = 0, verilator public = 1, local = 2
    visibility = 0;
    if (size(data.n, 2) > 7)
      if (strcmp(data.n(1:7), '__PVT__'))  %Public variables never have names with __PVT__
        visibility = 2;
      end
      if (strcmp(data.n(1:7), 'v__DOT_'))  %Public variables never have names with v__DOT__
        visibility = 2;
        signal_level = signal_level - 1;
      end
    end
    %verilator public signals are declared as SIG, but don't have __PVT__ prefix
    if (visibility == 0)
        if (wire_type == 2)
            visibility = 1;
        end
    end
    
    % 1 if signal marked as verilator_public
    port_info.visibility = visibility;
    %port type -1 - clock, 0 - input, 1 - output, 2 - signal
    port_info.type = wire_type;  
    % nesting level
    port_info.level = signal_level;
    port_info.name = data.n;
    % low and high dimension, eg sig[10:3] has low = 3, high = 10
    port_info.high = str2double(data.a);
    port_info.low = str2double(data.b);
    % size in 32-bit words
    port_info.size = floor((port_info.high - port_info.low + 32) / 32);
    % path for cpp file, eg top->mem->
    port_info.c_path = ctop_name;
    port_info.m_path = mtop_name;

    if (wire_type == 0) 
      gl.inputs = [gl.inputs port_info];
    else
      if (wire_type == -1)
          gl.outclks = [gl.outclks port_info];
      else
          gl.outputs = [gl.outputs port_info];
      end
    end
  end
  %%
  
  %parse included files
  for i=1:size(cells, 2)
    expr = '(?<a>.*)\*\s{1}(?<b>.*)';
    cls = regexp(cells(i).c, expr, 'names');
    
    if (level == 1)
      gl = parse(gl, level+1, [ctop_name cls.b '->'], mtop_name, ...
        [cls.a '.h']);
    else
      gl = parse(gl, level+1, [ctop_name cls.b '->'], ...
        [mtop_name cls.b '.'] , [cls.a '.h']);  
    end
  end

  %Adding rchg data to outputs
  if (level==1)                     %Adding outputs only on first call of parse
      if (gl.rchg_show_param)
        % 1 if signal marked as verilator_public
        port_info.visibility = 0;
        %port type -1 - clock, 0 - input, 1 - output, 2 - signal
        port_info.type = 1;  
        % nesting level
        port_info.level = 1;
        port_info.name = 'rchg_total';
        % low and high dimension, eg sig[10:3] has low = 3, high = 10
        port_info.high = 31;
        port_info.low = 0;
        % size in 32-bit words
        port_info.size = 1;
        % path for cpp file, eg top->mem->
        port_info.c_path = '';
        port_info.m_path = '';
        gl.outputs = [gl.outputs port_info];
        port_info.name = 'rchg_count';
        gl.outputs = [gl.outputs port_info];
      end
  end
end

