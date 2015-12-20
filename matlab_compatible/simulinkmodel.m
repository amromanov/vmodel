%%*********************vmodel MATLAB Verilog simulator******************
%%Moscow, Control Problems Department MIREA, 2009-2015
%%Authors: Karyakin D, Romanov A
%%
%%Distributed under the GNU LGPL
%%**********************************************************************


function [ ] = simulinkmodel( gl )
%SIMULINKMODEL Generator of simulink model
%   Function generates simulink model, must be called from vmodel.m

% gl is a structure, containing information about verilog model
% 
  inouts = parse_inouts(gl);
  help_string = generate_help(gl);
  generate_mdl(gl, inouts, help_string);

  generate_cpp(gl);
  
end

function [help_string] = generate_help(gl)
  %#ok<*AGROW>
  nl = [char(13) char(10)];
  
  help_string = '';
  for i = 1:size(gl.inputs, 2)
    if (simulink_filter(gl, gl.inputs{i}) == 0)
      continue;
    end
    help_string = [help_string 'input ' get_s_name(gl.inputs{i})];
    if (gl.inputs{i}.high ~= gl.inputs{i}.low)
      help_string = [help_string, '[' int2str(gl.inputs{i}.high) ':' ...
      int2str(gl.inputs{i}.low) ']'];
    end
    help_string = [help_string nl];
  end
  
  for i = 1:size(gl.outputs, 2)
    if (simulink_filter(gl, gl.outputs{i}) == 0)
      continue;
    end
    help_string = [help_string 'output ' get_s_name(gl.outputs{i})];
    if (gl.outputs{i}.high ~= gl.outputs{i}.low)
      help_string = [help_string, '[' int2str(gl.outputs{i}.high) ':' ...
      int2str(gl.outputs{i}.low) ']'];
    end
    help_string = [help_string nl];
  end
  

end


function [res] = parse_inouts(gl)
  res.inputs = {};
  res.outputs = {};
  for i=1:size(gl.inputs, 2)
    if (simulink_filter(gl, gl.inputs{i}) == 0)
      continue;
    end
    port_width = gl.inputs{i}.high - gl.inputs{i}.low + 1;
    if (port_width < 33)
      input.sim_name = [gl.inputs{i}.m_path gl.inputs{i}.name];
      res.inputs = [res.inputs input];
    else
      for j=0:floor((port_width - 1) / 32)
        input.sim_name = [gl.inputs{i}.m_path gl.inputs{i}.name '[' ...
          int2str(min(gl.inputs{i}.high, gl.inputs{i}.low + j*32 + 31)) ...
          '-' int2str(gl.inputs{i}.low + j*32) ']'];
        res.inputs = [res.inputs input];
      end
    end
  end
  
  for i=1:size(gl.outputs, 2)
    if (simulink_filter(gl, gl.outputs{i}) == 0)
      continue;
    end
    port_width = gl.outputs{i}.high - gl.outputs{i}.low + 1;
    if (port_width < 33)
      output.sim_name = [gl.outputs{i}.m_path gl.outputs{i}.name];
      res.outputs = [res.outputs output];
    else
      for j=0:floor((port_width - 1) / 32)
        output.sim_name = [gl.outputs{i}.m_path gl.outputs{i}.name '[' ...
          int2str(min(gl.outputs{i}.high, gl.outputs{i}.low + j*32 + 31)) ...
          '-' int2str(gl.outputs{i}.low + j*32) ']'];
        res.outputs = [res.outputs output];
      end
    end
  end
  
end

function [] = generate_mdl(gl, inouts, help_string)

  inCount = size(inouts.inputs, 2);
  outCount = size(inouts.outputs, 2);
  
  
  %getting number of inputs and outputs, and name of our model
  modelName = gl.src_file;

  %getting template of mdl file
  f = fopen('model_template', 'r');
  res = fscanf(f, '%c', inf);
  fclose(f); 

  % subsystem_path is a name of our model
  res = strrep(res, '%subsystem_name', modelName);
  
  % setting height of subsystem block
  s = 150 + max(inCount, outCount) * 20;
  res = strrep(res, '%subsystem_height', int2str(s));

  % ports is a string like "1, 2" , first number is count of inputs, second
  % is count of outputs
  ports = [int2str(inCount) ', ' int2str(outCount)];
  res = strrep(res, '%ports', ports);

  %nl is newline symbol
  nl = [char(13) char(10)];

  %blocks is a string, describing inputs of model, outputs of model,
  %s-function block and connections between all of these blocks
  blocks = '';
  lines = '';

  %#ok<*AGROW>
    
  for i = 1:inCount
    blocks = [blocks ...
  ' 	Block { ' nl ...
  ' 	  BlockType		  Inport' nl ...
  ' 	  Name			  "%name"' nl ...
  ' 	  Position		  [110, %y1, 140, %y2]' nl ...
  '       SampleTime	      "' num2str(gl.sample_time) '"' nl ...
	' 	  DataType		  "double"' nl ...
  '	    OutDataTypeStr	  "double"' nl ...
  ' 	}  ' nl];
    blockName = strrep(inouts.inputs{i}.sim_name, '__DOT__', '.');
    blocks = strrep(blocks, '%name', blockName);
    blocks = strrep(blocks, '%y1', int2str(100+i*60));
    blocks = strrep(blocks, '%y2', int2str(114+i*60));
    
    lines = [lines ...
      '  	Line {' nl ...
      '     SrcBlock		  "%name"' nl ...
      '     SrcPort		  1' nl ...
      '     DstBlock		  "S-Function"' nl ...
      '     DstPort		  %dst_port' nl ...
      '}' nl];
    lines = strrep(lines, '%name', blockName);
    lines = strrep(lines, '%dst_port', int2str(i));
    
  end

  for i = 1:outCount
    blocks = [blocks ...
  ' 	Block { ' nl ...
  ' 	  BlockType		  Outport' nl ...
  ' 	  Name			  "%name"' nl ...
  ' 	  Position		  [360, %y1, 390, %y2]' nl ...
  ' 	  DataType		  "uint32"' nl ...
  '       SampleTime	      "' num2str(gl.sample_time) '"' nl ...
  ' 	}  ' nl];
    blockName = strrep(inouts.outputs{i}.sim_name, '__DOT__', '.');
    blocks = strrep(blocks, '%name', blockName);
    blocks = strrep(blocks, '%y1', int2str(100+i*60));
    blocks = strrep(blocks, '%y2', int2str(114+i*60));
    
        lines = [lines ...
      '  	Line {' nl ...
      '     SrcBlock		  "S-Function"' nl ...
      '     SrcPort		  %src_port' nl ...
      '     DstBlock		  "%name"' nl ...
      '     DstPort		  1' nl ...
      '}' nl];
    lines = strrep(lines, '%name', blockName);
    lines = strrep(lines, '%src_port', int2str(i));

  end

  s_fcn = ['Block {' nl ...
	  '  BlockType		  "S-Function"' nl ...
	  '  Name			  "S-Function"' nl ...
	  '  Ports			  [%ports]' nl ...
	  '  Position		  [215, 164, 275, 196]' nl ...
    '	 Parameters		  "%params"' nl ...
	  '  FunctionName		  "%mex_name"' nl ...
    '}' nl];

  if (gl.type == 1)
    mask = [ ...
'      MaskType		      "' gl.src_file '"' nl ...
'      MaskDescription	      "' help_string '"' nl ...
'      MaskHelp		      "' help_string '"' nl ...
'      MaskPromptString	      "Sample time:"' nl ...
'      MaskStyleString	      "edit"' nl ...
'      MaskTunableValueString  "on"' nl ...
'      MaskEnableString	      "on"' nl ...
'      MaskVisibilityString    "on"' nl ...
'      MaskToolTipString	      "on"' nl ...
'      MaskValueString	      "' num2str(gl.sample_time) '"' nl ...
'      MaskVariables	      "params_samples=@1;"' nl ];
    s_fcn_params = 'params_samples';
  else
    mask = [ ...
'      MaskType		      "' gl.src_file '"' nl ...
'      MaskDescription	      "' help_string '"' nl ...
'      MaskHelp		      "' help_string '"' nl ...
'      MaskPromptString	      "Sample time:|FPGA frequency (MHz):"' nl ...
'      MaskStyleString	      "edit,edit"' nl ...
'      MaskTunableValueString "on,on"' nl ...
'      MaskEnableString	      "on,on"' nl ...
'      MaskVisibilityString   "on,on"' nl ...
'      MaskToolTipString	  "on,on"' nl ...
'      MaskValueString	      "' num2str(gl.sample_time) '|' num2str(gl.fpga_freq) '"' nl ...
'      MaskVariables	      "params_samples=@1;params_freq=@2;"' nl];
    s_fcn_params = 'params_samples, params_freq';
  end
  
  if (gl.blackbox == 1)
      blackbox_head = [ ...
'      Block {' nl ...
'      BlockType		      SubSystem' nl ...
'      Name		      "Blackbox_subsystem"' nl ...
'      Ports		      []' nl ...
'      Position		      [185, 164, 285, 206]' nl ...
'      ZOrder		      -17' nl ...
'      MinAlgLoopOccurrences   off' nl ...
'      PropExecContextOutsideSubsystem off' nl ...
'      RTWSystemCode	      "Auto"' nl ...
'      FunctionWithSeparateData off' nl ...
'      Opaque		      off' nl ...
'      RequestExecContextInheritance off' nl ...
'      MaskHideContents	      off' nl ...
'      System {' nl ...
'	Name			"Blackbox_subsystem"' nl ...
'	Location		[542, 454, 1040, 754]' nl ...
'	Open			on' nl ...
'	ModelBrowserVisibility	off' nl ...
'	ModelBrowserWidth	200' nl ...
'	ScreenColor		"white"' nl ...
'	PaperOrientation	"landscape"' nl ...
'	PaperPositionMode	"auto"' nl ...
'	PaperType		"A4"' nl ...
'	PaperUnits		"centimeters"' nl ...
'	TiledPaperMargins	[1.270000, 1.270000, 1.270000, 1.270000]' nl ...
'	TiledPageScale		1' nl ...
'	ShowPageBoundaries	off' nl ...
'	ZoomFactor		"100"' nl ...
    ];
    blackbox_tail = ['}' nl '}'];
    if (gl.clk == 0)
        sig_options = ['	      Cell		      "AddClockPort"' nl ...
                       '	      Cell		      "off"' nl];
    else
        sig_options = ['	      Cell		      "ClockInputPort"' nl ...
                       '	      Cell		      "' gl.clk_name '"' nl];
    end
    
    if (gl.rst == 0)
        sig_options = [sig_options ...
                       '	      Cell		      "AddResetPort"' nl ...
                       '	      Cell		      "off"' nl];
    else
        sig_options = [sig_options ...
                       '	      Cell		      "ResetInputPort"' nl ...
                       '	      Cell		      "' gl.rst_name '"' nl];
    end
    
    if (gl.clk_enable == 0)
        sig_options = [sig_options ...
                       '	      Cell		      "AddClockEnablePort"' nl ...
                       '	      Cell		      "off"' nl];
    else
        sig_options = [sig_options ...
                       '	      Cell		      "ClockEnableInputPort"' nl ...
                       '	      Cell		      "' gl.clk_enable_name '"' nl];
    end
    hdl_properties = [ ...
'   slprops.hdlblkprops {' nl ...
'	    $PropName		    "HDLData"' nl ...
'	    archSelection	    "BlackBox"' nl ...
'	    Array {' nl ...
'	      Type		      "Cell"' nl ...
'	      Dimension		      8' nl ...
sig_options ...
'	      Cell		      "EntityName"' nl ...
'	      Cell		      "' gl.src_file '"' nl ...
'	      PropName		      "archImplInfo"' nl ...
'	    }' nl ...
'	  }' nl ...
        ];
  else
    blackbox_head = '';
    blackbox_tail = '';
    hdl_properties = '';
  end
  
  
  s_fcn = strrep(s_fcn, '%ports', ports);
  s_fcn = strrep(s_fcn, '%mex_name', ['s_' gl.src_file]);
  s_fcn = strrep(s_fcn, '%params', s_fcn_params);
  res = strrep(res, '%blackbox_head', blackbox_head);
  res = strrep(res, '%blackbox_tail', blackbox_tail);
  res = strrep(res, '%hdl_properties', hdl_properties);
  res = strrep(res, '%blocks', [s_fcn blocks lines]);
  res = strrep(res, '%mask', mask);

  
  f = fopen([gl.output_dir gl.slash gl.src_file '.mdl'], 'w');
  fwrite(f, res);
  fclose(f); 
  
end

function [] = generate_cpp(gl)
  f = fopen('data_simulink', 'r');
  res = fscanf(f, '%c', inf);
  fclose(f); 
  
  %nl is newline symbol
  nl = [char(13) char(10)];
  
  set_inputs = '';
  set_outputs = '';
  
  
  %inputs for simulink
% top->in_a = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,0))[0];
% top->in_c[0] = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,1))[0];
% top->in_c[1] = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,2))[0];
% top->in_c[2] = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,3))[0];
% top->in_c[3] = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,4))[0];
% top->in_c[4] = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,5))[0];
% 
% top->in_b = ((uint64)(*((InputRealPtrsType)ssGetInputPortSignalPtrs(S,7))[0]) << 32) + (uint32)(*((InputRealPtrsType)ssGetInputPortSignalPtrs(S,6))[0]);

  index = 0;
  for i = 1:size(gl.inputs, 2)
    if (simulink_filter(gl, gl.inputs{i}) == 0) %skipping private wires
      continue;
    end
    sz = gl.inputs{i}.size;
    if (sz == 1)
      set_inputs = [set_inputs gl.inputs{i}.c_path gl.inputs{i}.name ...
        ' = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,' ...
        int2str(index) '))[0];' nl];
      index = index + 1;
    elseif (sz == 2)
      set_inputs = [set_inputs gl.inputs{i}.c_path gl.inputs{i}.name ...
        ' = ((uint64)(*((InputRealPtrsType)ssGetInputPortSignalPtrs(S,' ...
        int2str(index + 1) '))[0]) << 32) + ' ...
        '(uint32)(*((InputRealPtrsType)ssGetInputPortSignalPtrs(S,' ...
        int2str(index) '))[0]);' nl];
      index = index + 2;
    else
      for j = 1:sz
        set_inputs = [set_inputs gl.inputs{i}.c_path gl.inputs{i}.name '[' ...
          int2str(j-1) '] = *((InputRealPtrsType)ssGetInputPortSignalPtrs(S,' ...
          int2str(index + j - 1) '))[0];' nl];
      end
      index = index + sz;
    end
  end
  
  inCount = index;
  index = 0;
  
  %setting outputs for simulink
  
%       ((uint32 *)ssGetOutputPortSignal(S,0))[0] = top->out_a;
%   ((uint32 *)ssGetOutputPortSignal(S,1))[0] = top->out_c[0];
%   ((uint32 *)ssGetOutputPortSignal(S,2))[0] = top->out_c[1];
%   ((uint32 *)ssGetOutputPortSignal(S,3))[0] = top->out_c[2];
%   ((uint32 *)ssGetOutputPortSignal(S,4))[0] = top->out_c[3];
%   ((uint32 *)ssGetOutputPortSignal(S,5))[0] = top->out_c[4];
%   
%   ((uint32 *)ssGetOutputPortSignal(S,6))[0] = top->out_b & 0xFFFFFFFF;
%   ((uint32 *)ssGetOutputPortSignal(S,7))[0] = top->out_b >> 32;

  for i = 1:size(gl.outputs, 2)
    if (simulink_filter(gl, gl.outputs{i}) == 0)  %skipping private wires
      continue;
    end
    sz = gl.outputs{i}.size;
    if (sz == 1)
      set_outputs = [set_outputs '  ((uint32 *)ssGetOutputPortSignal(S,' ... 
        int2str(index) '))[0] = ' gl.outputs{i}.c_path ...
        gl.outputs{i}.name ';' nl];
      index = index + 1;
    elseif (sz == 2)
      set_outputs = [set_outputs '  ((uint32 *)ssGetOutputPortSignal(S,' ... 
        int2str(index) '))[0] = ' gl.outputs{i}.c_path ...
        gl.outputs{i}.name ' & 0xFFFFFFFF;' nl '  ((uint32 *)ssGetOutputPortSignal(S,' ... 
        int2str(index + 1) '))[0] = ' gl.outputs{i}.c_path ...
        gl.outputs{i}.name ' >> 32;' nl];
      index = index + 2;
    else
      for j = 1:sz
        set_outputs = [set_outputs '  ((uint32 *)ssGetOutputPortSignal(S,' ...
          int2str(index + j - 1) '))[0] = ' gl.outputs{i}.c_path ...
        gl.outputs{i}.name '[' int2str(j-1) '];' nl];
      end
      index = index + sz;
    end
  end
  
  outCount = index;
 
  if (gl.type == 1)
    define_type = ['#define TYPE_A' nl];
  else
    define_type = ['#define TYPE_B' nl];
  end
  
  %Special define for Windows version
  if (ispc)
        define_type = [define_type '#define CYGWIN_VMODEL' nl];
  end
  
  %define_type is also used to declare code coverage options 
  if (gl.coverage)  
    define_type = [define_type '#define CODE_COVERAGE' nl ...
                               '#include "verilated_cov.h"' nl];
  end   
  if(gl.multiclocks)
    [edges, clocks, halfperiods, timevectors, jitters, clock_chg] = generate_multiclock_data(gl);      
    define_type = [define_type '#define CLOCK_AMOUNT ' int2str(size(gl.clocks,1)) nl ...%number of clocks for multiclock
    '#define MULTICLOCK' nl];%enable multiclock mode
    if (gl.jitter_sim_on == 1)
        define_type = [define_type '#define JITTER_SIM' nl];
    end
  end

  if(gl.rchg_probability>0)  %If random change probability > 0 then adding change string
    [ random_chg_set ] = generate_rchg_data( gl );
  end

  if gl.rchg_show_param
      define_type = [define_type '#define RCHG_PARAMS_OUT' nl];
  end  
  
  res = strrep(res, '%slink_mex_filename', ['s_' gl.src_file]);
  res = strrep(res, '%includes', gl.include);
  res = strrep(res, '%clock_name', ['top->' gl.clk_name]);
  res = strrep(res, '%define_type', define_type);
  res = strrep(res, '%inputs_count', int2str(inCount));
  res = strrep(res, '%outputs_count', int2str(outCount));
  res = strrep(res, '%top_name', ['V' gl.src_file]);
  res = strrep(res, '%set_inputs', set_inputs);
  res = strrep(res, '%set_outputs', set_outputs);
  res = strrep(res, '%random_seed', num2str(uint32(gl.random_seed)));
  res = strrep(res, '%r_chg_prob',  num2str(uint32(gl.rchg_probability*(2^32-1))));

  if(gl.rchg_probability>0)
      res = strrep(res, '%rnd_chg_interal', random_chg_set);
  else
      res = strrep(res, '%rnd_chg_interal', '');
  end

  
  if(gl.multiclocks~=0)
      res = strrep(res, '%clocks', clocks);
      res = strrep(res, '%halfperiods', halfperiods);
      res = strrep(res, '%timevectors', timevectors);
      res = strrep(res, '%jitter_amp', jitters);
      res = strrep(res, '%clock_chg', clock_chg);
  end  
  
  f = fopen([gl.src_path 's_' gl.src_file '.cpp'], 'w');
  fwrite(f, res);
  fclose(f); 
  
end

function [res] = get_s_name(port)
  res = [port.m_path port.name];
  res = strrep(res, '__PVT__', '');
  res = strrep(res, 'v__DOT__', '');
  res = strrep(res, '__DOT__', '.');
end

function [res] = simulink_filter(gl, port)
    if ((gl.blackbox == 0)&&(gl.visibility ~= 1))  %if not black box model and vmodel configuration 'signals' parameter is not 'top'
        if (port.visibility > 1)
            res = 0;
        else
            res = 1;
        end  
    else
        if (port.visibility == 0)
            res = 1;
        else
            res = 0;
        end
    end
    if (strcmp(port.name(end),']')~=0)      %do not show memory in simulink
      res=0;
    end          
end
