%% vmodel MATLAB Verilog simulator
% Usage: vmodel(data)
% fields of structure 'data':
% .src_filename:        source *.v file. Required.
% .no_matlab_model:     1 = don't make model for Matlab, default 0
% .no_simulink_model:   1 = don't make model for Simulink, default 0
% .verilator_path:      path to 'verilator_bin'. Used only if $verilator_path is not defined.
% .break_condition:     string containing condition written in C. default 'true'
% .clk_name:            name of clock signal. default 'clk'
% .save_cpp:            1 = don't remove temporatory cpp file, default 0
% .debug_mode           1 = don't remove any cpp files (including verilator results), default 0 
% .dirlist:             list of included directories. Empty by default
% .constr_name:         name of CreateModel.m file. 'CreateModel' + model_name by default
% .sim_name:            name of SimModel.mex file. 'SimModel' + model_name by default
% .sim_name2:           name of SimModelTillCondition.mex file. 'SimModelTillSignal' + model_name by default
% .fpga_freq:           frequency of FPGA main clk in MHz. Default is 50 MHz.
% .sample_time:         Sample time in Simulink S-fcn. Default 0.001
% .output:              output directory. Default 'm_' + model_name.
% .reinterpret_floats:  1 = floats are reinterpreted as unsigned integers (bitwise)   
% .first_point:         1 = add to output vector ititial point while modeling, default 0
% .any_edge:            1 = output data on every clock change, 0 - only on posedge, default 0
% .signals:             'all' - all visible, 'top' - only top module signals, 'public' - verilator putlic and top module
% .verilator_keys:      string with additional keys to verilator. e.g. '--top-module fft'
% .coverage:            1 = switch on code coverage analysis, default 0.
% .coverage_keys:       string with code coverage keys to verilator, default '--coverage'
% .clk_to_out:          1 = copy clock signals to simulation results (in MATLAB model), default 0 
% .inputs_to_out:       1 = copy input signals to simulation results (in MATLAB model), default 0
% .multiclock:          1 = switch on multiclock mode. In this mode, clocks are defined with .clocks parameter, default 0 
% .clocks:              clock discription structure, used in multiclock mode
%                       should consist of fields with same names as sys                       clocks. Each field of clocks structure should be also structure
%                       with clock signal parameter 'freq', 'shift', 'shift180', 'result'
%                       E.g. for clock signal with name 'clk' clocks should be defined as                       
%                       clocks.clk.freq     = frequency [Hz]
%                                 .shift    = phase shift in [s]
%                                 .shift180 = if 1 add shift to half of clock period
%                                 .result   = 'none' or 'no'       - do not save result on this clock
%                                             'negedge' or 'neg'   - save result on negative edge of this clock
%                                             'posedge' or 'pos'   - save result on positive edge of this clock
%                                             'anyedge' or 'any'   - save result on anyedge of this clock
%                                 .jitter   = clock jitter in [s]
%                       If not defined, clocks will be initialized with
%                       single clock with name from .clk_name parameter,
%                       frequency .clk_freq parameter with no phase shift
%                       and saving result as set by any_edge parameter
% .random_seed:         positive 32-bit integer random seed (by default, based on build time)
% .rchg_probability:    probability of interal variable change
% .rchg_full_mem:       1 = interal variable change changes all memory data, 0 = interal variable change changes random data on address
% .rchg_show_param:     add interal variable change parameters to model output
%%*********************vmodel MATLAB Verilog simulator******************
%%Version 0.9.6
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A, Slaschov B 
%%- 
%%Distributed under the GNU LGPL
%%**********************************************************************
function [res] = vmodel(args)

  %free s-function files for Matlab2011 and later
  %clear functions
  
  %parsing input arguments and filling gl structure
  gl = parseArgs(args);
  
  %removing all temporary files
  if exist([gl.src_path 'obj_dir'], 'dir')
  	rmdir([gl.src_path 'obj_dir'],'s');  %For WIN32 capability
  end

  %Verilating
  fprintf 'verilating...\n';
  
  %In UNIX systems changing library path from matlab to OS    
  if(~ispc)
    setenv('LD_LIBRARY_PATH','usr/local/lib:/usr/lib:/usr/local/lib64:/usr/lib64');
  end
  
  dirlist_str = '';
  
  for i=1:length(gl.dirlist)
    dirlist_str = [dirlist_str '-y "' gl.dirlist{i} '" '];
  end
     %--top-module fft2d 
  gl.verilator_keys = ['-cc -O3 ' gl.verilator_keys];
  if gl.coverage
    gl.verilator_keys = [gl.coverage_keys ' ' gl.verilator_keys];
  end
  
  s = ['"' gl.v_path 'verilator_bin" ' gl.verilator_keys ' -Mdir "' ...
      gl.src_path 'obj_dir" ' dirlist_str ...
      '"' gl.src_path gl.src_file '.v"'];
  %hack
  if (gl.DoWindows)
      s = strrep(s, '..\', '../');
  end
  
  system(s);
  
  %checking for verilation success 
  if (isdir([gl.src_path 'obj_dir']) == 0)
    error('Error: Verilation error');
  end
  
  if ((gl.no_matlab_model == 1) && (gl.no_simulink_model == 1))
    fprintf('done.\n');
    res = true;
    return;
  end
  
  gl.i_c = 0; %number of inputs
  gl.o_c = 0; %number of outputs
  gl.include = '';
  gl.clk = false; %is there clock signal in the module (True = there is clock signal)
  gl.clk_enable = false;
  gl.rst = false;
  gl.inputs = {};
  gl.outputs = {};
  gl.outclks = {};
  
  gl = parse(gl, 1, 'top->', '', ['V' gl.src_file '.h']);
     
  %setting breaking condition for second simulation function (on C++)
  if (gl.clk == true) 
    if (isfield(args, 'break_condition') ~= 0)
      gl.break_condition = args.break_condition;
      gl.type = 3;
    else      
      gl.type = 2;
    end
  else
    gl.type = 1;
  end;
  
  fprintf 'compiling verilated model...\n';
  compile(gl, '');
  
  if (gl.no_matlab_model ~= 1)
    fprintf 'compiling MATLAB model...\n';   
    matlabmodel(gl);
    compile(gl, ['m_' gl.src_file]);
  end
  
  if (gl.no_simulink_model ~= 1)
    delete([gl.src_path 'obj_dir' gl.slash 'm_' gl.src_file '.o*']);
    fprintf 'compiling Simulink model...\n';   
    simulinkmodel(gl);
    compile(gl, ['s_' gl.src_file]);
  end

  if (~gl.debug_mode)
    rmdir([gl.src_path 'obj_dir'],'s');  %For WIN32 capability
  end
  
  if(~ (gl.savecpp == 1)) %Deleting c++ file
    if(gl.no_matlab_model ~= 1) 
      delete([gl.src_path 'm_' gl.src_file '.cpp']);
    end  
    if(gl.no_simulink_model ~= 1)          
      delete([gl.src_path 's_' gl.src_file '.cpp']);
    end  
  end
  
  fprintf('done.\n');
  res = true;
end

function[gl] = parseArgs(args)

  if (nargin == 0)
    error('Error: no input arguments.');
  end
  
  %if set to 1, matlab model will not be generated
  if (isfield(args, 'no_matlab_model') == 0) 
      gl.no_matlab_model = 0;
  else    
      gl.no_matlab_model = args.no_matlab_model;
  end

  %if set 1 all model inputs will be copied to output
  if (isfield(args, 'inputs_to_out') == 0) 
      gl.inp_to_out = 0;
  else    
      gl.inp_to_out = 1;
  end

  %if set 1 all clock signal will be copied to output
  if (isfield(args, 'clk_to_out') == 0) 
      gl.clk_to_out = 0;
  else    
      gl.clk_to_out = args.clk_to_out;
  end
  
  %if set to 1, matlab model will not be generated
  if (isfield(args, 'no_simulink_model') == 0) 
      gl.no_simulink_model = 0;
  else    
      gl.no_simulink_model = args.no_simulink_model;
  end

  %if set to 1, than code coverage analysis will be switched on
  if (isfield(args, 'coverage') == 0) 
      gl.coverage = 0;
  else    
      gl.coverage = args.coverage;
  end
  
  %if no coverage_keys defined then '--coverage' is used by default
  if (isfield(args, 'coverage_keys') == 0) 
      gl.coverage_keys='--coverage';
  else
      gl.coverage_keys=args.coverage_keys;
  end
  
  
  %Setting nestign level (if file A includes file B, then level = 1 while
  %parsing file A, and 2 while parsing file B
  gl.level = 1;
  
    
  %Check operating system; 1 = Windows
  gl.DoWindows = ispc;  
%  if (gl.DoWindows == 1)
%    gl.slash = '\';
%  else
    gl.slash = '/';
%  end
  
  %Getting path to verilator
  v_path = getenv('verilator_path');
  if (strcmp(v_path, ''))
    if (isfield(args, 'verilator_path') == 0)
      error('Error: verilator path is not defined.');
    else
      v_path = args.verilator_path;
    end
  end
  gl.v_path = relative2absolute(v_path, pwd, gl.DoWindows);
  
  %Getting source file path
  if (isfield(args, 'src_filename') == 0)
    error('Error: source file is not defined.');
  end

  %Check architecture info
  [~,ms] = computer;  
  gl.arch64=(ms>2^31); 
  
  %here src_file is full name and path of source .v file (eg:
  %/home/user/data.v or d:\data\main.v
  %later src_file will be splitted into src_file and src_path
  %eg : '/home/user/data.v' -> '/home/user/' and 'data'
  
  %saving filename in gl structure
  gl.src_file = relative2absolute(args.src_filename, pwd, gl.DoWindows);
  gl.src_path = '';
  
  %Removing file extension ('.v')
  sz = size(gl.src_file, 2); %Getting filename length
  if (sz > 1)
    if (strcmp(gl.src_file(sz-1:sz), '.v'))
      gl.src_file = gl.src_file(1:sz-2);
      sz = sz - 2;
    end
  end

  

  slash = strfind(gl.src_file, gl.slash);

  if (size(slash, 2) > 0) %if was '/' successfuly found
    pos = slash(size(slash, 2)); %Position of last '/'
    gl.src_path = gl.src_file(1:pos); %File path including '/' 
    gl.src_file = gl.src_file(pos+1:sz); %File name without extension 
  else
    error('Invalid source name');
  end
  
  %Saving current directory (eg: /home/user/my_models
  gl.main_dir = pwd;
  
  %unknown
  gl.mtop_name = '';
  gl.ctop_name = 'top';
  
  if (isfield(args, 'break_condition') == 0) 
    gl.break_condition = 'true';
  else    
    gl.break_condition = args.break_condition;
  end

  %Getting clock signal name (by default 'clk')
  if (isfield(args, 'clk_name') == 0) 
    gl.clk_name = 'clk';
  else
    gl.clk_name = args.clk_name;
  end
 
  %if set to 1, cpp source of the mex-file will be save. For debug purposes
  if (isfield(args, 'save_cpp') == 0) 
    gl.savecpp = 0;
  else    
    gl.savecpp = args.save_cpp;
  end
  
  %if set to 1, obj_dir will not be deleted. For debug purposes
  if (isfield(args, 'debug_mode') == 0) 
    gl.debug_mode = 0;
  else    
    gl.debug_mode = args.debug_mode;
  end
  
  %if set to 1, floats are considered as integers
  if (isfield(args, 'reinterpret_floats') == 0) 
    gl.reinterpret_floats = 0;
  else    
    gl.reinterpret_floats = args.reinterpret_floats;
  end
  
  %if set to 1, cpp source of the mex-file will be save. For debug purposes
  if (gl.debug_mode)
    gl.savecpp = 1;
  else
    if (isfield(args, 'save_cpp') == 0) 
      gl.savecpp = 0;
    else    
      gl.savecpp = args.save_cpp;
    end
  end
  
  %list of directories with Verilog files
  %vector filled with cells, containing pathes
  gl.dirlist = {gl.src_path};

  if(isfield(args, 'dirlist')~=0) 
    for i = 1:length(args.dirlist)
      gl.dirlist = [gl.dirlist {relative2absolute(args.dirlist{i}, ...
        gl.src_path, gl.DoWindows)}];
    end
  end
  
  
    
  %getting name of Matlab model constructor function
  %default is 'CreateModel' + Model name
  gl.constr_name = ['CreateModel' gl.src_file];
  if (isfield(args, 'constr_name') ~= 0)
    gl.constr_name = args.constr_name;
  end
  
  %getting name of Matlab model simulation function
  %default is 'SimModel' + Model name
  gl.sim_name = ['SimModel' gl.src_file]; 
  if (isfield(args, 'sim_name') ~= 0)
    gl.sim_name = args.sim_name;
  end
  
  %getting name of Matlab model conditional simulation function
  %default is 'SimModelTillSignal' + Model name
  gl.sim_name2 = ['SimModelTillSignal' gl.src_file]; 
  if (isfield(args, 'sim_name2') ~= 0)
    gl.sim_name2 = args.sim_name2;
  end
  
  %getting FPGA frequency value
  %default is 50 MHz
  gl.fpga_freq = 50;
  if (isfield(args, 'fpga_freq') ~= 0)
    gl.fpga_freq = args.fpga_freq;
  end
  
  %getting Simulink sample time value
  %default is 0.001
  gl.sample_time = 0.001;
  if (isfield(args, 'sample_time') ~= 0)
    gl.sample_time = args.sample_time;
  end

  %Setting output directory
  gl.output_dir=[gl.main_dir gl.slash 'm_' gl.src_file];
  if (isfield(args, 'output') ~= 0)  
    if(isempty(args.output)==0)
      gl.output_dir = relative2absolute(args.output, pwd, gl.DoWindows); 
    else
        gl.output_dir=gl.main_dir;
    end    
  end
  
  %Create output directory if it doesn't exist 
  if(exist(gl.output_dir,'dir')==0)
    mkdir(gl.output_dir);
  end
  
  gl.blackbox = 0;
  
  % parse data.signals section. Allowed values are:
  % all (default) - show all signals
  % public - signals in top module or marked as 'verilator public'
  % top - only signals in top module
  gl.visibility = 2;
  if (isfield(args, 'signals'))
      if (strcmp(args.signals, 'public') == 1)
          gl.visibility = 0;
      elseif (strcmp(args.signals, 'top') == 1)
          gl.visibility = 1;
      elseif (strcmp(args.signals, 'all') == 1)
          gl.visibility = 2;
      elseif (strcmp(args.signals, 'blackbox') == 1)
          gl.visibility = 1;
          gl.blackbox = 1;
      else
          error('Unexpected value of data.signals');
      end
  end
  
  if (gl.blackbox == 1)
      %Getting reset signal name (by default 'rst')
      if (isfield(args, 'rst_name') == 0) 
        gl.rst_name = 'rst';
      else
        gl.rst_name = args.rst_name;
      end

      %Getting clock_enable signal name (by default '')
      if (isfield(args, 'clk_enable_name') == 0) 
        gl.clk_enable_name = '';
      else
        gl.clk_enable_name = args.clk_enable_name;
      end
  else
      gl.rst_name = '';
      gl.clk_enable_name = '';
  end

  if (isfield(args, 'first_point'))
    if (args.first_point == 1)
      gl.first_point = 1;
    else
      gl.first_point = 0;
    end
  else
    gl.first_point = 0;
  end  
  
  if (isfield(args, 'any_edge'))
    if (args.any_edge == 1)
      gl.any_edge = 1;
    else
      gl.any_edge = 0;
    end
  else
    gl.any_edge = 0;
  end
  
  gl.verilator_keys = '';
  if (isfield(args, 'verilator_keys'))
      gl.verilator_keys = args.verilator_keys;
  end
  
  if (isfield(args, 'clocks'))
    gl.clocks=parse_clocks(args.clocks,gl.fpga_freq*10^6);
  else
    gl.clocks=[];
  end

  if(isempty(gl.clocks))    %if clocks field is undefined or has wrong type
    if(gl.any_edge)         %then create clocks from clk_name and any_edge fields  
        gl.clocks={gl.clk_name,1,0,1,3,0};
    else
        gl.clocks={gl.clk_name,1,0,1,2,0};
    end
  end 

  %Getting prameters array for multiclock mode
  if (isfield(args, 'multiclock') == 0)
      gl.multiclocks = 0;
  else
      gl.multiclocks = args.multiclock;
  end
 
  %Adding clocks to the verilator parameters
  if(gl.multiclocks)
      for i=1:size(gl.clocks)
        gl.verilator_keys = ['--clk ' cell2mat(gl.clocks(i,1)) ' ' gl.verilator_keys];
      end
  end
  
  %Getting multiclock clock names
  gl.jitter_sim_on=0;
  if(gl.multiclocks~=0)
      for i=1:size(gl.clocks)
        gl.multi_clk_names(i)=gl.clocks(i,1);
        if(cell2mat(gl.clocks(i,6))~=0)       %if any of clocks has jitter value
            gl.jitter_sim_on=1;     %then switching on jitter simulation
        end
      end
  end    

  %Interal variable random change probability
  if (isfield(args, 'rchg_probability') == 0)
      gl.rchg_probability = 0;
  else
      gl.rchg_probability = args.rchg_probability;
      if(gl.rchg_probability<0)
         gl.rchg_probability = 0;
      end
      if(gl.rchg_probability>1)
         gl.rchg_probability = 1;
      end
  end

  if (isfield(args, 'rchg_full_mem') == 0)
      gl.rchg_full_mem = 0;
  else
      gl.rchg_full_mem = args.rchg_full_mem;
  end
  
  
  if (isfield(args, 'rchg_show_param') == 0)
      gl.rchg_show_param = 0;
  else
      gl.rchg_show_param = args.rchg_show_param;
  end
  
  %Getting random seed
  if (isfield(args, 'random_seed') == 0)
      gl.random_seed = uint32(mod(sum(clock.*[365*24*60*60*30-1970 24*60*60*30 24*60*60 60*60 60 1]),2^32));  %Initial seed based on time
      if((gl.multiclocks~=0)||(gl.rchg_probability>0))
          f=fopen('random_seed.txt','w+');
          fprintf(f,[num2str(gl.random_seed) '\n']);  
          fclose(f);
      end
  else
      gl.random_seed = uint32(args.random_seed);
  end
  
end

function [ out ] = relative2absolute(name, path, win)
% if name is absolute, function returns name without '../../..' etc
% if name is relative, function returns [path '/' name] or [path name],
% also without '../../..'

  name_old = name;
  name = strrep(name, '\', '/');

  absolute_path = false;
  sz = size(name, 2);
  if (win && sz > 1)
    absolute_path = strcmp(name(2), ':');
  elseif (~win && sz > 0)
    absolute_path = strcmp(name(1), '/');
  end
  
  if (~absolute_path)
    path = strrep(path, '\', '/');
    last_char = path(size(path, 2));
    if (strcmp(last_char, '/'))
      name = [path name];
    else
      name = [path '/' name];
    end
  end

  while 1
    a = strfind(name, '..');
    if (size(a, 2) > 0)
      pos1 = a(1);
      if (~strcmp(name(pos1-1), '/')) 
        error(['Invalid path : ' name_old]);
      end
      pos = -1;
      for i = pos1-2:-1:1
        if (strcmp(name(i), '/'))
          pos = i;
          break;
        end
      end
      if (pos == -1)
        error(['Invalid path : ' name_old]);
      end
      name = [name(1:pos-1) name(pos1+2:size(name, 2))];
    else
      break;
    end
  end

  out = name;
end

